import Foundation
import SwiftData

/// Business logic engine for the Budget League Tracker.
/// Contains pure or nearly pure functions for scoring and state transitions.
/// ViewModels call these functions with SwiftData context and apply results.
enum LeagueEngine {
    
    // MARK: - Tournament Lifecycle
    
    /// Creates a new tournament with the given settings.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - name: Tournament name
    ///   - totalWeeks: Number of weeks
    ///   - randomPerWeek: Random achievements per week
    ///   - playerIds: IDs of players participating in this tournament
    static func createTournament(
        context: ModelContext,
        name: String,
        totalWeeks: Int,
        randomPerWeek: Int,
        playerIds: [String]
    ) {
        let clampedWeeks = min(max(totalWeeks, AppConstants.League.weeksRange.lowerBound),
                               AppConstants.League.weeksRange.upperBound)
        let clampedRandom = min(max(randomPerWeek, AppConstants.League.randomAchievementsPerWeekRange.lowerBound),
                                AppConstants.League.randomAchievementsPerWeekRange.upperBound)
        
        // Create the tournament
        let tournament = Tournament(
            name: name,
            totalWeeks: clampedWeeks,
            randomAchievementsPerWeek: clampedRandom
        )
        context.insert(tournament)
        
        // Roll active achievements for week 1
        let achievements = fetchAllAchievements(context: context)
        tournament.activeAchievementIds = rollActiveAchievements(
            achievements: achievements,
            randomPerWeek: clampedRandom
        ).map { $0.id }
        
        // Update league state
        guard let state = fetchLeagueState(context: context) else { return }
        state.activeTournamentId = tournament.id
        state.screen = .attendance
        
        // Increment tournamentsPlayed for selected players
        let playerDescriptor = FetchDescriptor<Player>()
        if let allPlayers = try? context.fetch(playerDescriptor) {
            for player in allPlayers where playerIds.contains(player.id) {
                player.tournamentsPlayed += 1
            }
        }
        
        try? context.save()
    }
    
    /// Archives the current tournament (marks as completed).
    /// - Parameter context: The SwiftData model context
    static func archiveTournament(context: ModelContext) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        tournament.status = .completed
        tournament.endDate = Date()
        
        // Clear active tournament reference
        if let state = fetchLeagueState(context: context) {
            state.activeTournamentId = nil
            state.screen = .tournaments
        }
        
