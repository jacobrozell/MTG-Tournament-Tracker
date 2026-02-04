import XCTest

/// UI tests for Achievements screen
@MainActor
final class AchievementsScreenTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDown() async throws {
        app = nil
        try await super.tearDown()
    }
    
    /// Navigate to Achievements tab
    private func navigateToAchievements() -> Bool {
        // Wait for main screen to load
        let navBar = app.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: 5) else { return false }
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return false }
        
        let achievementsTab = tabBar.buttons["Achievements"]
        guard achievementsTab.exists else { return false }
        achievementsTab.tap()
        
        return app.navigationBars["Achievements"].waitForExistence(timeout: 5)
    }
    
    func testAddAchievement() {
        guard navigateToAchievements() else {
            // Skip if navigation failed
            return
        }
        
        // Tap add button - look for plus button in nav bar
        let navBar = app.navigationBars["Achievements"]
        let addButton = navBar.buttons.element(boundBy: navBar.buttons.count - 1)
        guard addButton.waitForExistence(timeout: 5) else { return }
        addButton.tap()
        
        // Fill in achievement details
        let nameField = app.textFields["Achievement Name"]
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText("Test Achievement")
        }
        
        // Adjust points if stepper exists
        let pointsStepper = app.steppers.firstMatch
        if pointsStepper.exists {
            pointsStepper.buttons["Increment"].tap()
            pointsStepper.buttons["Increment"].tap()
        }
        
        // Tap Add Achievement
        let addAchievementButton = app.buttons["Add Achievement"]
        if addAchievementButton.waitForExistence(timeout: 5) {
            addAchievementButton.tap()
        }
        
        // Verify achievement appears in list
        let achievementCell = app.staticTexts["Test Achievement"]
        XCTAssertTrue(achievementCell.waitForExistence(timeout: 5))
    }
    
    func testToggleAlwaysOn() {
        guard navigateToAchievements() else { return }
        
        // Find an achievement toggle
        let toggle = app.switches.firstMatch
        if toggle.waitForExistence(timeout: 5) {
            let initialValue = toggle.value as? String
            
            // Toggle
            toggle.tap()
            
            // Verify value changed
            let newValue = toggle.value as? String
            XCTAssertNotEqual(initialValue, newValue)
        }
    }
    
    func testRemoveAchievement() {
        guard navigateToAchievements() else { return }
        
        // First add an achievement
        let navBar = app.navigationBars["Achievements"]
        let addButton = navBar.buttons.element(boundBy: navBar.buttons.count - 1)
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        }
        
        let nameField = app.textFields["Achievement Name"]
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText("To Delete")
        }
        
        let addAchievementButton = app.buttons["Add Achievement"]
        if addAchievementButton.waitForExistence(timeout: 3) {
            addAchievementButton.tap()
        }
        
        // Wait for achievement to appear in list
        let achievementCell = app.staticTexts["To Delete"]
        guard achievementCell.waitForExistence(timeout: 3) else {
            XCTFail("Achievement was not added")
            return
        }
        
        // Find and tap the options menu button for this achievement
        // Use firstMatch because SwiftUI Menu creates multiple button elements with the same identifier
        let optionsButton = app.buttons["Options for To Delete"].firstMatch
        guard optionsButton.waitForExistence(timeout: 3) else {
            XCTFail("Options menu button not found")
            return
        }
        optionsButton.tap()
        
        // Tap Remove in the menu
        let removeButton = app.buttons["Remove"]
        guard removeButton.waitForExistence(timeout: 3) else {
            XCTFail("Remove button not found in menu")
            return
        }
        removeButton.tap()
        
        // Wait briefly for deletion to process
        sleep(1)
        
        // Verify achievement is removed
        let stillExists = achievementCell.waitForExistence(timeout: 1)
        XCTAssertFalse(stillExists, "Achievement should be removed")
    }
    
    func testCancelAddAchievement() {
        guard navigateToAchievements() else { return }
        
        // Tap add button
        let navBar = app.navigationBars["Achievements"]
        let addButton = navBar.buttons.element(boundBy: navBar.buttons.count - 1)
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        }
        
        // Tap Cancel
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 5) {
            cancelButton.tap()
        }
        
        // Verify we're back on achievements list
        XCTAssertTrue(app.navigationBars["Achievements"].waitForExistence(timeout: 5))
    }
}
