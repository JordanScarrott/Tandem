import SwiftUI

public struct MainDashboardView: View {
    @State private var viewModel = DashboardViewModel()
    
    // Modal Sheets
    @State private var showingNewExpense: Bool = false
    @State private var showingAccounts: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingSearch: Bool = false
    
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
                                    showingSearch = true
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                                
                                Button {
                                    showingSearch = true
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(viewModel.selectedFilterCategoryId != nil ? Theme.accentBlue : Theme.primaryDark)
                                }
                                
                                Button {
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
                        if let catId = viewModel.selectedFilterCategoryId, let cat = viewModel.categoryFor(id: catId) {
                            HStack {
                                Text("Filtered by: **\(cat.name)**")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.accentBlue)
                                
                                Spacer()
                                
                                Button("Clear") {
                                    withAnimation {
                                        viewModel.selectedFilterCategoryId = nil
                                    }
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.accentBlue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.accentBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                        
                        // 1. Weekly Spending Big Card with Bar Chart
                        WeeklySpendingCard(
                            totalCents: viewModel.weeklyTotalCents,
                            currency: viewModel.currency,
                            chartData: viewModel.weeklyChartData
                        )
                        .padding(.horizontal, 16)
                        
                        // 2. Grouped Transaction List
                        TransactionGroupListView(
                            groupedExpenses: viewModel.groupedExpenses,
                            categories: viewModel.categories,
                            currency: viewModel.currency,
                            accountName: viewModel.activeAccount.name,
                            onDelete: { item in
                                viewModel.deleteExpense(item)
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingNewExpense = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.buttonDark)
                            .frame(width: 58, height: 58)
                            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
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
                    currency: viewModel.currency
                )
            }
            .task {
                await viewModel.refreshAll()
            }
        }
    }
}