        try? context.save()
    }
    
    // MARK: - Player Management
    
    /// Adds a new player with the given name.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - name: The player's name (will be trimmed)
    /// - Returns: The created player, or nil if name was empty
    @discardableResult
    static func addPlayer(context: ModelContext, name: String) -> Player? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        
        let player = Player(name: trimmedName)
        context.insert(player)
        try? context.save()
        return player
    }
    
    /// Removes a player by ID.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - id: The player's ID
    static func removePlayer(context: ModelContext, id: String) {
        let descriptor = FetchDescriptor<Player>()
        if let players = try? context.fetch(descriptor),
           let player = players.first(where: { $0.id == id }) {
            context.delete(player)
            try? context.save()
        }
    }
    
    // MARK: - Attendance
    
    /// Confirms attendance for the current week.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - presentIds: IDs of players who are present
    ///   - achievementsOnThisWeek: Whether achievements count this week
    static func confirmAttendance(
        context: ModelContext,
        presentIds: [String],
        achievementsOnThisWeek: Bool
    ) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        tournament.presentPlayerIds = presentIds
        tournament.achievementsOnThisWeek = achievementsOnThisWeek
        tournament.currentRound = AppConstants.League.defaultCurrentRound
        
        // Reset weekly points for all present players
        var weeklyPoints: [String: WeeklyPlayerPoints] = [:]
        for playerId in presentIds {
            weeklyPoints[playerId] = WeeklyPlayerPoints()
        }
        tournament.weeklyPointsByPlayer = weeklyPoints
        
        tournament.podHistorySnapshots = []
        
        // Clear any leftover round data
        tournament.roundPlacements = [:]
        tournament.roundAchievementChecks = []
        
        if let state = fetchLeagueState(context: context) {
            state.screen = .pods
        }
        
        try? context.save()
    }
    
    /// Adds a new player during attendance (joins league and is marked present).
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - name: The player's name
    /// - Returns: The created player, or nil if name was empty
    @discardableResult
    static func addWeeklyPlayer(context: ModelContext, name: String) -> Player? {
        guard let player = addPlayer(context: context, name: name) else { return nil }
        guard let tournament = fetchActiveTournament(context: context) else { return player }
        
        // Add to present players
        var presentIds = tournament.presentPlayerIds
        presentIds.append(player.id)
        tournament.presentPlayerIds = presentIds
        
        // Add to weekly points
        var weeklyPoints = tournament.weeklyPointsByPlayer
        weeklyPoints[player.id] = WeeklyPlayerPoints()
        tournament.weeklyPointsByPlayer = weeklyPoints
        
        // Increment tournamentsPlayed since they're joining mid-tournament
        player.tournamentsPlayed += 1
        
        try? context.save()
        return player
    }
    
    // MARK: - Pod Generation
    
    /// Generates pods for the current round.
    /// - Parameters:
    ///   - players: All players in the league
    ///   - presentPlayerIds: IDs of present players
    ///   - currentRound: The current round number
    ///   - weeklyPointsByPlayer: Weekly points for sorting (rounds 2+)
    /// - Returns: Array of player groups (pods)
    static func generatePodsForRound(
        players: [Player],
        presentPlayerIds: [String],
        currentRound: Int,
        weeklyPointsByPlayer: [String: WeeklyPlayerPoints]
    ) -> [[Player]] {
        let presentPlayers = players.filter { presentPlayerIds.contains($0.id) }
        guard !presentPlayers.isEmpty else { return [] }
        
        var sortedPlayers: [Player]
        
        if currentRound == 1 {
            // Round 1: Shuffle randomly
            sortedPlayers = presentPlayers.shuffled()
        } else {
            // Later rounds: Sort by weekly total points (descending)
            sortedPlayers = presentPlayers.sorted { player1, player2 in
                let points1 = weeklyPointsByPlayer[player1.id]?.total ?? 0
                let points2 = weeklyPointsByPlayer[player2.id]?.total ?? 0
                return points1 > points2
            }
        }
        
        // Split into pods of podSize
        let podSize = AppConstants.League.podSize
        var pods: [[Player]] = []
        var currentPod: [Player] = []
        
        for player in sortedPlayers {
            currentPod.append(player)
            if currentPod.count == podSize {
                pods.append(currentPod)
                currentPod = []
            }
        }
        
        // Handle remainder (incomplete pod)
        if !currentPod.isEmpty {
            pods.append(currentPod)
        }
        
        return pods
    }
    
    // MARK: - Auto-Save (Individual Placements/Achievements)
    
    /// Updates a single player's placement for the current round (auto-save).
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - playerId: The player's ID
    ///   - placement: The placement (1-4)
    static func updatePlacement(context: ModelContext, playerId: String, placement: Int) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        var placements = tournament.roundPlacements
        placements[playerId] = placement
        tournament.roundPlacements = placements
        
        try? context.save()
    }
    
    /// Updates a single achievement check for the current round (auto-save).
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - playerId: The player's ID
    ///   - achievementId: The achievement's ID
    ///   - checked: Whether the achievement is checked
    static func updateAchievementCheck(
        context: ModelContext,
        playerId: String,
        achievementId: String,
        checked: Bool
    ) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        let key = "\(playerId):\(achievementId)"
        var checks = tournament.roundAchievementChecks
        
        if checked {
            checks.insert(key)
        } else {
            checks.remove(key)
        }
        
        tournament.roundAchievementChecks = checks
        
        try? context.save()
    }
    
    /// Finalizes the current round's placements and achievements.
    /// Applies all stored placements to player stats and weekly points.
    /// Also creates GameResult records for historical tracking.
    /// - Parameter context: The SwiftData model context
    static func finalizeRound(context: ModelContext) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        let placements = tournament.roundPlacements
        let achievementCheckKeys = tournament.roundAchievementChecks
        
        // Skip if no placements recorded
        guard !placements.isEmpty else { return }
        
        // Fetch all players and achievements
        let playerDescriptor = FetchDescriptor<Player>()
        guard let allPlayers = try? context.fetch(playerDescriptor) else { return }
        
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let allAchievements = (try? context.fetch(achievementDescriptor)) ?? []
        let achievementLookup = Dictionary(uniqueKeysWithValues: allAchievements.map { ($0.id, $0) })
        
        var playerDeltas: [String: PlayerDelta] = [:]
        var weeklyDeltas: [String: WeeklyPlayerPoints] = [:]
        var checkRecords: [AchievementCheck] = []
        
        // Generate a pod ID for this group of results (for head-to-head tracking)
        let podId = UUID().uuidString
        
        // Process each player with a placement
        for (playerId, place) in placements {
            let placementPts = AppConstants.Scoring.placementPoints(forPlace: place)
            
            // Calculate achievement points for this player
            var achievementPts = 0
            var earnedAchievementIds: [String] = []
            
            if tournament.achievementsOnThisWeek {
                for key in achievementCheckKeys where key.hasPrefix("\(playerId):") {
                    let achievementId = String(key.dropFirst(playerId.count + 1))
                    if let achievement = achievementLookup[achievementId] {
                        achievementPts += achievement.points
                        earnedAchievementIds.append(achievementId)
                        checkRecords.append(AchievementCheck(
                            playerId: playerId,
                            achievementId: achievementId,
                            points: achievement.points
                        ))
                    }
                }
            }
            
            let isWin = place == 1
            
            // Create deltas for undo
            playerDeltas[playerId] = PlayerDelta(
                placementPoints: placementPts,
                achievementPoints: achievementPts,
                wins: isWin ? 1 : 0,
                gamesPlayed: 1
            )
            weeklyDeltas[playerId] = WeeklyPlayerPoints(
                placementPoints: placementPts,
                achievementPoints: achievementPts
            )
            
            // Create GameResult record for historical tracking
            let gameResult = GameResult(
                tournamentId: tournament.id,
                week: tournament.currentWeek,
                round: tournament.currentRound,
                playerId: playerId,
                placement: place,
                placementPoints: placementPts,
                achievementPoints: achievementPts,
                achievementIds: earnedAchievementIds,
                podId: podId
            )
            context.insert(gameResult)
        }
        
        // Update players' cumulative stats
        for player in allPlayers {
            if let delta = playerDeltas[player.id] {
                player.placementPoints += delta.placementPoints
                player.achievementPoints += delta.achievementPoints
                player.wins += delta.wins
                player.gamesPlayed += delta.gamesPlayed
            }
        }
        
        // Update weekly points
        var weeklyPoints = tournament.weeklyPointsByPlayer
        for (playerId, delta) in weeklyDeltas {
            var current = weeklyPoints[playerId] ?? WeeklyPlayerPoints()
            current.placementPoints += delta.placementPoints
            current.achievementPoints += delta.achievementPoints
            weeklyPoints[playerId] = current
        }
        tournament.weeklyPointsByPlayer = weeklyPoints
        
        // Push snapshot for undo
        var snapshots = tournament.podHistorySnapshots
        snapshots.append(PodSnapshot(
            playerIds: Array(placements.keys),
            placements: placements,
            achievementChecks: checkRecords,
            playerDeltas: playerDeltas,
            weeklyDeltas: weeklyDeltas
        ))
        tournament.podHistorySnapshots = snapshots
        
        // Clear round data
        tournament.roundPlacements = [:]
        tournament.roundAchievementChecks = []
        
        try? context.save()
    }
    
    /// Clears the current round's placements and achievements without applying them.
    /// - Parameter context: The SwiftData model context
    static func clearRoundData(context: ModelContext) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        tournament.roundPlacements = [:]
        tournament.roundAchievementChecks = []
        
        try? context.save()
    }
    
    /// Undoes the last saved pod.
    /// - Parameter context: The SwiftData model context
    static func undoLastPod(context: ModelContext) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        var snapshots = tournament.podHistorySnapshots
        guard let lastSnapshot = snapshots.popLast() else { return }
        
        // Reverse player cumulative stats
        let playerDescriptor = FetchDescriptor<Player>()
        if let allPlayers = try? context.fetch(playerDescriptor) {
            for player in allPlayers {
                if let delta = lastSnapshot.playerDeltas[player.id] {
                    player.placementPoints -= delta.placementPoints
                    player.achievementPoints -= delta.achievementPoints
                    player.wins -= delta.wins
                    player.gamesPlayed -= delta.gamesPlayed
                }
            }
        }
        
        // Reverse weekly points
        var weeklyPoints = tournament.weeklyPointsByPlayer
        for (playerId, delta) in lastSnapshot.weeklyDeltas {
            var current = weeklyPoints[playerId] ?? WeeklyPlayerPoints()
            current.placementPoints -= delta.placementPoints
            current.achievementPoints -= delta.achievementPoints
            weeklyPoints[playerId] = current
        }
        tournament.weeklyPointsByPlayer = weeklyPoints
        
        tournament.podHistorySnapshots = snapshots
        
        // Delete the corresponding GameResults
        // We need to find GameResults that match this pod's players, week, and round
        let gameResultDescriptor = FetchDescriptor<GameResult>()
        if let allResults = try? context.fetch(gameResultDescriptor) {
            for playerId in lastSnapshot.playerIds {
                let matchingResults = allResults.filter {
                    $0.tournamentId == tournament.id &&
                    $0.week == tournament.currentWeek &&
                    $0.round == tournament.currentRound &&
                    $0.playerId == playerId
                }
                for result in matchingResults {
                    context.delete(result)
                }
            }
        }
        
        try? context.save()
    }
    
    /// Applies edited round data, replacing the last snapshot with updated values.
    /// Reverses old deltas, calculates new deltas, and updates GameResults.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - newPlacements: Updated placements (playerId -> place 1-4)
    ///   - newAchievementChecks: Updated achievement checks ("playerId:achievementId")
    static func applyEditedRound(
        context: ModelContext,
        newPlacements: [String: Int],
        newAchievementChecks: Set<String>
    ) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        
        var snapshots = tournament.podHistorySnapshots
        guard let lastSnapshot = snapshots.popLast() else { return }
        
        // Fetch all players and achievements
        let playerDescriptor = FetchDescriptor<Player>()
        guard let allPlayers = try? context.fetch(playerDescriptor) else { return }
        
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let allAchievements = (try? context.fetch(achievementDescriptor)) ?? []
        let achievementLookup = Dictionary(uniqueKeysWithValues: allAchievements.map { ($0.id, $0) })
        
        // Step 1: Reverse old deltas from player stats
        for player in allPlayers {
            if let delta = lastSnapshot.playerDeltas[player.id] {
                player.placementPoints -= delta.placementPoints
                player.achievementPoints -= delta.achievementPoints
                player.wins -= delta.wins
                player.gamesPlayed -= delta.gamesPlayed
            }
        }
        
        // Step 2: Reverse old weekly points
        var weeklyPoints = tournament.weeklyPointsByPlayer
        for (playerId, delta) in lastSnapshot.weeklyDeltas {
            var current = weeklyPoints[playerId] ?? WeeklyPlayerPoints()
            current.placementPoints -= delta.placementPoints
            current.achievementPoints -= delta.achievementPoints
            weeklyPoints[playerId] = current
        }
        
        // Step 3: Calculate new deltas from edited values
        var newPlayerDeltas: [String: PlayerDelta] = [:]
        var newWeeklyDeltas: [String: WeeklyPlayerPoints] = [:]
        var newCheckRecords: [AchievementCheck] = []
        
        for (playerId, place) in newPlacements {
            let placementPts = AppConstants.Scoring.placementPoints(forPlace: place)
            
            // Calculate achievement points for this player
            var achievementPts = 0
            var earnedAchievementIds: [String] = []
            
            if tournament.achievementsOnThisWeek {
                for key in newAchievementChecks where key.hasPrefix("\(playerId):") {
                    let achievementId = String(key.dropFirst(playerId.count + 1))
                    if let achievement = achievementLookup[achievementId] {
                        achievementPts += achievement.points
                        earnedAchievementIds.append(achievementId)
                        newCheckRecords.append(AchievementCheck(
                            playerId: playerId,
                            achievementId: achievementId,
                            points: achievement.points
                        ))
                    }
                }
            }
            
            let isWin = place == 1
            
            newPlayerDeltas[playerId] = PlayerDelta(
                placementPoints: placementPts,
                achievementPoints: achievementPts,
                wins: isWin ? 1 : 0,
                gamesPlayed: 1
            )
            newWeeklyDeltas[playerId] = WeeklyPlayerPoints(
                placementPoints: placementPts,
                achievementPoints: achievementPts
            )
        }
        
        // Step 4: Apply new deltas to player stats
        for player in allPlayers {
            if let delta = newPlayerDeltas[player.id] {
                player.placementPoints += delta.placementPoints
                player.achievementPoints += delta.achievementPoints
                player.wins += delta.wins
                player.gamesPlayed += delta.gamesPlayed
            }
        }
        
        // Step 5: Apply new weekly points
        for (playerId, delta) in newWeeklyDeltas {
            var current = weeklyPoints[playerId] ?? WeeklyPlayerPoints()
            current.placementPoints += delta.placementPoints
            current.achievementPoints += delta.achievementPoints
            weeklyPoints[playerId] = current
        }
        tournament.weeklyPointsByPlayer = weeklyPoints
        
        // Step 6: Delete old GameResults and create new ones
        let gameResultDescriptor = FetchDescriptor<GameResult>()
        if let allResults = try? context.fetch(gameResultDescriptor) {
            for playerId in lastSnapshot.playerIds {
                let matchingResults = allResults.filter {
                    $0.tournamentId == tournament.id &&
                    $0.week == tournament.currentWeek &&
                    $0.round == tournament.currentRound &&
                    $0.playerId == playerId
                }
                for result in matchingResults {
                    context.delete(result)
                }
            }
        }
        
        // Create new GameResults with a new pod ID
        let podId = UUID().uuidString
        for (playerId, place) in newPlacements {
            let delta = newPlayerDeltas[playerId]!
            let earnedAchievementIds = newCheckRecords
                .filter { $0.playerId == playerId }
                .map { $0.achievementId }
            
            let gameResult = GameResult(
                tournamentId: tournament.id,
                week: tournament.currentWeek,
                round: tournament.currentRound,
                playerId: playerId,
                placement: place,
                placementPoints: delta.placementPoints,
                achievementPoints: delta.achievementPoints,
                achievementIds: earnedAchievementIds,
                podId: podId
            )
            context.insert(gameResult)
        }
        
        // Step 7: Replace snapshot in history with updated one
        let newSnapshot = PodSnapshot(
            playerIds: Array(newPlacements.keys),
            placements: newPlacements,
            achievementChecks: newCheckRecords,
            playerDeltas: newPlayerDeltas,
            weeklyDeltas: newWeeklyDeltas
        )
        snapshots.append(newSnapshot)
        tournament.podHistorySnapshots = snapshots
        
        try? context.save()
    }
    
    // MARK: - Round/Week Progression
    
    /// Advances to the next round or next week (no modal).
    /// Finalizes current round's placements before advancing.
    /// - Parameter context: The SwiftData model context
    static func nextRound(context: ModelContext) {
        // Finalize current round's placements first
        finalizeRound(context: context)
        
        guard let tournament = fetchActiveTournament(context: context) else { return }
        guard let state = fetchLeagueState(context: context) else { return }
        
        if tournament.currentRound < AppConstants.League.roundsPerWeek {
            // Advance to next round
            tournament.currentRound += 1
        } else {
            // End of week - advance to next week or end tournament
            if tournament.isFinalWeek {
                // Archive the tournament and show standings
                tournament.status = .completed
                tournament.endDate = Date()
                state.screen = .tournamentStandings
            } else {
                tournament.currentWeek += 1
                tournament.currentRound = AppConstants.League.defaultCurrentRound
                tournament.presentPlayerIds = []
                tournament.weeklyPointsByPlayer = [:]
                tournament.podHistorySnapshots = []
                
                // Roll new active achievements
                let achievements = fetchAllAchievements(context: context)
                tournament.activeAchievementIds = rollActiveAchievements(
                    achievements: achievements,
                    randomPerWeek: tournament.randomAchievementsPerWeek
                ).map { $0.id }
                
                state.screen = .attendance
            }
        }
        
        try? context.save()
    }
    
    /// Closes weekly standings and advances to next week or tournament standings.
    /// - Parameter context: The SwiftData model context
    static func closeWeeklyStandings(context: ModelContext) {
        guard let tournament = fetchActiveTournament(context: context) else { return }
        guard let state = fetchLeagueState(context: context) else { return }
        
        if tournament.isFinalWeek {
            tournament.status = .completed
            tournament.endDate = Date()
            state.screen = .tournamentStandings
        } else {
            tournament.currentWeek += 1
            tournament.currentRound = AppConstants.League.defaultCurrentRound
            tournament.presentPlayerIds = []
            tournament.weeklyPointsByPlayer = [:]
            tournament.podHistorySnapshots = []
            
            // Roll new active achievements
            let achievements = fetchAllAchievements(context: context)
            tournament.activeAchievementIds = rollActiveAchievements(
                achievements: achievements,
                randomPerWeek: tournament.randomAchievementsPerWeek
            ).map { $0.id }
            
            state.screen = .attendance
        }
        
        try? context.save()
    }
    
    /// Exits weekly standings back to pods without advancing.
    /// - Parameter context: The SwiftData model context
    static func exitWeeklyStandings(context: ModelContext) {
        guard let state = fetchLeagueState(context: context) else { return }
        state.screen = .pods
        try? context.save()
    }
    
    /// Closes tournament standings and returns to tournaments list.
    /// - Parameter context: The SwiftData model context
    static func closeTournamentStandings(context: ModelContext) {
        guard let state = fetchLeagueState(context: context) else { return }
        state.activeTournamentId = nil
        state.screen = .tournaments
        try? context.save()
    }
    
    // MARK: - Achievement Management
    
    /// Rolls active achievements for a week.
    /// - Parameters:
    ///   - achievements: All available achievements
    ///   - randomPerWeek: Number of random achievements to include
    /// - Returns: Array of active achievements (always-on + random sample)
    static func rollActiveAchievements(
        achievements: [Achievement],
        randomPerWeek: Int
    ) -> [Achievement] {
        let alwaysOn = achievements.filter { $0.alwaysOn }
        let notAlwaysOn = achievements.filter { !$0.alwaysOn }
        
        let randomCount = min(randomPerWeek, notAlwaysOn.count)
        let randomSample = Array(notAlwaysOn.shuffled().prefix(randomCount))
        
        return alwaysOn + randomSample
    }
    
    /// Adds a new achievement.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - name: Achievement name
    ///   - points: Points awarded
    ///   - alwaysOn: Whether always active
    /// - Returns: The created achievement, or nil if name was empty
    @discardableResult
    static func addAchievement(
        context: ModelContext,
        name: String,
        points: Int,
        alwaysOn: Bool
    ) -> Achievement? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        
        let achievement = Achievement(name: trimmedName, points: points, alwaysOn: alwaysOn)
        context.insert(achievement)
        try? context.save()
        return achievement
    }
    
    /// Removes an achievement by ID.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - id: The achievement's ID
    static func removeAchievement(context: ModelContext, id: String) {
        let descriptor = FetchDescriptor<Achievement>()
        if let achievements = try? context.fetch(descriptor),
           let achievement = achievements.first(where: { $0.id == id }) {
            context.delete(achievement)
            try? context.save()
        }
    }
    
    /// Updates an achievement's alwaysOn status.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - id: The achievement's ID
    ///   - alwaysOn: New alwaysOn value
    static func setAchievementAlwaysOn(context: ModelContext, id: String, alwaysOn: Bool) {
        let descriptor = FetchDescriptor<Achievement>()
        if let achievements = try? context.fetch(descriptor),
           let achievement = achievements.first(where: { $0.id == id }) {
            achievement.alwaysOn = alwaysOn
            try? context.save()
        }
    }
    
    // MARK: - Navigation
    
    /// Sets the current screen.
    /// - Parameters:
    ///   - context: The SwiftData model context
    ///   - screen: The screen to navigate to
    static func setScreen(context: ModelContext, screen: Screen) {
        guard let state = fetchLeagueState(context: context) else { return }
        state.screen = screen
        try? context.save()
    }
    
    // MARK: - State Validation
    
    /// Validates and sanitizes the league state to ensure consistency.
    /// Call this on app launch to fix any corrupted or inconsistent state.
    /// - Parameter context: The SwiftData model context
    static func validateAndSanitizeState(context: ModelContext) {
        guard let state = fetchLeagueState(context: context) else { return }
        
        var needsSave = false
        
        // Check if we have an active tournament
        if let tournamentId = state.activeTournamentId {
            // Verify the tournament exists
            let descriptor = FetchDescriptor<Tournament>()
            let allTournaments = (try? context.fetch(descriptor)) ?? []
            let tournament = allTournaments.first { $0.id == tournamentId }
            
            if tournament == nil {
                // Tournament doesn't exist, clear reference
                state.activeTournamentId = nil
                state.screen = .tournaments
                needsSave = true
            } else if tournament?.status == .completed {
                // Tournament is completed, clear reference
                state.activeTournamentId = nil
                state.screen = .tournaments
                needsSave = true
            }
        } else {
            // No active tournament - only allow pre-tournament screens
            let validScreens: [Screen] = [.tournaments, .dashboard, .newTournament, .confirmNewTournament]
            if !validScreens.contains(state.screen) {
                state.screen = .tournaments
                needsSave = true
            }
        }
        
        // Map legacy screen values
        if state.screen == .dashboard {
            state.screen = .tournaments
            needsSave = true
        }
        if state.screen == .confirmNewTournament {
            state.screen = .newTournament
            needsSave = true
        }
        
        if needsSave {
            try? context.save()
        }
    }
    
    // MARK: - Helpers
    
    /// Fetches all achievements from the context.
    static func fetchAllAchievements(context: ModelContext) -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Fetches the league state.
    static func fetchLeagueState(context: ModelContext) -> LeagueState? {
        let descriptor = FetchDescriptor<LeagueState>()
        return (try? context.fetch(descriptor))?.first
    }
    
    /// Fetches the active tournament.
    static func fetchActiveTournament(context: ModelContext) -> Tournament? {
        guard let state = fetchLeagueState(context: context),
              let tournamentId = state.activeTournamentId else { return nil }
        
        let descriptor = FetchDescriptor<Tournament>()
        let allTournaments = (try? context.fetch(descriptor)) ?? []
        return allTournaments.first { $0.id == tournamentId }
    }
    
    /// Fetches a tournament by ID.
    static func fetchTournament(context: ModelContext, id: String) -> Tournament? {
        let descriptor = FetchDescriptor<Tournament>()
        let allTournaments = (try? context.fetch(descriptor)) ?? []
        return allTournaments.first { $0.id == id }
    }
}
