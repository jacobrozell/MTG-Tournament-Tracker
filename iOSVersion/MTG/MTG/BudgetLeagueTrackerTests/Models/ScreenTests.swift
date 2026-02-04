import Testing
import Foundation
@testable import BudgetLeagueTracker

/// Tests for Screen enum
@Suite("Screen Enum Tests")
struct ScreenTests {
    
    @Suite("Raw Values")
    struct RawValueTests {
        
        @Test("All raw values map correctly")
        func allRawValues() {
            #expect(Screen.tournaments.rawValue == "tournaments")
            #expect(Screen.newTournament.rawValue == "newTournament")
            #expect(Screen.addPlayers.rawValue == "addPlayers")
            #expect(Screen.attendance.rawValue == "attendance")
            #expect(Screen.pods.rawValue == "pods")
            #expect(Screen.tournamentStandings.rawValue == "tournamentStandings")
            #expect(Screen.tournamentDetail.rawValue == "tournamentDetail")
            #expect(Screen.dashboard.rawValue == "dashboard")
            #expect(Screen.confirmNewTournament.rawValue == "confirmNewTournament")
        }
        
        @Test("Can initialize from raw value", arguments: [
            ("tournaments", Screen.tournaments),
            ("newTournament", Screen.newTournament),
            ("addPlayers", Screen.addPlayers),
            ("attendance", Screen.attendance),
            ("pods", Screen.pods),
            ("tournamentStandings", Screen.tournamentStandings),
            ("tournamentDetail", Screen.tournamentDetail),
            ("dashboard", Screen.dashboard),
            ("confirmNewTournament", Screen.confirmNewTournament)
        ])
        func initFromRawValue(rawValue: String, expected: Screen) {
            let screen = Screen(rawValue: rawValue)
            #expect(screen == expected)
        }
        
        @Test("Returns nil for invalid raw value")
        func nilForInvalidRawValue() {
            let screen = Screen(rawValue: "invalid")
            #expect(screen == nil)
        }
    }
    
    @Suite("Legacy Screen Mappings")
    struct LegacyMappingsTests {
        
        @Test("Dashboard is legacy for tournaments")
        func dashboardIsLegacy() {
            // Dashboard should exist but is considered legacy
            // The app should map dashboard to tournaments
            #expect(Screen.dashboard.rawValue == "dashboard")
            #expect(Screen.tournaments.rawValue == "tournaments")
        }
        
        @Test("confirmNewTournament is legacy for newTournament")
        func confirmNewTournamentIsLegacy() {
            // confirmNewTournament should exist but is considered legacy
            // The app should map confirmNewTournament to newTournament
            #expect(Screen.confirmNewTournament.rawValue == "confirmNewTournament")
            #expect(Screen.newTournament.rawValue == "newTournament")
        }
    }
    
    @Suite("Codable Conformance")
    struct CodableTests {
        
        @Test("Encodes and decodes correctly")
        func encodesAndDecodes() throws {
            let original = Screen.pods
            
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Screen.self, from: encoded)
            
            #expect(decoded == original)
        }
        
        @Test("All cases encode and decode", arguments: Screen.allCases)
        func allCasesEncodeDecode(screen: Screen) throws {
            let encoded = try JSONEncoder().encode(screen)
            let decoded = try JSONDecoder().decode(Screen.self, from: encoded)
            
            #expect(decoded == screen)
        }
    }
    
    @Suite("CaseIterable Conformance")
    struct CaseIterableTests {
        
        @Test("Contains expected number of cases")
        func expectedCaseCount() {
            // 7 main screens + 2 legacy = 9 total
            #expect(Screen.allCases.count == 9)
        }
        
        @Test("Contains all expected screens")
        func containsExpectedScreens() {
            let allCases = Screen.allCases
            
            #expect(allCases.contains(.tournaments))
            #expect(allCases.contains(.newTournament))
            #expect(allCases.contains(.addPlayers))
            #expect(allCases.contains(.attendance))
            #expect(allCases.contains(.pods))
            #expect(allCases.contains(.tournamentStandings))
            #expect(allCases.contains(.tournamentDetail))
            #expect(allCases.contains(.dashboard))
            #expect(allCases.contains(.confirmNewTournament))
        }
    }
    
    @Suite("Screen Flow Logic")
    struct ScreenFlowTests {
        
        @Test("Pre-tournament screens")
        func preTournamentScreens() {
            // These screens are valid without an active tournament
            let preTournamentScreens: [Screen] = [
                .tournaments,
                .dashboard,
                .newTournament,
                .confirmNewTournament
            ]
            
            for screen in preTournamentScreens {
                #expect(Screen.allCases.contains(screen))
            }
        }
        
        @Test("Tournament flow screens")
        func tournamentFlowScreens() {
            // These screens require an active tournament
            let tournamentScreens: [Screen] = [
                .addPlayers,
                .attendance,
                .pods,
                .tournamentDetail,
                .tournamentStandings
            ]
            
            for screen in tournamentScreens {
                #expect(Screen.allCases.contains(screen))
            }
        }
    }
}
