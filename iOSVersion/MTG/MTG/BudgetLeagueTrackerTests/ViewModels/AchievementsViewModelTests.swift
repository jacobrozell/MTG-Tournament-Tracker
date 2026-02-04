import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for AchievementsViewModel
@Suite("AchievementsViewModel Tests", .serialized)
@MainActor
struct AchievementsViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads all achievements")
        func loadsAllAchievements() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            let viewModel = AchievementsViewModel(context: context)
            
            // Should include default achievement + sample achievements
            #expect(viewModel.achievements.count >= 5)
        }
    }
    
    @Suite("showNewAchievement and dismissNewAchievement")
    @MainActor
    struct SheetPresentationTests {
        
        @Test("Shows and dismisses new achievement sheet")
        func showsAndDismisses() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AchievementsViewModel(context: context)
            
            #expect(viewModel.isShowingNewAchievement == false)
            
            viewModel.showNewAchievement()
            #expect(viewModel.isShowingNewAchievement == true)
            
            viewModel.dismissNewAchievement()
            #expect(viewModel.isShowingNewAchievement == false)
        }
    }
    
    @Suite("makeNewAchievementViewModel")
    @MainActor
    struct MakeNewAchievementViewModelTests {
        
        @Test("Creates ViewModel with callbacks")
        func createsWithCallbacks() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = AchievementsViewModel(context: context)
            viewModel.showNewAchievement()
            
            let newAchievementVM = viewModel.makeNewAchievementViewModel()
            
            // Simulate adding - should dismiss
            newAchievementVM.name = "Test"
            newAchievementVM.points = 1
            newAchievementVM.addAchievement()
            
            // After a brief delay, the callback should have been called
            #expect(viewModel.isShowingNewAchievement == false)
        }
    }
    
    @Suite("removeAchievement")
    @MainActor
    struct RemoveAchievementTests {
        
        @Test("Removes achievement and refreshes")
        func removesAchievement() throws {
            let context = try TestHelpers.bootstrappedContext()
            let achievements = TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            let viewModel = AchievementsViewModel(context: context)
            let initialCount = viewModel.achievements.count
            
            let toRemove = achievements[0]
            viewModel.removeAchievement(toRemove)
            
            #expect(viewModel.achievements.count == initialCount - 1)
            #expect(!viewModel.achievements.contains { $0.id == toRemove.id })
        }
    }
    
    @Suite("toggleAlwaysOn")
    @MainActor
    struct ToggleAlwaysOnTests {
        
        @Test("Toggles alwaysOn flag and refreshes")
        func togglesAlwaysOn() throws {
            let context = try TestHelpers.bootstrappedContext()
            let achievement = TestFixtures.achievement(alwaysOn: false)
            context.insert(achievement)
            try context.save()
            
            let viewModel = AchievementsViewModel(context: context)
            
            viewModel.toggleAlwaysOn(achievement)
            
            let updated = viewModel.achievements.first { $0.id == achievement.id }
            #expect(updated?.alwaysOn == true)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("hasAchievements reflects achievement count")
        func hasAchievements() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let viewModel = AchievementsViewModel(context: context)
            
            // Bootstrap context has default achievement
            #expect(viewModel.hasAchievements == true)
        }
    }
}

/// Tests for NewAchievementViewModel
@Suite("NewAchievementViewModel Tests")
@MainActor
struct NewAchievementViewModelTests {
    
    @Suite("addAchievement")
    @MainActor
    struct AddAchievementTests {
        
        @Test("Creates achievement and calls onAdd callback")
        func createsAndCallsCallback() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewAchievementViewModel(context: context)
            
            var callbackCalled = false
            viewModel.onAdd = { callbackCalled = true }
            
            viewModel.name = "Test Achievement"
            viewModel.points = 2
            viewModel.alwaysOn = true
            viewModel.addAchievement()
            
            #expect(callbackCalled == true)
            
            let achievements = try TestHelpers.fetchAll(Achievement.self, from: context)
            let created = achievements.first { $0.name == "Test Achievement" }
            #expect(created != nil)
            #expect(created?.points == 2)
            #expect(created?.alwaysOn == true)
        }
    }
    
    @Suite("cancel")
    @MainActor
    struct CancelTests {
        
        @Test("Calls onCancel callback")
        func callsCallback() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewAchievementViewModel(context: context)
            
            var callbackCalled = false
            viewModel.onCancel = { callbackCalled = true }
            
            viewModel.cancel()
            
            #expect(callbackCalled == true)
        }
    }
    
    @Suite("reset")
    @MainActor
    struct ResetTests {
        
        @Test("Resets form to defaults")
        func resetsToDefaults() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewAchievementViewModel(context: context)
            
            viewModel.name = "Test"
            viewModel.points = 5
            viewModel.alwaysOn = true
            
            viewModel.reset()
            
            #expect(viewModel.name == "")
            #expect(viewModel.points == 1)
            #expect(viewModel.alwaysOn == false)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("canAdd requires non-empty name")
        func canAdd() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewAchievementViewModel(context: context)
            
            viewModel.name = ""
            #expect(viewModel.canAdd == false)
            
            viewModel.name = "   "
            #expect(viewModel.canAdd == false)
            
            viewModel.name = "Test"
            #expect(viewModel.canAdd == true)
        }
    }
}
