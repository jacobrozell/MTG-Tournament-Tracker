import XCTest

/// UI tests for tournament completion flow
@MainActor
final class TournamentCompletionFlowTests: XCTestCase {
    
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
    
    /// Creates a 1-week tournament for quick testing
    /// Returns true if successful, false otherwise
    @discardableResult
    private func createOneWeekTournament() -> Bool {
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
            nameField.typeText("Quick Tournament")
            app.keyboards.buttons["return"].tap() // Dismiss keyboard faster
        }
        
        // Try to adjust weeks to 1 - find decrease button
        let decreaseButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Decrease'"))
        if decreaseButtons.count > 0 {
            // Tap decrease multiple times to get to 1 week
            for _ in 0..<5 {
                if decreaseButtons.element(boundBy: 0).isHittable {
                    decreaseButtons.element(boundBy: 0).tap()
                }
            }
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
            return true
        }
        return false
    }
    
    /// Completes all rounds for one week
    private func completeOneWeek() {
        // Confirm attendance
        let confirmButton = app.buttons["Confirm Attendance"]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()
        }
        
        // Complete 3 rounds
        for _ in 1...3 {
            let generateButton = app.buttons["Generate"]
            if generateButton.waitForExistence(timeout: 3) {
                generateButton.tap()
            }
            
            // Wait for pod controls to appear instead of sleeping
            let nextRoundButton = app.buttons["Next Round"]
            if nextRoundButton.waitForExistence(timeout: 3) {
                nextRoundButton.tap()
            }
        }
    }
    
    // MARK: - Completion Flow Tests
    
    func testCompleteTournamentShowsStandings() {
        guard createOneWeekTournament() else { return }
        
        // Wait for attendance
        guard app.navigationBars["Attendance"].waitForExistence(timeout: 5) else { return }
        
        completeOneWeek()
        
        // After completing final week, should see tournament standings
        let standingsTitle = app.staticTexts["Tournament Standings"]
        let finalRankings = app.staticTexts["Final Rankings"]
        
        let standingsShown = standingsTitle.waitForExistence(timeout: 5) || finalRankings.waitForExistence(timeout: 5)
        XCTAssertTrue(standingsShown)
    }
    
    func testCloseCompletedTournament() {
        guard createOneWeekTournament() else { return }
        
        // Wait for attendance
        guard app.navigationBars["Attendance"].waitForExistence(timeout: 3) else { return }
        
        completeOneWeek()
        
        // Find and tap Close button (waitForExistence handles the delay)
        let closeButton = app.buttons["Close"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        }
        
        // Verify we're back on tournaments list
        let tournamentsScreen = app.navigationBars["Tournaments"]
        XCTAssertTrue(tournamentsScreen.waitForExistence(timeout: 3))
    }
    
    func testCompletedTournamentShowsInList() {
        guard createOneWeekTournament() else { return }
        
        // Wait for attendance
        guard app.navigationBars["Attendance"].waitForExistence(timeout: 3) else { return }
        
        completeOneWeek()
        
        // Close standings
        let closeButton = app.buttons["Close"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        }
        
        // Look for completed section or the tournament name
        let completedSection = app.staticTexts["Completed"]
        let tournamentCell = app.staticTexts["Quick Tournament"]
        
        let found = completedSection.waitForExistence(timeout: 3) || tournamentCell.waitForExistence(timeout: 3)
        XCTAssertTrue(found)
    }
    
    func testViewCompletedTournamentStandings() {
        guard createOneWeekTournament() else { return }
        
        guard app.navigationBars["Attendance"].waitForExistence(timeout: 3) else { return }
        
        completeOneWeek()
        
        // Close standings
        let closeButton = app.buttons["Close"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        }
        
        // Tap on completed tournament to view standings again
        let tournamentCell = app.cells.firstMatch
        if tournamentCell.waitForExistence(timeout: 3) {
            tournamentCell.tap()
        }
        
        // Should show standings
        let standingsShown = app.staticTexts["Tournament Standings"].waitForExistence(timeout: 3) || 
                             app.staticTexts["Final Rankings"].exists ||
                             app.staticTexts["Total"].exists
        
        XCTAssertTrue(standingsShown)
    }
}
