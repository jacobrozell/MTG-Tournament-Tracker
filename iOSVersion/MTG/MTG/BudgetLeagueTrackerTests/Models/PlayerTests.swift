import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for Player model
@Suite("Player Model Tests", .serialized)
@MainActor
struct PlayerTests {
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Default initialization with name only")
        func defaultInitialization() {
            let player = Player(name: "Test Player")
            
            #expect(player.name == "Test Player")
            #expect(!player.id.isEmpty)
            #expect(player.placementPoints == AppConstants.Scoring.initialPlacementPoints)
            #expect(player.achievementPoints == AppConstants.Scoring.initialAchievementPoints)
            #expect(player.wins == AppConstants.Scoring.initialWins)
            #expect(player.gamesPlayed == AppConstants.Scoring.initialGamesPlayed)
            #expect(player.tournamentsPlayed == 0)
        }
        
        @Test("Custom initialization with all parameters")
        func customInitialization() {
            let customId = "custom-id-123"
            let player = Player(
                id: customId,
                name: "Custom Player",
                placementPoints: 50,
                achievementPoints: 20,
                wins: 10,
                gamesPlayed: 25,
                tournamentsPlayed: 3
            )
            
            #expect(player.id == customId)
            #expect(player.name == "Custom Player")
            #expect(player.placementPoints == 50)
            #expect(player.achievementPoints == 20)
            #expect(player.wins == 10)
            #expect(player.gamesPlayed == 25)
            #expect(player.tournamentsPlayed == 3)
        }
        
        @Test("ID uniqueness across multiple players")
        func idUniqueness() {
            let player1 = Player(name: "Player 1")
            let player2 = Player(name: "Player 2")
            let player3 = Player(name: "Player 3")
            
            #expect(player1.id != player2.id)
            #expect(player2.id != player3.id)
            #expect(player1.id != player3.id)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("totalPoints sums placement and achievement points", arguments: [
            (placement: 0, achievement: 0, expected: 0),
            (placement: 10, achievement: 0, expected: 10),
            (placement: 0, achievement: 5, expected: 5),
            (placement: 25, achievement: 15, expected: 40),
            (placement: 100, achievement: 50, expected: 150)
        ])
        func totalPointsCalculation(placement: Int, achievement: Int, expected: Int) {
            let player = Player(
                name: "Test",
                placementPoints: placement,
                achievementPoints: achievement
            )
            
            #expect(player.totalPoints == expected)
        }
        
        @Test("totalPoints updates when components change")
        func totalPointsDynamic() {
            let player = Player(name: "Test")
            #expect(player.totalPoints == 0)
            
            player.placementPoints = 10
            #expect(player.totalPoints == 10)
            
            player.achievementPoints = 5
            #expect(player.totalPoints == 15)
            
            player.placementPoints = 20
            #expect(player.totalPoints == 25)
        }
    }
    
    @Suite("SwiftData Persistence")
    @MainActor
    struct PersistenceTests {
        
        @Test("Player persists to context")
        func persistsToContext() throws {
            let context = try TestHelpers.cleanContext()
            let player = Player(name: "Persistent Player")
            
            context.insert(player)
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(Player.self, from: context)
            #expect(fetched.count == 1)
            #expect(fetched.first?.name == "Persistent Player")
        }
        
        @Test("Player properties persist correctly")
        func propertiesPersist() throws {
            let context = try TestHelpers.cleanContext()
            let player = Player(
                name: "Full Player",
                placementPoints: 30,
                achievementPoints: 15,
                wins: 5,
                gamesPlayed: 12,
                tournamentsPlayed: 2
            )
            
            context.insert(player)
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(Player.self, from: context).first!
            #expect(fetched.name == "Full Player")
            #expect(fetched.placementPoints == 30)
            #expect(fetched.achievementPoints == 15)
            #expect(fetched.wins == 5)
            #expect(fetched.gamesPlayed == 12)
            #expect(fetched.tournamentsPlayed == 2)
        }
        
        @Test("Player updates persist")
        func updatesPersist() throws {
            let context = try TestHelpers.cleanContext()
            let player = Player(name: "Updatable")
            context.insert(player)
            try context.save()
            
            player.placementPoints = 100
            player.wins = 25
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(Player.self, from: context).first!
            #expect(fetched.placementPoints == 100)
            #expect(fetched.wins == 25)
        }
    }
}
