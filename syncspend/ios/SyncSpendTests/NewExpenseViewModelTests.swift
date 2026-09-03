import XCTest
@testable import SyncSpend

final class MockExpenseLoggingService: @unchecked Sendable, ExpenseLoggingService {
    var loggedExpenses: [(amountCents: Int64, currency: String, categoryId: UInt64, paymentMethod: String, note: String, spentDate: Date)] = []
    var updatedExpenses: [(expenseId: UInt64, amountCents: Int64, currency: String, categoryId: UInt64, paymentMethod: String, note: String, spentDate: Date, splitMode: String)] = []
    var shouldFail: Bool = false

    func logExpense(
        amountCents: Int64,
        currency: String,
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date
    ) async throws {
        if shouldFail {
            throw NSError(domain: "MockExpenseLoggingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Log failed"])
        }
        loggedExpenses.append((amountCents, currency, categoryId, paymentMethod, note, spentDate))
    }

    func updateExpense(
        expenseId: UInt64,
        amountCents: Int64,
        currency: String,
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date,
        splitMode: String
    ) async throws {
        if shouldFail {
            throw NSError(domain: "MockExpenseLoggingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        }
        updatedExpenses.append((expenseId, amountCents, currency, categoryId, paymentMethod, note, spentDate, splitMode))
    }
}

final class NewExpenseViewModelTests: XCTestCase {
    private var testUserDefaults: UserDefaults!
    private var testSuiteName: String!
    private var mockService: MockExpenseLoggingService!

    override func setUp() {
        super.setUp()
        testSuiteName = "test_new_expense_vm_\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: testSuiteName)!
        mockService = MockExpenseLoggingService()
    }

    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: testSuiteName)
        testUserDefaults = nil
        mockService = nil
        super.tearDown()
    }

    private func makeTestCategory(id: UInt64, name: String) -> CategoryItem {
        CategoryItem(
            id: id,
            name: name,
            icon: "cart.fill",
            colorHex: "#FF9500",
            monthlyBudgetCents: 100000,
            isArchived: false,
            spaceId: nil
        )
    }

    func testInit_LoadsStoredPaymentMethodAndCategory() {
        testUserDefaults.set("Debit Card", forKey: NewExpenseViewModel.lastUsedPaymentMethodKey)
        testUserDefaults.set(NSNumber(value: 42), forKey: NewExpenseViewModel.lastUsedCategoryIdKey)

        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)

        XCTAssertEqual(viewModel.selectedPaymentMethod, "Debit Card")
        XCTAssertEqual(viewModel.selectedCategoryId, 42)
    }

    func testInit_DefaultsWhenStorageEmpty() {
        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)

        XCTAssertEqual(viewModel.selectedPaymentMethod, "Apple Pay")
        XCTAssertNil(viewModel.selectedCategoryId)
    }

    func testSaveExpense_PersistsPaymentMethodAndCategory() async {
        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)
        viewModel.amountInput = "49.99"
        viewModel.selectedCategoryId = 88
        viewModel.selectedPaymentMethod = "Debit Card"
        viewModel.title = "Grocery shopping"

        let categories = [makeTestCategory(id: 88, name: "Groceries")]
        let success = await viewModel.saveExpense(categories: categories)

        XCTAssertTrue(success)
        XCTAssertEqual(mockService.loggedExpenses.count, 1)

        let savedMethod = testUserDefaults.string(forKey: NewExpenseViewModel.lastUsedPaymentMethodKey)
        let savedCategoryNum = testUserDefaults.object(forKey: NewExpenseViewModel.lastUsedCategoryIdKey) as? NSNumber

        XCTAssertEqual(savedMethod, "Debit Card")
        XCTAssertEqual(savedCategoryNum?.uint64Value, 88)
    }

    func testReset_RestoresLastUsedDefaults() {
        testUserDefaults.set("Cash", forKey: NewExpenseViewModel.lastUsedPaymentMethodKey)
        testUserDefaults.set(NSNumber(value: 77), forKey: NewExpenseViewModel.lastUsedCategoryIdKey)

        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)
        XCTAssertEqual(viewModel.selectedPaymentMethod, "Cash")
        XCTAssertEqual(viewModel.selectedCategoryId, 77)

        // Modify in-memory
        viewModel.selectedPaymentMethod = "Bank Transfer"
        viewModel.selectedCategoryId = 999
        viewModel.amountInput = "100.00"
        viewModel.title = "Temporary"

        viewModel.reset()

        XCTAssertEqual(viewModel.selectedPaymentMethod, "Cash")
        XCTAssertEqual(viewModel.selectedCategoryId, 77)
        XCTAssertEqual(viewModel.amountInput, "")
        XCTAssertEqual(viewModel.title, "")
    }

    func testReconcileCategory_PreservesValidStoredCategory() {
        testUserDefaults.set(NSNumber(value: 20), forKey: NewExpenseViewModel.lastUsedCategoryIdKey)
        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)

        let categories = [
            makeTestCategory(id: 10, name: "Housing"),
            makeTestCategory(id: 20, name: "Groceries"),
            makeTestCategory(id: 30, name: "Dining")
        ]

        viewModel.reconcileSelectedCategory(with: categories)
        XCTAssertEqual(viewModel.selectedCategoryId, 20)
    }

    func testReconcileCategory_FallsBackWhenStoredCategoryMissing() {
        testUserDefaults.set(NSNumber(value: 999), forKey: NewExpenseViewModel.lastUsedCategoryIdKey)
        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)

        let categories = [
            makeTestCategory(id: 10, name: "Housing"),
            makeTestCategory(id: 20, name: "Groceries")
        ]

        viewModel.reconcileSelectedCategory(with: categories)
        XCTAssertEqual(viewModel.selectedCategoryId, 10)
    }

    func testReconcileCategory_HandlesEmptyCategories() {
        testUserDefaults.set(NSNumber(value: 999), forKey: NewExpenseViewModel.lastUsedCategoryIdKey)
        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)

        viewModel.reconcileSelectedCategory(with: [])
        XCTAssertNil(viewModel.selectedCategoryId)
    }

    func testPopulate_DoesNotOverwriteUserDefaults() {
        testUserDefaults.set("Debit Card", forKey: NewExpenseViewModel.lastUsedPaymentMethodKey)
        testUserDefaults.set(NSNumber(value: 10), forKey: NewExpenseViewModel.lastUsedCategoryIdKey)

        let viewModel = NewExpenseViewModel(service: mockService, userDefaults: testUserDefaults)

        let expense = ExpenseItem(
            id: 501,
            amountCents: 1500,
            currency: "ZAR",
            categoryId: 30,
            paymentMethod: "E-Wallet",
            note: "Coffee",
            spentAtMillis: Int64(Date().timeIntervalSince1970 * 1000.0)
        )

        viewModel.populate(with: expense)

        XCTAssertEqual(viewModel.selectedPaymentMethod, "E-Wallet")
        XCTAssertEqual(viewModel.selectedCategoryId, 30)
        XCTAssertEqual(viewModel.editingExpenseId, 501)

        // Verify UserDefaults was NOT modified
        XCTAssertEqual(testUserDefaults.string(forKey: NewExpenseViewModel.lastUsedPaymentMethodKey), "Debit Card")
        let storedCatNum = testUserDefaults.object(forKey: NewExpenseViewModel.lastUsedCategoryIdKey) as? NSNumber
        XCTAssertEqual(storedCatNum?.uint64Value, 10)
    }
}
