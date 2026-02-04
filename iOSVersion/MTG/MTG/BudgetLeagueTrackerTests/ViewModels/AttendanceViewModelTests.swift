import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for AttendanceViewModel
@Suite("AttendanceViewModel Tests", .serialized)
@MainActor
struct AttendanceViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads players and tournament info")
        func loadsPlayersAndTournamentInfo() throws {
            let context = try TestHelpers.contextWithTournament()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = AttendanceViewModel(context: context)
            
            #expect(viewModel.players.count == players.count + 4) // standard pod + inserted
            #expect(viewModel.currentWeek == 1)
        }
        
        @Test("Initializes all players as present by default")
        func initializesPlayersAsPresent() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            let viewModel = AttendanceViewModel(context: context)
            
            for player in players {
                #expect(viewModel.isPresent(player.id) == true)
            }
        }
    }
    
    @Suite("togglePresence")
    @MainActor
    struct TogglePresenceTests {
        
        @Test("Toggles player presence")
        func togglesPresence() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            let viewModel = AttendanceViewModel(context: context)
            let playerId = players[0].id
            
            #expect(viewModel.isPresent(playerId) == true)
            
            viewModel.togglePresence(for: playerId)
            #expect(viewModel.isPresent(playerId) == false)
            
            viewModel.togglePresence(for: playerId)
            #expect(viewModel.isPresent(playerId) == true)
        }
    }
    
    @Suite("addWeeklyPlayer")
    @MainActor
    struct AddWeeklyPlayerTests {
        
        @Test("Creates player and marks present")
        func createsAndMarksPresent() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let viewModel = AttendanceViewModel(context: context)
            viewModel.newPlayerName = "Weekly Player"
            viewModel.addWeeklyPlayer()
            
            let addedPlayer = viewModel.players.first { $0.name == "Weekly Player" }
            #expect(addedPlayer != nil)
            #expect(viewModel.isPresent(addedPlayer!.id) == true)
        }
        
        @Test("Clears input field after adding")
        func clearsInputField() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let viewModel = AttendanceViewModel(context: context)
            viewModel.newPlayerName = "New Player"
            viewModel.addWeeklyPlayer()
            
            #expect(viewModel.newPlayerName == "")
        }
    }
    
    @Suite("confirmAttendance")
    @MainActor
    struct ConfirmAttendanceTests {
        
        @Test("Confirms with present IDs and achievements flag")
        func confirmsWithPresentIdsAndFlag() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let viewModel = AttendanceViewModel(context: context)
            viewModel.achievementsOnThisWeek = false
            
            viewModel.confirmAttendance()
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.achievementsOnThisWeek == false)
        }
        
        @Test("Does not confirm when no players present")
        func doesNotConfirmWithNoPresent() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let viewModel = AttendanceViewModel(context: context)
            
            // Mark all players absent
            for player in viewModel.players {
                viewModel.presentStatus[player.id] = false
            }
            
            #expect(viewModel.canConfirmAttendance == false)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("presentPlayerIds returns only present players")
        func presentPlayerIds() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            let viewModel = AttendanceViewModel(context: context)
            
            // Mark some as absent
            viewModel.presentStatus[players[0].id] = false
            viewModel.presentStatus[players[1].id] = false
            
            #expect(viewModel.presentPlayerIds.count == 2)
            #expect(!viewModel.presentPlayerIds.contains(players[0].id))
            #expect(!viewModel.presentPlayerIds.contains(players[1].id))
        }
        
        @Test("canConfirmAttendance requires at least one present player")
        func canConfirmAttendance() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            let viewModel = AttendanceViewModel(context: context)
            
            #expect(viewModel.canConfirmAttendance == true)
            
            // Mark all absent
            for player in players {
                viewModel.presentStatus[player.id] = false
            }
            
            #expect(viewModel.canConfirmAttendance == false)
        }
    }
}
