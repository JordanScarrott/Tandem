import XCTest
@testable import SyncSpend

final class SpacetimeWebSocketTests: XCTestCase {

    func testTransactionUpdateMessage_Parsing_InsertAndDeletes() {
        let mockPayload: [String: Any] = [
            "status": "committed",
            "caller_identity": "0x1a2b3c4d5e",
            "reducer_name": "log_expense",
            "timestamp": 1725280500000000 as Int64,
            "table_updates": [
                [
                    "table_name": "expense",
                    "table_id": 5,
                    "table_row_operations": [
                        [
                            "op": "insert",
                            "row": [
                                102 as UInt64,
                                "0x1a2b...",
                                45000 as Int64,
                                "ZAR",
                                1 as UInt64,
                                "Apple Pay",
                                "Groceries run",
                                1725280500000 as Int64,
                                [1725280500000000 as Int64],
                                [1725280500000000 as Int64],
                                [1, [] as [Any]],
                                [0, 42 as UInt64],
                                "EQUAL"
                            ]
                        ],
                        [
                            "op": "delete",
                            "row": [
                                101 as UInt64,
                                "0x1a2b..."
                            ]
                        ]
                    ]
                ]
            ]
        ]

        guard let message = TransactionUpdateMessage.parse(from: mockPayload) else {
            XCTFail("Failed to parse TransactionUpdateMessage")
            return
        }

        XCTAssertEqual(message.status, "committed")
        XCTAssertEqual(message.callerIdentity, "0x1a2b3c4d5e")
        XCTAssertEqual(message.reducerName, "log_expense")
        XCTAssertEqual(message.tableUpdates.count, 1)

        let expenseUpdate = message.tableUpdates[0]
        XCTAssertEqual(expenseUpdate.tableName, "expense")
        XCTAssertEqual(expenseUpdate.operations.count, 2)

        if case .insert(let row) = expenseUpdate.operations[0] {
            let item = ExpenseItem.parse(from: row)
            XCTAssertNotNil(item)
            XCTAssertEqual(item?.id, 102)
            XCTAssertEqual(item?.amountCents, 45000)
            XCTAssertEqual(item?.note, "Groceries run")
            XCTAssertEqual(item?.splitMode, "EQUAL")
            XCTAssertEqual(item?.spaceId, 42)
            XCTAssertEqual(item?.accountId, "acc-couple")
        } else {
            XCTFail("Expected first operation to be insert")
        }

        if case .delete(let row) = expenseUpdate.operations[1] {
            let id = (row.first as? NSNumber)?.uint64Value
            XCTAssertEqual(id, 101)
        } else {
            XCTFail("Expected second operation to be delete")
        }
    }

    func testCategoryItem_Parse_FromSATSRow() {
        let rawCategoryRow: [Any] = [
            1 as UInt64,
            "0x1a2b3c...",
            "Groceries",
            "cart.fill",
            "#10B981",
            [0, 600000 as Int64],
            false,
            [1, [] as [Any]]
        ]

        let cat = CategoryItem.parse(from: rawCategoryRow)
        XCTAssertNotNil(cat)
        XCTAssertEqual(cat?.id, 1)
        XCTAssertEqual(cat?.name, "Groceries")
        XCTAssertEqual(cat?.icon, "cart.fill")
        XCTAssertEqual(cat?.colorHex, "#10B981")
        XCTAssertEqual(cat?.monthlyBudgetCents, 600000)
        XCTAssertEqual(cat?.isArchived, false)
        XCTAssertNil(cat?.spaceId)
    }

    func testExpenseItem_Parse_FromSATSRow_PersonalAndDeleted() {
        let rawExpenseRow: [Any] = [
            99 as UInt64,
            "0x1a2b3c...",
            25000 as Int64,
            "ZAR",
            2 as UInt64,
            "Credit Card",
            "Dinner at restaurant",
            1725280000000 as Int64,
            [1725280000000000 as Int64],
            [1725280000000000 as Int64],
            [1, [] as [Any]],
            [1, [] as [Any]],
            "PERSONAL"
        ]

        let exp = ExpenseItem.parse(from: rawExpenseRow)
        XCTAssertNotNil(exp)
        XCTAssertEqual(exp?.id, 99)
        XCTAssertEqual(exp?.amountCents, 25000)
        XCTAssertEqual(exp?.note, "Dinner at restaurant")
        XCTAssertNil(exp?.deletedAtMillis)
        XCTAssertFalse(exp?.isDeleted ?? true)
        XCTAssertEqual(exp?.accountId, "acc-personal")
    }

    func testLiveExpenseInsert_UpdatesDashboardViewModelAndTelemetry() {
        let vm = DashboardViewModel()
        vm.categories = [
            CategoryItem(id: 1, name: "Food", icon: "cart.fill", colorHex: "#10B981", monthlyBudgetCents: 500000)
        ]
        vm.expenses = []

        let newExpense = ExpenseItem(
            id: 201,
            amountCents: 15000,
            currency: "ZAR",
            categoryId: 1,
            paymentMethod: "Apple Pay",
            note: "Supermarket lunch",
            spentAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )

        // Simulate live WebSocket transaction insert callback
        SpacetimeService.shared.onLiveExpenseInsert?(newExpense)

        XCTAssertTrue(vm.expenses.contains(where: { $0.id == 201 }))
        XCTAssertEqual(vm.todaySpentCents, 15000)
        XCTAssertEqual(vm.cycleTotalSpentCents, 15000)
    }

    func testLiveExpenseDelete_RemovesExpenseFromViewModel() {
        let vm = DashboardViewModel()
        let exp1 = ExpenseItem(
            id: 301,
            amountCents: 10000,
            currency: "ZAR",
            categoryId: 1,
            paymentMethod: "Cash",
            note: "Coffee",
            spentAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
        vm.expenses = [exp1]

        // Simulate live WebSocket transaction delete callback
        SpacetimeService.shared.onLiveExpenseDelete?(301)

        XCTAssertFalse(vm.expenses.contains(where: { $0.id == 301 }))
        XCTAssertEqual(vm.todaySpentCents, 0)
    }
}
