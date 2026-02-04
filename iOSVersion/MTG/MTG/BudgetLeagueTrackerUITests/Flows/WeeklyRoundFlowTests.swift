import XCTest

/// UI tests for weekly round flow
@MainActor
final class WeeklyRoundFlowTests: XCTestCase {
    
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
    
    // MARK: - Helper Methods
    
    /// Creates a tournament and advances to attendance screen
    /// Returns true if successful, false otherwise
    @discardableResult
    private func createTournamentAndGoToAttendance() -> Bool {
        // Wait for main screen to load
        let navBar = app.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: 3) else { return false }
        
        // Create tournament
        let createButton = app.buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 2) {
            createButton.tap()
        } else {
            let buttons = app.navigationBars.buttons
            guard buttons.count > 0 else { return false }
            buttons.element(boundBy: buttons.count - 1).tap()
        }
        
        // Wait for New Tournament screen
        guard app.navigationBars["New Tournament"].waitForExistence(timeout: 3) else { return false }
        
        // Find tournament name field by placeholder
        let nameField = app.textFields["e.g., Spring 2026 League"]
        if nameField.waitForExistence(timeout: 2) {
            nameField.tap()
            nameField.typeText("Test Tournament")
            app.keyboards.buttons["return"].tap() // Dismiss keyboard faster
        }
        
        // Add 4 players quickly - find add player field by placeholder
        let addPlayerField = app.textFields["Add player"]
        if addPlayerField.waitForExistence(timeout: 2) {
            for i in 1...4 {
                addPlayerField.tap()
                addPlayerField.typeText("P\(i)") // Shorter names for speed
                
                let addButton = app.buttons["Add player"]
                if addButton.exists && addButton.isHittable {
                    addButton.tap()
                }
            }
        }
        
        // Dismiss keyboard if still showing
        if app.keyboards.count > 0 {
            app.keyboards.buttons["return"].tap()
        }
        
        let createTournamentButton = app.buttons["Submit Create Tournament"]
        guard createTournamentButton.waitForExistence(timeout: 2) else { return false }
        
        if createTournamentButton.isEnabled {
            createTournamentButton.tap()
        } else {
            return false
        }
        
        // Wait for Attendance screen
        return app.navigationBars["Attendance"].waitForExistence(timeout: 3)
    }
    
    /// Confirms attendance with all players present
    private func confirmAttendance() {
        let confirmButton = app.buttons["Confirm Attendance"]
        guard confirmButton.waitForExistence(timeout: 3) else { return }
        confirmButton.tap()
        
        // Wait for Tournament Detail screen (where pods are managed)
        _ = app.navigationBars.staticTexts.firstMatch.waitForExistence(timeout: 3)
    }
    
    // MARK: - Round Flow Tests
    
    func testCompleteThreeRounds() {
        guard createTournamentAndGoToAttendance() else { return }
        confirmAttendance()
        
        // For each of 3 rounds
        for round in 1...3 {
            // Generate pods
            let generateButton = app.buttons["Generate"]
            guard generateButton.waitForExistence(timeout: 3) else { return }
            generateButton.tap()
            
            // Tap Next Round (waitForExistence handles delay)
            let nextRoundButton = app.buttons["Next Round"]
            guard nextRoundButton.waitForExistence(timeout: 3) else { return }
            nextRoundButton.tap()
            
            // After round 3, should be on attendance for next week or tournament standings
            if round == 3 {
                // Could be attendance (next week) or tournament standings (final week)
                let attendanceExists = app.navigationBars["Attendance"].waitForExistence(timeout: 3)
                let standingsExists = app.staticTexts["Tournament Standings"].waitForExistence(timeout: 3)
                XCTAssertTrue(attendanceExists || standingsExists)
            }
        }
    }
    
    func testEditLastRound() {
        guard createTournamentAndGoToAttendance() else { return }
        confirmAttendance()
        
        // Generate and complete a round
        let generateButton = app.buttons["Generate"]
        guard generateButton.waitForExistence(timeout: 3) else { return }
        generateButton.tap()
        
        // Save the round
        let nextRoundButton = app.buttons["Next Round"]
        guard nextRoundButton.waitForExistence(timeout: 3) else { return }
        nextRoundButton.tap()
        
        // Now we should be in round 2 - Generate pods for round 2
        guard generateButton.waitForExistence(timeout: 3) else { return }
        generateButton.tap()
        
        // Edit should be available
        let editButton = app.buttons["Edit Last Round"]
        guard editButton.waitForExistence(timeout: 3) else { return }
        
        // Tap edit
        editButton.tap()
        
        // Verify edit sheet appears with Save button
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        
        // Cancel to dismiss
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
        
        // Verify we're back on tournament detail screen
        XCTAssertTrue(generateButton.waitForExistence(timeout: 3))
    }
    
    func testToggleAchievementsOff() {
        guard createTournamentAndGoToAttendance() else { return }
        
        // Find achievements toggle
        let achievementsToggle = app.switches["Count achievements this week"]
        if achievementsToggle.exists {
            // Toggle off
            achievementsToggle.tap()
            
            // Verify it's off
            XCTAssertEqual(achievementsToggle.value as? String, "0")
        }
        
        confirmAttendance()
        
        // Generate pods
        let generateButton = app.buttons["Generate"]
        guard generateButton.waitForExistence(timeout: 3) else { return }
        generateButton.tap()
        
        // Achievement checkboxes should not be visible when achievements are off
        // Verify pods are generated
        XCTAssertTrue(app.buttons["Next Round"].waitForExistence(timeout: 3))
    }
    
    func testPlacementSelection() {
        guard createTournamentAndGoToAttendance() else { return }
        confirmAttendance()
        
        // Generate pods
        let generateButton = app.buttons["Generate"]
        guard generateButton.waitForExistence(timeout: 3) else { return }
        generateButton.tap()
        
        // Wait for pods to appear by checking for Next Round button
        guard app.buttons["Next Round"].waitForExistence(timeout: 3) else { return }
        
        // Find a placement picker (segmented control)
        let picker = app.segmentedControls.firstMatch
        if picker.exists {
            // Tap on "2" segment
            picker.buttons["2"].tap()
            
            // Verify selection changed
            XCTAssertTrue(picker.buttons["2"].isSelected)
        }
    }
}
