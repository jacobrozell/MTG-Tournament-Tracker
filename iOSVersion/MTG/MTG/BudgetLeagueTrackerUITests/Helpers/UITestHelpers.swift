import XCTest

/// Helper methods for UI tests
extension XCUIApplication {
    
    // MARK: - Navigation Helpers
    
    /// Navigate to a specific tab
    func navigateToTab(_ tabName: String) {
        let tabBar = tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            tabBar.buttons[tabName].tap()
        }
    }
    
    /// Navigate to Tournaments tab
    func navigateToTournaments() {
        let tabBar = tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            let tournamentsTab = tabBar.buttons["Tournaments"]
            if tournamentsTab.exists {
                tournamentsTab.tap()
            }
        }
    }
    
    /// Navigate to Players tab
    func navigateToPlayers() {
        navigateToTab("Players")
    }
    
    /// Navigate to Stats tab
    func navigateToStats() {
        navigateToTab("Stats")
    }
    
    /// Navigate to Achievements tab
    func navigateToAchievements() {
        navigateToTab("Achievements")
    }
    
    // MARK: - Tournament Creation Helpers
    
    /// Creates a tournament with the given name and player names
    func createTournament(name: String, playerNames: [String] = []) {
        // Tap create button - try empty state button first, then toolbar button
        let createButton = buttons["Create Tournament"]
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
        } else {
            let addButton = buttons["Add"]
            if addButton.waitForExistence(timeout: 3) {
                addButton.tap()
            }
        }
        
        // Enter tournament name
        let nameField = textFields["Tournament Name"]
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText(name)
        }
        
        // Add players
        let addPlayerField = textFields["Player Name"]
        for playerName in playerNames {
            if addPlayerField.waitForExistence(timeout: 3) {
                addPlayerField.tap()
                addPlayerField.typeText(playerName)
                buttons["Add"].tap()
            }
        }
        
        // Create tournament
        buttons["Submit Create Tournament"].tap()
    }
    
    /// Confirms attendance with all players present
    func confirmAttendance() {
        let confirmButton = buttons["Confirm Attendance"]
        if confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        }
    }
    
    /// Generates pods and advances to next round
    func generateAndAdvanceRound() {
        let generateButton = buttons["Generate"]
        if generateButton.waitForExistence(timeout: 3) {
            generateButton.tap()
        }
        
        // Wait for pods to generate by checking for Next Round button
        let nextRoundButton = buttons["Next Round"]
        if nextRoundButton.waitForExistence(timeout: 3) {
            nextRoundButton.tap()
        }
    }
    
    // MARK: - Verification Helpers
    
    /// Verifies the current screen by checking the navigation bar title
    func verifyScreen(titled title: String) -> Bool {
        return navigationBars[title].waitForExistence(timeout: 5)
    }
    
    /// Verifies that a specific element exists
    func verifyElementExists(_ identifier: String) -> Bool {
        let element = descendants(matching: .any)[identifier]
        return element.waitForExistence(timeout: 5)
    }
    
    // MARK: - Form Helpers
    
    /// Enters text into a text field with the given identifier
    func enterText(_ text: String, inFieldWithIdentifier identifier: String) {
        let field = textFields[identifier]
        if field.waitForExistence(timeout: 5) {
            field.tap()
            field.typeText(text)
        }
    }
    
    /// Taps a button with the given title
    func tapButton(titled title: String) {
        let button = buttons[title]
        if button.waitForExistence(timeout: 5) {
            button.tap()
        }
    }
    
    /// Toggles a switch with the given identifier
    func toggleSwitch(identifier: String) {
        let toggle = switches[identifier]
        if toggle.waitForExistence(timeout: 5) {
            toggle.tap()
        }
    }
    
    // MARK: - Wait Helpers
    
    /// Waits for an element to appear and then disappear (for loading states)
    func waitForLoadingToComplete(timeout: TimeInterval = 10) {
        let loadingIndicator = activityIndicators.firstMatch
        if loadingIndicator.exists {
            _ = loadingIndicator.waitForExistence(timeout: timeout)
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    
    /// Clears existing text and enters new text
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Failed to get text value")
            return
        }
        
        tap()
        
        // Select all and delete
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        
        // Enter new text
        typeText(text)
    }
    
    /// Waits for element to be hittable (visible and enabled)
    func waitForHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
