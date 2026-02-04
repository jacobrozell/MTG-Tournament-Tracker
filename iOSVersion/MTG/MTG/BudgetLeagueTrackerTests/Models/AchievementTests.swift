import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for Achievement model
@Suite("Achievement Model Tests", .serialized)
@MainActor
struct AchievementTests {
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Default initialization")
        func defaultInitialization() {
            let achievement = Achievement(name: "Test Achievement", points: 1)
            
            #expect(achievement.name == "Test Achievement")
            #expect(achievement.points == 1)
            #expect(achievement.alwaysOn == false)
            #expect(!achievement.id.isEmpty)
        }
        
        @Test("Custom initialization with all parameters")
        func customInitialization() {
            let customId = "custom-achievement-id"
            let achievement = Achievement(
                id: customId,
                name: "Always On Achievement",
                points: 3,
                alwaysOn: true
            )
            
            #expect(achievement.id == customId)
            #expect(achievement.name == "Always On Achievement")
            #expect(achievement.points == 3)
            #expect(achievement.alwaysOn == true)
        }
        
        @Test("ID uniqueness across multiple achievements")
        func idUniqueness() {
            let a1 = Achievement(name: "Achievement 1", points: 1)
            let a2 = Achievement(name: "Achievement 2", points: 1)
            let a3 = Achievement(name: "Achievement 3", points: 1)
            
            #expect(a1.id != a2.id)
            #expect(a2.id != a3.id)
            #expect(a1.id != a3.id)
        }
    }
    
    @Suite("Properties")
    @MainActor
    struct PropertiesTests {
        
        @Test("Points can be zero or positive")
        func pointsRange() {
            let zeroPoints = Achievement(name: "Zero", points: 0)
            let onePoint = Achievement(name: "One", points: 1)
            let manyPoints = Achievement(name: "Many", points: 99)
            
            #expect(zeroPoints.points == 0)
            #expect(onePoint.points == 1)
            #expect(manyPoints.points == 99)
        }
        
        @Test("AlwaysOn toggle works")
        func alwaysOnToggle() {
            let achievement = Achievement(name: "Toggle Test", points: 1, alwaysOn: false)
            #expect(achievement.alwaysOn == false)
            
            achievement.alwaysOn = true
            #expect(achievement.alwaysOn == true)
            
            achievement.alwaysOn = false
            #expect(achievement.alwaysOn == false)
        }
    }
    
    @Suite("SwiftData Persistence")
    @MainActor
    struct PersistenceTests {
        
        @Test("Achievement persists to context")
        func persistsToContext() throws {
            let context = try TestHelpers.cleanContext()
            let achievement = Achievement(name: "Persistent", points: 2, alwaysOn: true)
            
            context.insert(achievement)
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(Achievement.self, from: context)
            #expect(fetched.count == 1)
            #expect(fetched.first?.name == "Persistent")
            #expect(fetched.first?.points == 2)
            #expect(fetched.first?.alwaysOn == true)
        }
        
        @Test("Achievement updates persist")
        func updatesPersist() throws {
            let context = try TestHelpers.cleanContext()
            let achievement = Achievement(name: "Original", points: 1, alwaysOn: false)
            context.insert(achievement)
            try context.save()
            
            achievement.name = "Updated"
            achievement.points = 5
            achievement.alwaysOn = true
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(Achievement.self, from: context).first!
            #expect(fetched.name == "Updated")
            #expect(fetched.points == 5)
            #expect(fetched.alwaysOn == true)
        }
    }
}
