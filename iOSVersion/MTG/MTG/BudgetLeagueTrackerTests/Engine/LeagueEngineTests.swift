import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Comprehensive tests for LeagueEngine business logic
@Suite("LeagueEngine Tests", .serialized)
@MainActor
struct LeagueEngineTests {
    
    // MARK: - Tournament Lifecycle Tests
    
    @Suite("createTournament")
    @MainActor
    struct CreateTournamentTests {
        
        @Test("Creates tournament with valid parameters")
        func createsWithValidParams() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let playerIds = players.map { $0.id }
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Spring League",
                totalWeeks: 8,
                randomPerWeek: 3,
                playerIds: playerIds
            )
            
            let tournaments = try TestHelpers.fetchAll(Tournament.self, from: context)
            #expect(tournaments.count == 1)
            #expect(tournaments.first?.name == "Spring League")
            #expect(tournaments.first?.totalWeeks == 8)
            #expect(tournaments.first?.randomAchievementsPerWeek == 3)
        }
        
        @Test("Clamps weeks to valid range", arguments: [
            (input: 0, expected: 1),
            (input: -5, expected: 1),
            (input: 100, expected: 99),
            (input: 150, expected: 99),
            (input: 50, expected: 50)
        ])
        func clampsWeeks(input: Int, expected: Int) throws {
            let context = try TestHelpers.bootstrappedContext()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Test",
                totalWeeks: input,
                randomPerWeek: 2,
                playerIds: []
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.totalWeeks == expected)
        }
        
        @Test("Clamps random achievements to valid range", arguments: [
            (input: -1, expected: 0),
            (input: -10, expected: 0),
            (input: 100, expected: 99),
            (input: 150, expected: 99),
            (input: 5, expected: 5)
        ])
        func clampsRandomAchievements(input: Int, expected: Int) throws {
            let context = try TestHelpers.bootstrappedContext()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Test",
                totalWeeks: 6,
                randomPerWeek: input,
                playerIds: []
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.randomAchievementsPerWeek == expected)
        }
        
        @Test("Sets active tournament ID in LeagueState")
        func setsActiveTournamentId() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Test",
                totalWeeks: 6,
                randomPerWeek: 2,
                playerIds: []
            )
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            
            #expect(state?.activeTournamentId == tournament?.id)
        }
        
        @Test("Sets screen to attendance")
        func setsScreenToAttendance() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Test",
                totalWeeks: 6,
                randomPerWeek: 2,
                playerIds: []
            )
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .attendance)
        }
        
        @Test("Increments tournamentsPlayed for selected players")
        func incrementsTournamentsPlayed() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let selectedIds = [players[0].id, players[1].id]
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Test",
                totalWeeks: 6,
                randomPerWeek: 2,
                playerIds: selectedIds
            )
            
            // Selected players should have tournamentsPlayed incremented
            #expect(players[0].tournamentsPlayed == 1)
            #expect(players[1].tournamentsPlayed == 1)
            // Non-selected players should be unchanged
            #expect(players[2].tournamentsPlayed == 0)
            #expect(players[3].tournamentsPlayed == 0)
        }
        
        @Test("Rolls active achievements for week 1")
        func rollsActiveAchievements() throws {
            let context = try TestHelpers.bootstrappedContext()
            let achievements = TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            let alwaysOnCount = achievements.filter { $0.alwaysOn }.count
            
            LeagueEngine.createTournament(
                context: context,
                name: "Test",
                totalWeeks: 6,
                randomPerWeek: 2,
                playerIds: []
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            // Should have at least the alwaysOn achievements
            #expect(tournament?.activeAchievementIds.count ?? 0 >= alwaysOnCount)
        }
    }
    
    @Suite("archiveTournament")
    @MainActor
    struct ArchiveTournamentTests {
        
        @Test("Marks tournament as completed")
        func marksTournamentCompleted() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.archiveTournament(context: context)
            
            let descriptor = FetchDescriptor<Tournament>()
            let tournaments = try context.fetch(descriptor)
            #expect(tournaments.first?.status == .completed)
        }
        
        @Test("Sets end date")
        func setsEndDate() throws {
            let context = try TestHelpers.contextWithTournament()
            let beforeArchive = Date()
            
            LeagueEngine.archiveTournament(context: context)
            
            let descriptor = FetchDescriptor<Tournament>()
            let tournaments = try context.fetch(descriptor)
            let endDate = tournaments.first?.endDate
            
            #expect(endDate != nil)
            #expect(endDate! >= beforeArchive)
        }
        
        @Test("Clears active tournament ID")
        func clearsActiveTournamentId() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.archiveTournament(context: context)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.activeTournamentId == nil)
        }
        
        @Test("Sets screen to tournaments")
        func setsScreenToTournaments() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.archiveTournament(context: context)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .tournaments)
        }
    }
    
    // MARK: - Player Management Tests
    
    @Suite("addPlayer")
    @MainActor
    struct AddPlayerTests {
        
        @Test("Creates player with trimmed name")
        func createsWithTrimmedName() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let player = LeagueEngine.addPlayer(context: context, name: "  John Doe  ")
            
            #expect(player?.name == "John Doe")
        }
        
        @Test("Returns nil for empty name")
        func returnsNilForEmptyName() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let player1 = LeagueEngine.addPlayer(context: context, name: "")
            let player2 = LeagueEngine.addPlayer(context: context, name: "   ")
            let player3 = LeagueEngine.addPlayer(context: context, name: "\n\t")
            
            #expect(player1 == nil)
            #expect(player2 == nil)
            #expect(player3 == nil)
        }
        
        @Test("Initializes stats to zero")
        func initializesStatsToZero() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let player = LeagueEngine.addPlayer(context: context, name: "Test Player")
            
            #expect(player?.placementPoints == 0)
            #expect(player?.achievementPoints == 0)
            #expect(player?.wins == 0)
            #expect(player?.gamesPlayed == 0)
        }
        
        @Test("Persists player to context")
        func persistsToContext() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            LeagueEngine.addPlayer(context: context, name: "New Player")
            
            let players = try TestHelpers.fetchAll(Player.self, from: context)
            #expect(players.contains { $0.name == "New Player" })
        }
    }
    
    @Suite("removePlayer")
    @MainActor
    struct RemovePlayerTests {
        
        @Test("Deletes existing player")
        func deletesExistingPlayer() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player(name: "To Delete")
            context.insert(player)
            try context.save()
            
            LeagueEngine.removePlayer(context: context, id: player.id)
            
            let players = try TestHelpers.fetchAll(Player.self, from: context)
            #expect(!players.contains { $0.id == player.id })
        }
        
        @Test("No-op for non-existent ID")
        func noOpForNonExistentId() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            try context.save()
            
            let countBefore = try TestHelpers.fetchAll(Player.self, from: context).count
            
            LeagueEngine.removePlayer(context: context, id: "non-existent-id")
            
            let countAfter = try TestHelpers.fetchAll(Player.self, from: context).count
            #expect(countBefore == countAfter)
        }
    }
    
    // MARK: - Attendance Tests
    
    @Suite("confirmAttendance")
    @MainActor
    struct ConfirmAttendanceTests {
        
        @Test("Sets present player IDs")
        func setsPresentPlayerIds() throws {
            let context = try TestHelpers.contextWithTournament()
            let presentIds = ["player1", "player2"]
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: presentIds,
                achievementsOnThisWeek: true
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.presentPlayerIds == presentIds)
        }
        
        @Test("Sets achievements flag")
        func setsAchievementsFlag() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: ["p1"],
                achievementsOnThisWeek: false
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.achievementsOnThisWeek == false)
        }
        
        @Test("Resets weekly points for all present players")
        func resetsWeeklyPoints() throws {
            let context = try TestHelpers.contextWithTournament()
            let presentIds = ["p1", "p2", "p3"]
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: presentIds,
                achievementsOnThisWeek: true
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            
            for id in presentIds {
                let points = tournament?.weeklyPointsByPlayer[id]
                #expect(points?.placementPoints == 0)
                #expect(points?.achievementPoints == 0)
            }
        }
        
        @Test("Clears pod history")
        func clearsPodHistory() throws {
            let context = try TestHelpers.contextWithTournament()
            
            // Add some fake pod history
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            tournament?.podHistorySnapshots = [PodSnapshot(
                playerIds: ["p1"],
                placements: [:],
                achievementChecks: [],
                playerDeltas: [:],
                weeklyDeltas: [:]
            )]
            try context.save()
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: ["p1"],
                achievementsOnThisWeek: true
            )
            
            let updatedTournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updatedTournament?.podHistorySnapshots.isEmpty == true)
        }
        
        @Test("Sets screen to pods")
        func setsScreenToPods() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: ["p1"],
                achievementsOnThisWeek: true
            )
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .pods)
        }
    }
    
    @Suite("addWeeklyPlayer")
    @MainActor
    struct AddWeeklyPlayerTests {
        
        @Test("Creates player and marks present")
        func createsAndMarksPresent() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let player = LeagueEngine.addWeeklyPlayer(context: context, name: "New Weekly Player")
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(player != nil)
            #expect(tournament?.presentPlayerIds.contains(player!.id) == true)
        }
        
        @Test("Increments tournaments played")
        func incrementsTournamentsPlayed() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let player = LeagueEngine.addWeeklyPlayer(context: context, name: "New Player")
            
            #expect(player?.tournamentsPlayed == 1)
        }
        
        @Test("Initializes weekly points")
        func initializesWeeklyPoints() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let player = LeagueEngine.addWeeklyPlayer(context: context, name: "New Player")
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            let points = tournament?.weeklyPointsByPlayer[player!.id]
            
            #expect(points != nil)
            #expect(points?.placementPoints == 0)
            #expect(points?.achievementPoints == 0)
        }
    }
    
    // MARK: - Pod Generation Tests
    
    @Suite("generatePodsForRound")
    @MainActor
    struct GeneratePodsForRoundTests {
        
        @Test("Round 1 shuffles randomly with correct pod sizes")
        func round1ShufflesRandomly() throws {
            let players = TestFixtures.players("A", "B", "C", "D", "E", "F", "G", "H")
            let presentIds = players.map { $0.id }
            
            let pods = LeagueEngine.generatePodsForRound(
                players: players,
                presentPlayerIds: presentIds,
                currentRound: 1,
                weeklyPointsByPlayer: [:]
            )
            
            // Should have 2 complete pods of 4
            #expect(pods.count == 2)
            #expect(pods[0].count == 4)
            #expect(pods[1].count == 4)
            
            // All players should be assigned
            let assignedPlayers = pods.flatMap { $0 }
            #expect(assignedPlayers.count == 8)
        }
        
        @Test("Round 2+ sorts by weekly points descending")
        func laterRoundsSortByPoints() throws {
            let players = TestFixtures.players("Low", "Medium", "High", "VeryHigh")
            let presentIds = players.map { $0.id }
            
            let weeklyPoints: [String: WeeklyPlayerPoints] = [
                players[0].id: WeeklyPlayerPoints(placementPoints: 2, achievementPoints: 0),  // 2
                players[1].id: WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 0),  // 5
                players[2].id: WeeklyPlayerPoints(placementPoints: 8, achievementPoints: 0),  // 8
                players[3].id: WeeklyPlayerPoints(placementPoints: 10, achievementPoints: 2)  // 12
            ]
            
            let pods = LeagueEngine.generatePodsForRound(
                players: players,
                presentPlayerIds: presentIds,
                currentRound: 2,
                weeklyPointsByPlayer: weeklyPoints
            )
            
            // Should be sorted: VeryHigh (12), High (8), Medium (5), Low (2)
            #expect(pods.count == 1)
            #expect(pods[0][0].name == "VeryHigh")
            #expect(pods[0][1].name == "High")
            #expect(pods[0][2].name == "Medium")
            #expect(pods[0][3].name == "Low")
        }
        
        @Test("Handles incomplete final pod")
        func handlesIncompletePod() throws {
            let players = TestFixtures.players("A", "B", "C", "D", "E", "F")
            let presentIds = players.map { $0.id }
            
            let pods = LeagueEngine.generatePodsForRound(
                players: players,
                presentPlayerIds: presentIds,
                currentRound: 1,
                weeklyPointsByPlayer: [:]
            )
            
            #expect(pods.count == 2)
            #expect(pods[0].count == 4)
            #expect(pods[1].count == 2)  // Incomplete pod
        }
        
        @Test("Returns empty for no present players")
        func returnsEmptyForNoPlayers() throws {
            let players = TestFixtures.players("A", "B")
            
            let pods = LeagueEngine.generatePodsForRound(
                players: players,
                presentPlayerIds: [],  // No one present
                currentRound: 1,
                weeklyPointsByPlayer: [:]
            )
            
            #expect(pods.isEmpty)
        }
        
        @Test("Pod size is always 4 or remainder", arguments: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        func podSizeIsCorrect(playerCount: Int) throws {
            let playerNames = (0..<playerCount).map { "Player \($0)" }
            let players = playerNames.map { Player(name: $0) }
            let presentIds = players.map { $0.id }
            
            let pods = LeagueEngine.generatePodsForRound(
                players: players,
                presentPlayerIds: presentIds,
                currentRound: 1,
                weeklyPointsByPlayer: [:]
            )
            
            // All pods except possibly the last should have 4 players
            for (index, pod) in pods.enumerated() {
                if index < pods.count - 1 {
                    #expect(pod.count == 4)
                } else {
                    #expect(pod.count <= 4)
                    #expect(pod.count > 0)
                }
            }
            
            // Total players should match
            let totalAssigned = pods.reduce(0) { $0 + $1.count }
            #expect(totalAssigned == playerCount)
        }
    }
    
    // MARK: - Auto-Save Tests
    
    @Suite("updatePlacement")
    @MainActor
    struct UpdatePlacementTests {
        
        @Test("Updates placement immediately")
        func updatesPlacementImmediately() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.updatePlacement(context: context, playerId: "player1", placement: 2)
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.roundPlacements["player1"] == 2)
        }
        
        @Test("Persists to tournament")
        func persistsToTournament() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.updatePlacement(context: context, playerId: "p1", placement: 1)
            LeagueEngine.updatePlacement(context: context, playerId: "p2", placement: 3)
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.roundPlacements.count == 2)
            #expect(tournament?.roundPlacements["p1"] == 1)
            #expect(tournament?.roundPlacements["p2"] == 3)
        }
    }
    
    @Suite("updateAchievementCheck")
    @MainActor
    struct UpdateAchievementCheckTests {
        
        @Test("Adds achievement check when checked")
        func addsWhenChecked() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.updateAchievementCheck(
                context: context,
                playerId: "p1",
                achievementId: "a1",
                checked: true
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.roundAchievementChecks.contains("p1:a1") == true)
        }
        
        @Test("Removes achievement check when unchecked")
        func removesWhenUnchecked() throws {
            let context = try TestHelpers.contextWithTournament()
            
            // First check it
            LeagueEngine.updateAchievementCheck(
                context: context,
                playerId: "p1",
                achievementId: "a1",
                checked: true
            )
            
            // Then uncheck it
            LeagueEngine.updateAchievementCheck(
                context: context,
                playerId: "p1",
                achievementId: "a1",
                checked: false
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.roundAchievementChecks.contains("p1:a1") == false)
        }
        
        @Test("Uses correct composite key format")
        func usesCorrectKeyFormat() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.updateAchievementCheck(
                context: context,
                playerId: "player-123",
                achievementId: "achievement-456",
                checked: true
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.roundAchievementChecks.contains("player-123:achievement-456") == true)
        }
    }
    
    // MARK: - Round Finalization Tests
    
    @Suite("finalizeRound")
    @MainActor
    struct FinalizeRoundTests {
        
        @Test("Calculates correct placement points", arguments: [
            (placement: 1, expectedPoints: 4),
            (placement: 2, expectedPoints: 3),
            (placement: 3, expectedPoints: 2),
            (placement: 4, expectedPoints: 1)
        ])
        func calculatesPlacementPoints(placement: Int, expectedPoints: Int) throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: placement]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            #expect(player.placementPoints == expectedPoints)
        }
        
        @Test("Awards win only for 1st place")
        func awardsWinOnlyForFirst() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = players.map { $0.id }
            var weeklyPoints: [String: WeeklyPlayerPoints] = [:]
            var placements: [String: Int] = [:]
            
            for (index, player) in players.enumerated() {
                weeklyPoints[player.id] = WeeklyPlayerPoints()
                placements[player.id] = index + 1  // 1, 2, 3, 4
            }
            
            tournament.weeklyPointsByPlayer = weeklyPoints
            tournament.roundPlacements = placements
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            // Only first place gets a win
            #expect(players[0].wins == 1)
            #expect(players[1].wins == 0)
            #expect(players[2].wins == 0)
            #expect(players[3].wins == 0)
        }
        
        @Test("Creates GameResult records")
        func createsGameResults() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = players.map { $0.id }
            tournament.weeklyPointsByPlayer = Dictionary(uniqueKeysWithValues: 
                players.map { ($0.id, WeeklyPlayerPoints()) }
            )
            tournament.roundPlacements = Dictionary(uniqueKeysWithValues:
                players.enumerated().map { ($1.id, $0 + 1) }
            )
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            let results = try TestHelpers.fetchAll(GameResult.self, from: context)
            #expect(results.count == 4)
        }
        
        @Test("Creates undo snapshot")
        func createsUndoSnapshot() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: 1]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            let updatedTournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updatedTournament?.podHistorySnapshots.count == 1)
        }
        
        @Test("Clears round data after finalization")
        func clearsRoundData() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: 1]
            tournament.roundAchievementChecks = ["some:check"]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            let updatedTournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updatedTournament?.roundPlacements.isEmpty == true)
            #expect(updatedTournament?.roundAchievementChecks.isEmpty == true)
        }
    }
    
    @Suite("clearRoundData")
    @MainActor
    struct ClearRoundDataTests {
        
        @Test("Clears placements and achievement checks")
        func clearsBoth() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            tournament.roundPlacements = ["p1": 1, "p2": 2]
            tournament.roundAchievementChecks = ["p1:a1", "p2:a1"]
            try context.save()
            
            LeagueEngine.clearRoundData(context: context)
            
            let updated = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updated?.roundPlacements.isEmpty == true)
            #expect(updated?.roundAchievementChecks.isEmpty == true)
        }
        
        @Test("Does not modify player stats")
        func doesNotModifyPlayerStats() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player(placementPoints: 10, wins: 2)
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.roundPlacements = [player.id: 1]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.clearRoundData(context: context)
            
            // Stats should be unchanged
            #expect(player.placementPoints == 10)
            #expect(player.wins == 2)
        }
    }
    
    @Suite("applyEditedRound")
    @MainActor
    struct ApplyEditedRoundTests {
        
        @Test("Applies new player stats after reversing old")
        func appliesNewPlayerStats() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: 1]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            // Finalize to add stats (1st place = 4 pts, 1 win)
            LeagueEngine.finalizeRound(context: context)
            
            #expect(player.placementPoints == 4)
            #expect(player.wins == 1)
            #expect(player.gamesPlayed == 1)
            
            // Edit to change to 4th place
            let newPlacements = [player.id: 4]
            LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
            
            #expect(player.placementPoints == 1) // 4th place = 1 pt
            #expect(player.wins == 0) // No longer a win
            #expect(player.gamesPlayed == 1) // Still 1 game
        }
        
        @Test("Applies new weekly points")
        func appliesNewWeeklyPoints() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: 2]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            var updated = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updated?.weeklyPointsByPlayer[player.id]?.placementPoints == 3) // 2nd place
            
            // Edit to 1st place
            let newPlacements = [player.id: 1]
            LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
            
            updated = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updated?.weeklyPointsByPlayer[player.id]?.placementPoints == 4) // 1st place
        }
        
        @Test("Replaces snapshot in history")
        func replacesSnapshot() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: 1]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            var updated = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updated?.podHistorySnapshots.count == 1)
            #expect(updated?.podHistorySnapshots.first?.placements[player.id] == 1)
            
            // Edit to 3rd place
            let newPlacements = [player.id: 3]
            LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
            
            updated = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updated?.podHistorySnapshots.count == 1) // Still 1, replaced not added
            #expect(updated?.podHistorySnapshots.first?.placements[player.id] == 3) // Updated
        }
        
        @Test("Updates GameResult records")
        func updatesGameResults() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = [player.id]
            tournament.weeklyPointsByPlayer = [player.id: WeeklyPlayerPoints()]
            tournament.roundPlacements = [player.id: 1]
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            LeagueEngine.finalizeRound(context: context)
            
            var results = try TestHelpers.fetchAll(GameResult.self, from: context)
            #expect(results.count == 1)
            #expect(results.first?.placement == 1)
            #expect(results.first?.placementPoints == 4)
            
            // Edit to 2nd place
            let newPlacements = [player.id: 2]
            LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
            
            results = try TestHelpers.fetchAll(GameResult.self, from: context)
            #expect(results.count == 1) // Still 1 record
            #expect(results.first?.placement == 2) // Updated
            #expect(results.first?.placementPoints == 3) // Updated
        }
    }
    
    // MARK: - Round/Week Progression Tests
    
    @Suite("nextRound")
    @MainActor
    struct NextRoundTests {
        
        @Test("Increments round within week")
        func incrementsRoundWithinWeek() throws {
            let context = try TestHelpers.contextWithTournament(round: 1)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.roundPlacements = [:]  // No placements to finalize
            try context.save()
            
            LeagueEngine.nextRound(context: context)
            
            let updated = try TestHelpers.fetchActiveTournament(from: context)
            #expect(updated?.currentRound == 2)
        }
        
        @Test("Transitions to attendance after 3 rounds")
        func transitionsAfterThreeRounds() throws {
            let context = try TestHelpers.contextWithTournament(week: 1, round: 3)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.roundPlacements = [:]
            try context.save()
            
            LeagueEngine.nextRound(context: context)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            let updated = try TestHelpers.fetchActiveTournament(from: context)
            
            // Should advance to week 2, round 1
            #expect(updated?.currentWeek == 2)
            #expect(updated?.currentRound == 1)
            #expect(state?.screen == .attendance)
        }
        
        @Test("Marks tournament complete on final week")
        func marksTournamentCompleteOnFinalWeek() throws {
            let context = try TestHelpers.contextWithTournament(week: 6, round: 3)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.totalWeeks = 6
            tournament.roundPlacements = [:]
            try context.save()
            
            LeagueEngine.nextRound(context: context)
            
            let updated = try TestHelpers.fetchActiveTournament(from: context)
            let state = try TestHelpers.fetchLeagueState(from: context)
            
            #expect(updated?.status == .completed)
            #expect(state?.screen == .tournamentStandings)
        }
    }
    
    @Suite("closeWeeklyStandings")
    @MainActor
    struct CloseWeeklyStandingsTests {
        
        @Test("Advances week correctly")
        func advancesWeekCorrectly() throws {
            let context = try TestHelpers.contextWithTournament(week: 2)
            
            LeagueEngine.closeWeeklyStandings(context: context)
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.currentWeek == 3)
            #expect(tournament?.currentRound == 1)
        }
        
        @Test("Transitions to tournament standings on final week")
        func transitionsOnFinalWeek() throws {
            let context = try TestHelpers.contextWithTournament(week: 6)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.totalWeeks = 6
            try context.save()
            
            LeagueEngine.closeWeeklyStandings(context: context)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .tournamentStandings)
        }
    }
    
    @Suite("exitWeeklyStandings")
    @MainActor
    struct ExitWeeklyStandingsTests {
        
        @Test("Returns to pods screen")
        func returnsToPods() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.attendance.rawValue
            try context.save()
            
            LeagueEngine.exitWeeklyStandings(context: context)
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.screen == .pods)
        }
    }
    
    @Suite("closeTournamentStandings")
    @MainActor
    struct CloseTournamentStandingsTests {
        
        @Test("Clears active tournament")
        func clearsActiveTournament() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.closeTournamentStandings(context: context)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.activeTournamentId == nil)
        }
        
        @Test("Returns to tournaments screen")
        func returnsToTournamentsScreen() throws {
            let context = try TestHelpers.contextWithTournament()
            
            LeagueEngine.closeTournamentStandings(context: context)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .tournaments)
        }
    }
    
    // MARK: - Achievement Management Tests
    
    @Suite("rollActiveAchievements")
    @MainActor
    struct RollActiveAchievementsTests {
        
        @Test("Always includes alwaysOn achievements")
        func includesAlwaysOn() throws {
            let achievements = TestFixtures.achievements(alwaysOnCount: 2, randomCount: 5)
            
            let active = LeagueEngine.rollActiveAchievements(
                achievements: achievements,
                randomPerWeek: 0  // No random ones
            )
            
            #expect(active.count == 2)
            #expect(active.allSatisfy { $0.alwaysOn })
        }
        
        @Test("Samples correct number of random achievements")
        func samplesCorrectNumber() throws {
            let achievements = TestFixtures.achievements(alwaysOnCount: 1, randomCount: 10)
            
            let active = LeagueEngine.rollActiveAchievements(
                achievements: achievements,
                randomPerWeek: 3
            )
            
            // 1 alwaysOn + 3 random = 4
            #expect(active.count == 4)
        }
        
        @Test("Handles edge case: 0 random requested")
        func handlesZeroRandom() throws {
            let achievements = TestFixtures.achievements(alwaysOnCount: 2, randomCount: 5)
            
            let active = LeagueEngine.rollActiveAchievements(
                achievements: achievements,
                randomPerWeek: 0
            )
            
            #expect(active.count == 2)
        }
        
        @Test("Handles edge case: all achievements are alwaysOn")
        func handlesAllAlwaysOn() throws {
            let achievements = TestFixtures.achievements(alwaysOnCount: 5, randomCount: 0)
            
            let active = LeagueEngine.rollActiveAchievements(
                achievements: achievements,
                randomPerWeek: 3
            )
            
            #expect(active.count == 5)
        }
        
        @Test("Handles more random requested than available")
        func handlesMoreRequestedThanAvailable() throws {
            let achievements = TestFixtures.achievements(alwaysOnCount: 1, randomCount: 2)
            
            let active = LeagueEngine.rollActiveAchievements(
                achievements: achievements,
                randomPerWeek: 10  // Request more than available
            )
            
            // Should get 1 alwaysOn + 2 random = 3 (all available)
            #expect(active.count == 3)
        }
    }
    
    @Suite("addAchievement")
    @MainActor
    struct AddAchievementTests {
        
        @Test("Creates achievement with valid name")
        func createsWithValidName() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let achievement = LeagueEngine.addAchievement(
                context: context,
                name: "Test Achievement",
                points: 2,
                alwaysOn: true
            )
            
            #expect(achievement != nil)
            #expect(achievement?.name == "Test Achievement")
            #expect(achievement?.points == 2)
            #expect(achievement?.alwaysOn == true)
        }
        
        @Test("Returns nil for empty name")
        func returnsNilForEmptyName() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let achievement = LeagueEngine.addAchievement(
                context: context,
                name: "   ",
                points: 1,
                alwaysOn: false
            )
            
            #expect(achievement == nil)
        }
    }
    
    @Suite("removeAchievement")
    @MainActor
    struct RemoveAchievementTests {
        
        @Test("Deletes existing achievement")
        func deletesExisting() throws {
            let context = try TestHelpers.bootstrappedContext()
            let achievement = TestFixtures.achievement()
            context.insert(achievement)
            try context.save()
            
            LeagueEngine.removeAchievement(context: context, id: achievement.id)
            
            let achievements = try TestHelpers.fetchAll(Achievement.self, from: context)
            #expect(!achievements.contains { $0.id == achievement.id })
        }
        
        @Test("No-op for non-existent ID")
        func noOpForNonExistent() throws {
            let context = try TestHelpers.bootstrappedContext()
            let countBefore = try TestHelpers.fetchAll(Achievement.self, from: context).count
            
            LeagueEngine.removeAchievement(context: context, id: "non-existent")
            
            let countAfter = try TestHelpers.fetchAll(Achievement.self, from: context).count
            #expect(countBefore == countAfter)
        }
    }
    
    @Suite("setAchievementAlwaysOn")
    @MainActor
    struct SetAchievementAlwaysOnTests {
        
        @Test("Updates alwaysOn flag")
        func updatesAlwaysOnFlag() throws {
            let context = try TestHelpers.bootstrappedContext()
            let achievement = TestFixtures.achievement(alwaysOn: false)
            context.insert(achievement)
            try context.save()
            
            LeagueEngine.setAchievementAlwaysOn(context: context, id: achievement.id, alwaysOn: true)
            
            #expect(achievement.alwaysOn == true)
        }
    }
    
    // MARK: - Navigation Tests
    
    @Suite("setScreen")
    @MainActor
    struct SetScreenTests {
        
        @Test("Updates screen correctly", arguments: Screen.allCases)
        func updatesScreenCorrectly(screen: Screen) throws {
            let context = try TestHelpers.bootstrappedContext()
            
            LeagueEngine.setScreen(context: context, screen: screen)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == screen)
        }
    }
    
    // MARK: - State Validation Tests
    
    @Suite("validateAndSanitizeState")
    @MainActor
    struct ValidateAndSanitizeStateTests {
        
        @Test("Clears invalid active tournament reference")
        func clearsInvalidReference() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = "non-existent-tournament"
            state.currentScreen = Screen.pods.rawValue
            try context.save()
            
            LeagueEngine.validateAndSanitizeState(context: context)
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.activeTournamentId == nil)
            #expect(updated?.screen == .tournaments)
        }
        
        @Test("Clears reference to completed tournament")
        func clearsCompletedTournamentReference() throws {
            let context = try TestHelpers.bootstrappedContext()
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            state.currentScreen = Screen.pods.rawValue
            try context.save()
            
            LeagueEngine.validateAndSanitizeState(context: context)
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.activeTournamentId == nil)
            #expect(updated?.screen == .tournaments)
        }
        
        @Test("Maps legacy dashboard screen to tournaments")
        func mapsLegacyDashboard() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.dashboard.rawValue
            try context.save()
            
            LeagueEngine.validateAndSanitizeState(context: context)
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.screen == .tournaments)
        }
        
        @Test("Maps legacy confirmNewTournament to newTournament")
        func mapsLegacyConfirmNewTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.confirmNewTournament.rawValue
            try context.save()
            
            LeagueEngine.validateAndSanitizeState(context: context)
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.screen == .newTournament)
        }
        
        @Test("Resets invalid screen when no active tournament")
        func resetsInvalidScreenWithoutActiveTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = nil
            state.currentScreen = Screen.pods.rawValue  // Invalid without tournament
            try context.save()
            
            LeagueEngine.validateAndSanitizeState(context: context)
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.screen == .tournaments)
        }
    }
    
    // MARK: - Helper Tests
    
    @Suite("fetchHelpers")
    @MainActor
    struct FetchHelperTests {
        
        @Test("fetchAllAchievements returns all achievements")
        func fetchAllAchievementsReturnsAll() throws {
            let context = try TestHelpers.bootstrappedContext()
            let achievements = TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            let fetched = LeagueEngine.fetchAllAchievements(context: context)
            
            // Should include default achievement from bootstrap + sample achievements
            #expect(fetched.count >= achievements.count)
        }
        
        @Test("fetchLeagueState returns singleton")
        func fetchLeagueStateReturnsSingleton() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let state = LeagueEngine.fetchLeagueState(context: context)
            
            #expect(state != nil)
        }
        
        @Test("fetchActiveTournament returns active tournament")
        func fetchActiveTournamentReturnsActive() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let tournament = LeagueEngine.fetchActiveTournament(context: context)
            
            #expect(tournament != nil)
            #expect(tournament?.name == "Test Tournament")
        }
        
        @Test("fetchActiveTournament returns nil when no active")
        func fetchActiveTournamentReturnsNilWhenNoActive() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let tournament = LeagueEngine.fetchActiveTournament(context: context)
            
            #expect(tournament == nil)
        }
        
        @Test("fetchTournament returns tournament by ID")
        func fetchTournamentReturnsById() throws {
            let context = try TestHelpers.bootstrappedContext()
            let tournament = TestFixtures.tournament(name: "Specific Tournament")
            context.insert(tournament)
            try context.save()
            
            let fetched = LeagueEngine.fetchTournament(context: context, id: tournament.id)
            
            #expect(fetched?.name == "Specific Tournament")
        }
    }
}
