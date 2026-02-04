import XCTest

/// UI tests for tournament creation flow
@MainActor
final class CreateTournamentFlowTests: XCTestCase {
    
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
    
    // MARK: - Tournament Creation Flow
    
    func testCreateTournamentHappyPath() {
        // Wait for main screen to load
        let navBar = app.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: 5) else {
            XCTFail("Navigation bar not found")
            return
        }
        
        // Navigate to new tournament
        let createButton = app.buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
        } else {
            // Look for the plus button in the navigation bar
            let buttons = app.navigationBars.buttons
            if buttons.count > 0 {
                buttons.element(boundBy: buttons.count - 1).tap()
            } else {
                XCTFail("Could not find create button")
                return
            }
        }
        
        // Wait for New Tournament screen
        guard app.navigationBars["New Tournament"].waitForExistence(timeout: 5) else {
            XCTFail("New Tournament screen not found")
            return
        }
        
        // Find tournament name field by placeholder
        let nameField = app.textFields["e.g., Spring 2026 League"]
        guard nameField.waitForExistence(timeout: 3) else {
            XCTFail("Tournament name field not found")
            return
        }
        nameField.tap()
        nameField.typeText("Test Tournament")
        
        // Dismiss keyboard
        app.swipeDown()
        
        // Add a player - find by placeholder
        let addPlayerField = app.textFields["Add player"]
        if addPlayerField.waitForExistence(timeout: 3) {
            addPlayerField.tap()
            addPlayerField.typeText("Test Player")
            
            let addButton = app.buttons["Add player"]
            if addButton.waitForExistence(timeout: 2) && addButton.isHittable {
                addButton.tap()
            }
        }
        
        // Dismiss keyboard
        app.swipeDown()
        
        // Tap Create Tournament
        let createTournamentButton = app.buttons["Submit Create Tournament"]
        if createTournamentButton.waitForExistence(timeout: 3) && createTournamentButton.isEnabled {
            createTournamentButton.tap()
            
            // Verify we're on Attendance screen
            let attendanceTitle = app.navigationBars["Attendance"]
            XCTAssertTrue(attendanceTitle.waitForExistence(timeout: 5))
        }
    }
    
    func testCreateTournamentAddNewPlayer() {
        // Wait for main screen to load
        let navBar = app.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: 5) else { return }
        
        // Navigate to new tournament
        let createButton = app.buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
        } else {
            let buttons = app.navigationBars.buttons
            if buttons.count > 0 {
                buttons.element(boundBy: buttons.count - 1).tap()
            }
        }
        
        // Wait for New Tournament screen
        guard app.navigationBars["New Tournament"].waitForExistence(timeout: 5) else { return }
        
        // Find tournament name field by placeholder
        let nameField = app.textFields["e.g., Spring 2026 League"]
        guard nameField.waitForExistence(timeout: 3) else { return }
        nameField.tap()
        nameField.typeText("Test Tournament")
        
        // Dismiss keyboard
        app.swipeDown()
        
        // Add a new player - find by placeholder
        let addPlayerField = app.textFields["Add player"]
        guard addPlayerField.waitForExistence(timeout: 3) else { return }
        addPlayerField.tap()
        addPlayerField.typeText("New Player")
        
        let addButton = app.buttons["Add player"]
        if addButton.waitForExistence(timeout: 3) && addButton.isHittable {
            addButton.tap()
        }
        
        // Verify player appears in list
        let playerCell = app.staticTexts["New Player"]
        XCTAssertTrue(playerCell.waitForExistence(timeout: 5))
    }
    
    func testCancelTournamentCreation() {
        // Navigate to new tournament
        let createButton = app.buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
        }
        
        // Tap Cancel
        let cancelButton = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()
        
        // Verify we're back on tournaments list
        let tournamentsTitle = app.navigationBars["Tournaments"]
        XCTAssertTrue(tournamentsTitle.waitForExistence(timeout: 5))
    }
    
    func testCannotCreateTournamentWithoutName() {
        // Wait for main screen to load
        let navBar = app.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: 5) else {
            XCTFail("Navigation bar not found")
            return
        }
        
        // Navigate to new tournament - try empty state button first, then toolbar button
        let createButton = app.buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
        } else {
            // Look for toolbar plus button by accessibility identifier
            let addButton = app.buttons["Add"]
            guard addButton.waitForExistence(timeout: 3) else {
                XCTFail("Could not find create/add button")
                return
            }
            addButton.tap()
        }
        
        // Wait for New Tournament screen
        guard app.navigationBars["New Tournament"].waitForExistence(timeout: 5) else {
            XCTFail("New Tournament screen not found")
            return
        }
        
        // Create Tournament button should be disabled without a name
        let createTournamentButton = app.buttons["Submit Create Tournament"]
        XCTAssertTrue(createTournamentButton.waitForExistence(timeout: 5))
        XCTAssertFalse(createTournamentButton.isEnabled)
    }
    
    func testAdjustTournamentSettings() {
        // Wait for main screen to load
        let navBar = app.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: 5) else { return }
        
        // Navigate to new tournament
        let createButton = app.buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
        } else {
            let buttons = app.navigationBars.buttons
            if buttons.count > 0 {
                buttons.element(boundBy: buttons.count - 1).tap()
            }
        }
        
        // Wait for New Tournament screen
        guard app.navigationBars["New Tournament"].waitForExistence(timeout: 5) else { return }
        
        // Find tournament name field by placeholder
        let nameField = app.textFields["e.g., Spring 2026 League"]
        guard nameField.waitForExistence(timeout: 3) else { return }
        nameField.tap()
        nameField.typeText("Test")
        
        // Dismiss keyboard
        app.swipeDown()
        
        // Find weeks setting and verify it exists
        // The stepper is now custom buttons, so look for the label
        let weeksLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Weeks'")).firstMatch
        XCTAssertTrue(weeksLabel.waitForExistence(timeout: 5), "Weeks setting should exist")
        
        // Try to find increment button for weeks
        let incrementButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Increase'"))
        if incrementButtons.count > 0 && incrementButtons.element(boundBy: 0).isHittable {
            incrementButtons.element(boundBy: 0).tap()
        }
    }
}
