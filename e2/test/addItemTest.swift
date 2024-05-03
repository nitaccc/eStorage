import XCTest
@testable import AddItemView

class AddItemViewTests: XCTestCase {
    
    func testAddItemViewInitialization() {
        // Test initialization
        let addItemView = AddItemView(onAdd: { _ in })
        
        // Check default values
        XCTAssertTrue(addItemView.itemName.isEmpty)
        XCTAssertTrue(addItemView.expirationDateInput.isEmpty)
        XCTAssertFalse(addItemView.showingDatePicker)
        XCTAssertFalse(addItemView.isShowingCameraView)
    }
    
    func testCreateItemWithNoExpirationDate() {
        // Mock dependencies
        let mockSettingDefault = SettingDefault()
        mockSettingDefault.default_notify_time = Date()
        mockSettingDefault.default_enable_notify = true
        mockSettingDefault.default_prior_day = 3

        // Create the view with the mock dependencies
        let addItemView = AddItemView(onAdd: { _ in })
        addItemView.settingDefault = mockSettingDefault
        
        // Set item name
        addItemView.itemName = "Test Item"

        // Call createItem to generate an item without an expiration date
        let item = addItemView.createItem()

        // Validate that the item has the correct properties
        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.priorDay, 3)
        XCTAssertEqual(item.ifEnable, true)
    }
}
