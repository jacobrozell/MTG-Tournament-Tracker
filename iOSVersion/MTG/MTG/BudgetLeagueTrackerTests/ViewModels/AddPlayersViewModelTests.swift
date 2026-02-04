import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for AddPlayersViewModel — data flow: context ↔ VM → LeagueEngine
@Suite("AddPlayersViewModel Tests", .serialized)
@MainActor
struct AddPlayersViewModelTests {

    @Suite("Initialization and refresh")
    @MainActor
    struct InitAndRefreshTests {

        @Test("Init loads players and defaults")
        func initLoadsPlayersAndDefaults() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()

            let viewModel = AddPlayersViewModel(context: context)

            #expect(viewModel.players.count == 4)
            #expect(viewModel.totalWeeks == AppConstants.League.defaultTotalWeeks)
            #expect(viewModel.randomAchievementsPerWeek == AppConstants.League.defaultRandomAchievementsPerWeek)
        }

        @Test("Refresh repopulates players and resets defaults")
        func refreshRepopulatesPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AddPlayersViewModel(context: context)
            #expect(viewModel.players.isEmpty)

            LeagueEngine.addPlayer(context: context, name: "New Player")
            try context.save()
            viewModel.refresh()

            #expect(viewModel.players.count == 1)
            #expect(viewModel.players.first?.name == "New Player")
            #expect(viewModel.totalWeeks == AppConstants.League.defaultTotalWeeks)
            #expect(viewModel.randomAchievementsPerWeek == AppConstants.League.defaultRandomAchievementsPerWeek)
        }
    }

    @Suite("addPlayer")
    @MainActor
    struct AddPlayerTests {

        @Test("Adds player with non-empty trimmed name and clears newPlayerName")
        func addsPlayerAndClearsName() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AddPlayersViewModel(context: context)

            viewModel.newPlayerName = "  New Player  "
            viewModel.addPlayer()

            #expect(viewModel.newPlayerName == "")
            #expect(viewModel.players.count == 1)
            #expect(viewModel.players.first?.name == "New Player")
        }

        @Test("No-op for empty name")
        func noOpForEmptyName() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AddPlayersViewModel(context: context)

            viewModel.newPlayerName = ""
            viewModel.addPlayer()

            #expect(viewModel.players.isEmpty)
        }

        @Test("No-op for whitespace-only name")
        func noOpForWhitespaceName() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AddPlayersViewModel(context: context)

            viewModel.newPlayerName = "   \n\t  "
            viewModel.addPlayer()

            #expect(viewModel.players.isEmpty)
        }
    }

    @Suite("removePlayer")
    @MainActor
    struct RemovePlayerTests {

        @Test("Removes player via LeagueEngine and refresh updates list")
        func removesPlayerAndRefreshes() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()

            let viewModel = AddPlayersViewModel(context: context)
            #expect(viewModel.players.count == 4)
            let toRemove = viewModel.players[0]

            viewModel.removePlayer(toRemove)

            #expect(viewModel.players.count == 3)
            #expect(!viewModel.players.contains { $0.id == toRemove.id })
        }
    }

    @Suite("canStartTournament")
    @MainActor
    struct CanStartTournamentTests {

        @Test("False when players empty")
        func falseWhenEmpty() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AddPlayersViewModel(context: context)

            #expect(viewModel.canStartTournament == false)
        }

        @Test("True when players not empty")
        func trueWhenNotEmpty() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()

            let viewModel = AddPlayersViewModel(context: context)

            #expect(viewModel.canStartTournament == true)
        }
    }

    @Suite("startTournament")
    @MainActor
    struct StartTournamentTests {

        @Test("When canStartTournament creates tournament and sets active tournament and screen")
        func createsTournamentAndSetsScreen() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()

            let viewModel = AddPlayersViewModel(context: context)
            viewModel.totalWeeks = 8
            viewModel.randomAchievementsPerWeek = 3
            viewModel.startTournament()

            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            let state = try TestHelpers.fetchLeagueState(from: context)

            #expect(tournament != nil)
            #expect(tournament?.name == "Tournament")
            #expect(tournament?.totalWeeks == 8)
            #expect(tournament?.randomAchievementsPerWeek == 3)
            #expect(state?.activeTournamentId == tournament?.id)
            #expect(state?.screen == .attendance)
        }

        @Test("When no players no-ops")
        func noOpWhenNoPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AddPlayersViewModel(context: context)

            viewModel.startTournament()

            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament == nil)
        }
    }

    @Suite("cancel")
    @MainActor
    struct CancelTests {

        @Test("Sets screen to tournaments")
        func setsScreenToTournaments() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.addPlayers.rawValue
            try context.save()

            let viewModel = AddPlayersViewModel(context: context)
            viewModel.cancel()

            let updatedState = try TestHelpers.fetchLeagueState(from: context)
            #expect(updatedState?.screen == .tournaments)
        }
    }
}
