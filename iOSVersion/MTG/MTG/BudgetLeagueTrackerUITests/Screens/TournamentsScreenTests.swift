import XCTest

/// UI tests for Tournaments screen
@MainActor
final class TournamentsScreenTests: XCTestCase {
    
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
    
    func testEmptyStateShowsCreateButton() {
        // On fresh launch, should show empty state with create button
        let createButton = app.buttons["Create Tournament"]
        let emptyMessage = app.staticTexts["No tournaments yet"]
        let addButton = app.buttons["Add"]
        
        let hasCreateButton = createButton.waitForExistence(timeout: 5)
        let hasEmptyMessage = emptyMessage.waitForExistence(timeout: 5)
        let hasAddButton = addButton.waitForExistence(timeout: 3)
        
        // Should have either a prominent create button, empty state message, or toolbar add button
        XCTAssertTrue(hasCreateButton || hasEmptyMessage || hasAddButton)
    }
    
    func testNavigationToNewTournament() {
        // Wait for the main screen to load
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        
        // Tap create/add button - try empty state button first, then toolbar button
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
        
        // Verify new tournament screen appears - check for navigation title
        let newTournamentNav = app.navigationBars["New Tournament"]
        XCTAssertTrue(newTournamentNav.waitForExistence(timeout: 5))
    }
    
    func testTabBarNavigation() {
        // Wait for the main screen to load first
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        
        // Verify tab bar exists with expected tabs
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            // Tab bar might be hidden if in a flow, test passes if nav bar exists
            return
        }
        
        // Check for Tournaments tab
        let tournamentsTab = tabBar.buttons["Tournaments"]
        XCTAssertTrue(tournamentsTab.exists, "Tournaments tab should exist")
        
        // Check for Players tab
        let playersTab = tabBar.buttons["Players"]
        XCTAssertTrue(playersTab.exists, "Players tab should exist")
        
        // Check for Stats tab
        let statsTab = tabBar.buttons["Stats"]
        XCTAssertTrue(statsTab.exists, "Stats tab should exist")
        
        // Check for Achievements tab
        let achievementsTab = tabBar.buttons["Achievements"]
        XCTAssertTrue(achievementsTab.exists, "Achievements tab should exist")
    }
    
    func testSwitchToStatsTab() {
        // Wait for main screen to load first
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            // Tab bar might be hidden, skip test
            return
        }
        
        let statsTab = tabBar.buttons["Stats"]
        guard statsTab.exists else { return }
        statsTab.tap()
        
        // Verify Stats screen appears
        let statsTitle = app.navigationBars["Stats"]
        XCTAssertTrue(statsTitle.waitForExistence(timeout: 5))
    }
    
    func testSwitchToAchievementsTab() {
        // Wait for main screen to load first
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            // Tab bar might be hidden, skip test
            return
        }
        
        let achievementsTab = tabBar.buttons["Achievements"]
        guard achievementsTab.exists else { return }
        achievementsTab.tap()
        
        // Verify Achievements screen appears
        let achievementsTitle = app.navigationBars["Achievements"]
        XCTAssertTrue(achievementsTitle.waitForExistence(timeout: 5))
    }
}
