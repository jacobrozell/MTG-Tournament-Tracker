import Testing
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import BudgetLeagueTracker

/// Snapshot tests for screen-level visual regression
/// Note: Set `SnapshotTestConfiguration.record = true` to generate reference snapshots
@Suite("Screen Snapshot Tests", .serialized)
@MainActor
struct ScreenSnapshotTests {
    
    // MARK: - TournamentsView Snapshots
    
    @Suite("TournamentsView")
    @MainActor
    struct TournamentsViewSnapshots {
        
        @Test("Empty state")
        func emptyState() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = TournamentsViewModel(context: context)
            let view = TournamentsView(viewModel: viewModel)
                .frame(width: 390, height: 844)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("With tournaments")
        func withTournaments() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let ongoing = TestFixtures.tournament(name: "Spring League")
            ongoing.currentWeek = 3
            context.insert(ongoing)
            
            let completed = TestFixtures.completedTournament()
            context.insert(completed)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            let view = TournamentsView(viewModel: viewModel)
                .frame(width: 390, height: 844)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - StatsView Snapshots
    
    @Suite("StatsView")
    @MainActor
    struct StatsViewSnapshots {
        @Test("Empty state")
        func emptyState() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = StatsViewModel(context: context)
            let view = StatsView(viewModel: viewModel)
                .frame(width: 390, height: 844)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("With stats")
        func withStats() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let players = [
                TestFixtures.player(name: "Alice", placementPoints: 45, achievementPoints: 12, wins: 8, gamesPlayed: 15),
                TestFixtures.player(name: "Bob", placementPoints: 38, achievementPoints: 8, wins: 6, gamesPlayed: 15),
                TestFixtures.player(name: "Charlie", placementPoints: 30, achievementPoints: 10, wins: 4, gamesPlayed: 15)
            ]
            
            for player in players {
                context.insert(player)
            }
            try context.save()
            
            let viewModel = StatsViewModel(context: context)
            let view = StatsView(viewModel: viewModel)
                .frame(width: 390, height: 844)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - AchievementsView Snapshots
    
    @Suite("AchievementsView")
    @MainActor
    struct AchievementsViewSnapshots {
        @Test("Empty state")
        func emptyState() throws {
            let context = try TestHelpers.cleanContext()
            
            // Bootstrap state without default achievement
            let state = LeagueState()
            context.insert(state)
            try context.save()
            
            let viewModel = AchievementsViewModel(context: context)
            let view = AchievementsView(viewModel: viewModel)
                .frame(width: 390, height: 844)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("With achievements")
        func withAchievements() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            let viewModel = AchievementsViewModel(context: context)
            let view = AchievementsView(viewModel: viewModel)
                .frame(width: 390, height: 844)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - Note: Additional screen snapshots would require more setup
    // NewTournamentView, AttendanceView, PodsView require specific tournament states
    // TournamentStandingsView requires a completed tournament with results
    // These can be added as the test infrastructure matures
}
