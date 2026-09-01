import SwiftUI

public struct MainDashboardView: View {
    @State private var viewModel = DashboardViewModel()
    
    // Modal Sheets
    @State private var showingNewExpense: Bool = false
    @State private var showingAccounts: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingSearch: Bool = false
    @State private var showingAddCategory: Bool = false
    @State private var selectedCategoryToEdit: CategoryItem? = nil
    @State private var selectedExpenseToEdit: ExpenseItem? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Main Scrollable Dashboard
                ScrollView {
                    VStack(spacing: 20) {
                        // Top Header Bar
                        HStack {
                            // Account Switcher Pill
                            AccountPickerPill(accountName: viewModel.activeAccount.name) {
                                showingAccounts = true
                            }
                            
                            Spacer()
                            
                            // Action Icons
                            HStack(spacing: 16) {
                                Button {
                                    Haptics.impact(.light)
                                    showingSearch = true
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                                
                                // Native iOS Filter Dropdown Menu
                                Menu {
                                    // 1. Period Submenu
                                    Menu {
                                        ForEach(FilterPeriod.allCases) { period in
                                            Button {
                                                Haptics.selection()
                                                viewModel.selectedPeriod = period
                                            } label: {
                                                if viewModel.selectedPeriod == period {
                                                    Label(period.title, systemImage: "checkmark")
                                                } else {
                                                    Text(period.title)
                                                }
                                            }
                                        }
                                    } label: {
                                        Label("Period", systemImage: "calendar")
                                    }
                                    
                                    // 2. Category Submenu
                                    Menu {
                                        Button {
                                            Haptics.selection()
                                            viewModel.selectedFilterCategoryId = nil
                                        } label: {
                                            if viewModel.selectedFilterCategoryId == nil {
                                                Label("All", systemImage: "checkmark")
                                            } else {
                                                Text("All")
                                            }
                                        }
                                        
                                        ForEach(viewModel.categories) { cat in
                                            Button {
                                                Haptics.selection()
                                                viewModel.selectedFilterCategoryId = cat.id
                                            } label: {
                                                if viewModel.selectedFilterCategoryId == cat.id {
                                                    Label(cat.name, systemImage: "checkmark")
                                                } else {
                                                    Text(cat.name)
                                                }
                                            }
                                        }
                                    } label: {
                                        Label("Category", systemImage: "tag")
                                    }
                                    
                                    // 3. Payment Method Submenu
                                    Menu {
                                        Button {
                                            Haptics.selection()
                                            viewModel.selectedPaymentMethod = nil
                                        } label: {
                                            if viewModel.selectedPaymentMethod == nil || viewModel.selectedPaymentMethod == "All" {
                                                Label("All", systemImage: "checkmark")
                                            } else {
                                                Text("All")
                                            }
                                        }
                                        
                                        ForEach(DashboardViewModel.defaultPaymentMethods, id: \.self) { method in
                                            Button {
                                                Haptics.selection()
                                                viewModel.selectedPaymentMethod = method
                                            } label: {
                                                if viewModel.selectedPaymentMethod == method {
                                                    Label(method, systemImage: "checkmark")
                                                } else {
                                                    Text(method)
                                                }
                                            }
                                        }
                                    } label: {
                                        Label("Payment Method", systemImage: "creditcard")
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(viewModel.isFilterActive ? Theme.accentBlue : Theme.primaryDark)
                                }
                                
                                Button {
                                    Haptics.impact(.light)
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Active Filter Notice Pill
                        if viewModel.isFilterActive {
                            HStack {
                                Text("Filtered by: **\(viewModel.activeFilterDescription)**")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.accentBlue)
                                
                                Spacer()
                                
                                Button("Clear") {
                                    Haptics.selection()
                                    withAnimation {
                                        viewModel.clearAllFilters()
                                    }
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.accentBlue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.accentBlue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                        
                        // 1. Period Spending Big Card with Bar Chart
                        WeeklySpendingCard(
                            title: viewModel.periodTitle,
                            totalCents: viewModel.periodTotalCents,
                            currency: viewModel.currency,
                            chartData: viewModel.chartData
                        )
                        .padding(.horizontal, 16)
                        
                        // 2. Category Envelopes Section (Payday Cycle Tracking)
                        CategoryEnvelopesDashboardSection(
                            cycle: viewModel.currentPaydayCycle,
                            envelopeStatuses: viewModel.envelopeStatuses,
                            totalSpentCents: viewModel.cycleTotalSpentCents,
                            totalBudgetCents: viewModel.cycleTotalBudgetCents,
                            currency: viewModel.currency,
                            selectedCategoryId: $viewModel.selectedFilterCategoryId,
                            onAddEnvelope: {
                                showingAddCategory = true
                            },
                            onEditEnvelope: { cat in
                                selectedCategoryToEdit = cat
                            }
                        )
                        .padding(.horizontal, 16)
                        
                        // 3. Grouped Transaction List
                        TransactionGroupListView(
                            groupedExpenses: viewModel.groupedExpenses,
                            categories: viewModel.categories,
                            currency: viewModel.currency,
                            accountName: viewModel.activeAccount.name,
                            onDelete: { item in
                                viewModel.deleteExpense(item)
                            },
                            onEdit: { item in
                                selectedExpenseToEdit = item
                            },
                            onLogExpense: {
                                showingNewExpense = true
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90) // Padding for FAB
                    }
                }
                .background(Theme.appBackground)
                .refreshable {
                    await viewModel.refreshAll()
                }
                
                // Floating Undo Bar
                if viewModel.showingUndoBar, let deleted = viewModel.lastDeletedExpense {
                    UndoFloatingBar(
                        expense: deleted,
                        currency: viewModel.currency,
                        onUndo: {
                            viewModel.undoDelete(deleted)
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
                
                // Floating Action Button (FAB)
                Button {
                    Haptics.impact(.medium)
                    showingNewExpense = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.buttonDark)
                            .frame(width: 58, height: 58)
                            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.buttonForeground)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 24)
                .zIndex(20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewExpense) {
                NewExpenseSheet(
                    categories: viewModel.categories,
                    currency: viewModel.currency,
                    accountId: viewModel.activeAccountId,
                    smartSuggestionsEnabled: viewModel.smartSuggestionsEnabled,
                    onExpenseSaved: {
                        Task { await viewModel.loadExpenses() }
                    }
                )
            }
            .sheet(item: $selectedExpenseToEdit) { expense in
                NewExpenseSheet(
                    categories: viewModel.categories,
                    currency: viewModel.currency,
                    accountId: viewModel.activeAccountId,
                    smartSuggestionsEnabled: viewModel.smartSuggestionsEnabled,
                    expenseToEdit: expense,
                    onExpenseSaved: {
                        Task { await viewModel.loadExpenses() }
                    }
                )
            }
            .sheet(isPresented: $showingAccounts) {
                AccountsSheet(
                    accounts: $viewModel.accounts,
                    activeAccountId: $viewModel.activeAccountId,
                    currency: viewModel.currency,
                    onAddAccount: { name in
                        viewModel.addAccount(name: name)
                    },
                    onDeleteAccount: { id in
                        viewModel.deleteAccount(id: id)
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    currency: $viewModel.currency,
                    startWeekOn: $viewModel.startWeekOn,
                    smartSuggestionsEnabled: $viewModel.smartSuggestionsEnabled,
                    accountName: viewModel.activeAccount.name
                )
            }
            .sheet(isPresented: $showingSearch) {
                SearchFilterSheet(
                    searchQuery: $viewModel.searchQuery,
                    selectedCategoryId: $viewModel.selectedFilterCategoryId,
                    categories: viewModel.categories,
                    expenses: viewModel.accountExpenses,
                    currency: viewModel.currency,
                    onSelectExpense: { item in
                        selectedExpenseToEdit = item
                    }
                )
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEnvelopeSheet(mode: .create, currency: viewModel.currency) {
                    Task {
                        await viewModel.loadCategories()
                    }
                }
            }
            .sheet(item: $selectedCategoryToEdit) { cat in
                CategoryEnvelopeSheet(mode: .edit(cat), currency: viewModel.currency) {
                    Task {
                        await viewModel.loadCategories()
                    }
                }
            }
            .sheet(isPresented: $viewModel.needsOnboarding) {
                OnboardingPaydaySheet {
                    viewModel.needsOnboarding = false
                    Task {
                        await viewModel.refreshAll()
                    }
                }
            }
            .task {
                await viewModel.refreshAll()
            }
        }
    }
}


