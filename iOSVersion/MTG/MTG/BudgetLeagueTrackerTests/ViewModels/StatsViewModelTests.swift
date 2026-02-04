import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for StatsViewModel
@Suite("StatsViewModel Tests", .serialized)
@MainActor
struct StatsViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads players and tournament info")
        func loadsPlayersAndTournamentInfo() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = StatsViewModel(context: context)
            
            #expect(viewModel.players.count == 4)
        }
    }
    
    @Suite("statsSubtitle")
    @MainActor
    struct StatsSubtitleTests {
        
        @Test("Formats subtitle correctly")
        func formatsSubtitle() throws {
            let context = try TestHelpers.bootstrappedContext()
            let player = TestFixtures.player(
                name: "Test",
                placementPoints: 25,
                achievementPoints: 10,
                wins: 5
            )
            context.insert(player)
            try context.save()
            
            let viewModel = StatsViewModel(context: context)
            let subtitle = viewModel.statsSubtitle(for: player)
            
            // Implementation shows total points (25+10=35), wins, games, and tournaments
            #expect(subtitle.contains("35"))  // total points
            #expect(subtitle.contains("5"))   // wins
            #expect(subtitle.contains("pts"))
            #expect(subtitle.contains("wins"))
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("hasPlayers reflects player count")
        func hasPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            var viewModel = StatsViewModel(context: context)
            
            #expect(viewModel.hasPlayers == false)
            
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            viewModel.refresh()
            
            #expect(viewModel.hasPlayers == true)
        }
        
        @Test("weeklyStandings returns sorted standings for current week")
        func weeklyStandings() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            let playerIds = tournament.presentPlayerIds
            
            tournament.weeklyPointsByPlayer = [
                playerIds[0]: WeeklyPlayerPoints(placementPoints: 10, achievementPoints: 2),
                playerIds[1]: WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 1),
                playerIds[2]: WeeklyPlayerPoints(placementPoints: 8, achievementPoints: 0),
                playerIds[3]: WeeklyPlayerPoints(placementPoints: 3, achievementPoints: 0)
            ]
            try context.save()
            
            let viewModel = StatsViewModel(context: context)
            viewModel.refresh()
            
            let standings = viewModel.weeklyStandings
            
            #expect(standings.count == 4)
            #expect(standings[0].points.total >= standings[1].points.total)
        }
        
        @Test("tournamentStandings returns all players sorted by total")
        func tournamentStandings() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = [
                TestFixtures.player(name: "High", placementPoints: 50, achievementPoints: 20),
                TestFixtures.player(name: "Medium", placementPoints: 30, achievementPoints: 10),
                TestFixtures.player(name: "Low", placementPoints: 10, achievementPoints: 5)
            ]
            
            for player in players {
                context.insert(player)
            }
            try context.save()
            
            let viewModel = StatsViewModel(context: context)
            let standings = viewModel.tournamentStandings
            
            #expect(standings.count == 3)
            #expect(standings[0].player.name == "High")
            #expect(standings[1].player.name == "Medium")
            #expect(standings[2].player.name == "Low")
        }
        
        @Test("hasWeeklyStandings returns true when league started and standings exist")
        func hasWeeklyStandings() throws {
            let context = try TestHelpers.contextWithTournament()
            let viewModel = StatsViewModel(context: context)
            
            #expect(viewModel.hasWeeklyStandings == true)
        }
    }
}
