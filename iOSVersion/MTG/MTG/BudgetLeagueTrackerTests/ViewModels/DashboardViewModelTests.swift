import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for DashboardViewModel — data flow: context → VM state
@Suite("DashboardViewModel Tests", .serialized)
@MainActor
struct DashboardViewModelTests {

    @Suite("Initialization and refresh")
    @MainActor
    struct InitAndRefreshTests {

        @Test("When no active tournament isLeagueStarted false and currentWeek 0")
        func noActiveTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = DashboardViewModel(context: context)

            #expect(viewModel.isLeagueStarted == false)
            #expect(viewModel.currentWeek == 0)
        }

        @Test("When active tournament exists isLeagueStarted true and currentWeek matches")
        func withActiveTournament() throws {
            let context = try TestHelpers.contextWithTournament(week: 3, round: 2)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!

            let viewModel = DashboardViewModel(context: context)

            #expect(viewModel.isLeagueStarted == true)
            #expect(viewModel.currentWeek == tournament.currentWeek)
            #expect(viewModel.currentWeek == 3)
        }

        @Test("Refresh updates state when tournament state changes")
        func refreshUpdatesState() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = DashboardViewModel(context: context)
            #expect(viewModel.isLeagueStarted == false)

            _ = try TestHelpers.contextWithTournament(week: 2)
            // Re-use same context - we need to create tournament in the same context
            let players = TestFixtures.insertStandardPlayers(into: context)
            let tournament = Tournament(name: "Test", totalWeeks: 6, randomAchievementsPerWeek: 2)
            tournament.currentWeek = 2
            tournament.currentRound = 1
            tournament.presentPlayerIds = players.map { $0.id }
            context.insert(tournament)
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()

            viewModel.refresh()

            #expect(viewModel.isLeagueStarted == true)
            #expect(viewModel.currentWeek == 2)
        }
    }

    @Suite("startNewTournament")
    @MainActor
    struct StartNewTournamentTests {

        @Test("Sets screen to newTournament")
        func setsScreenToNewTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.dashboard.rawValue
            try context.save()

            let viewModel = DashboardViewModel(context: context)
            viewModel.startNewTournament()

            let updatedState = try TestHelpers.fetchLeagueState(from: context)
            #expect(updatedState?.screen == .newTournament)
        }
    }
}
