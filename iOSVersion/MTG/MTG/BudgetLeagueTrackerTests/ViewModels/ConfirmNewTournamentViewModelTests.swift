import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for ConfirmNewTournamentViewModel — data flow: navigation only
@Suite("ConfirmNewTournamentViewModel Tests", .serialized)
@MainActor
struct ConfirmNewTournamentViewModelTests {

    @Suite("confirmStart")
    @MainActor
    struct ConfirmStartTests {

        @Test("Sets screen to newTournament")
        func setsScreenToNewTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.tournaments.rawValue
            try context.save()

            let viewModel = ConfirmNewTournamentViewModel(context: context)
            viewModel.confirmStart()

            let updatedState = try TestHelpers.fetchLeagueState(from: context)
            #expect(updatedState?.screen == .newTournament)
        }
    }

    @Suite("cancel")
    @MainActor
    struct CancelTests {

        @Test("Sets screen to tournaments")
        func setsScreenToTournaments() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.confirmNewTournament.rawValue
            try context.save()

            let viewModel = ConfirmNewTournamentViewModel(context: context)
            viewModel.cancel()

            let updatedState = try TestHelpers.fetchLeagueState(from: context)
            #expect(updatedState?.screen == .tournaments)
        }
    }
}
