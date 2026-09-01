import React, { useState, useMemo, useEffect, useRef } from 'react';
import {
  ChevronDown,
  ChevronUp,
  Search,
  SlidersHorizontal,
  Settings,
  Plus,
  Heart,
  X,
  Check,
  Minus,
  Menu,
  ChevronRight,
  ChevronLeft,
  Calendar as CalendarIcon,
  DollarSign,
  Sparkles,
  Command,
  FileText,
  Trash2,
  Edit2,
  CreditCard,
  Wallet,
  Utensils,
  ShoppingBag,
  Plane,
  Wrench,
  Film,
  Activity,
  Car,
  Smartphone,
  CheckCircle2,
  ArrowUpRight,
  RefreshCw,
  Info,
  Layers,
  User,
  Briefcase,
  Lock,
  Globe,
  Mic,
  Smile,
  Delete
} from 'lucide-react';

// --- Constants & Initial Data ---
const CATEGORIES = [
  { id: 'none', name: 'None', icon: Activity, color: 'bg-neutral-100 text-neutral-800' },
  { id: 'food', name: 'Food & Drinks', icon: Utensils, color: 'bg-amber-100 text-amber-900' },
  { id: 'shopping', name: 'Shopping', icon: ShoppingBag, color: 'bg-blue-100 text-blue-900' },
  { id: 'travel', name: 'Travel', icon: Plane, color: 'bg-sky-100 text-sky-900' },
  { id: 'services', name: 'Services', icon: Wrench, color: 'bg-orange-100 text-orange-900' },
  { id: 'entertainment', name: 'Entertainment', icon: Film, color: 'bg-purple-100 text-purple-900' },
  { id: 'health', name: 'Health', icon: Heart, color: 'bg-rose-100 text-rose-900' },
  { id: 'transportation', name: 'Transportation', icon: Car, color: 'bg-emerald-100 text-emerald-900' },
];

const PAYMENT_METHODS = [
  { id: 'none', name: 'None' },
  { id: 'apple-pay', name: 'Apple Pay' },
  { id: 'credit-card', name: 'Credit Card' },
  { id: 'debit-card', name: 'Debit Card' },
  { id: 'cash', name: 'Cash' },
  { id: 'bank-transfer', name: 'EFT / Bank Transfer' }
];

const CURRENCIES = [
  { code: 'ZAR', symbol: 'R', name: 'South African Rand (ZAR)' },
  { code: 'USD', symbol: '$', name: 'US Dollar ($)' },
  { code: 'EUR', symbol: '€', name: 'Euro (€)' },
  { code: 'GBP', symbol: '£', name: 'British Pound (£)' },
  { code: 'JPY', symbol: '¥', name: 'Japanese Yen (¥)' },
  { code: 'CAD', symbol: '$', name: 'Canadian Dollar ($)' },
  { code: 'AUD', symbol: '$', name: 'Australian Dollar ($)' }
];

// Initial mock transactions corresponding directly to the screenshots (August 2026)
const INITIAL_EXPENSES = [
  {
    id: 'exp-1',
    accountId: 'acc-personal',
    title: 'Creatine',
    amount: 325.00,
    category: 'health',
    paymentMethod: 'apple-pay',
    date: '2026-08-28' // Friday
  },
  {
    id: 'exp-2',
    accountId: 'acc-personal',
    title: 'Whey',
    amount: 1150.00,
    category: 'health',
    paymentMethod: 'apple-pay',
    date: '2026-08-28' // Friday
  }
];

const INITIAL_ACCOUNTS = [
  { id: 'acc-personal', name: 'Personal', icon: 'user', balance: 1475.00, isDefault: true },
  { id: 'acc-business', name: 'Business', icon: 'briefcase', balance: 8320.00, isDefault: false },
  { id: 'acc-savings', name: 'Savings & Trip', icon: 'plane', balance: 24500.00, isDefault: false },
];

export default function App() {
  // State
  const [accounts, setAccounts] = useState(INITIAL_ACCOUNTS);
  const [activeAccountId, setActiveAccountId] = useState('acc-personal');
  const [expenses, setExpenses] = useState(INITIAL_EXPENSES);
  const [currency, setCurrency] = useState(CURRENCIES[0]); // ZAR
  const [startWeekOn, setStartWeekOn] = useState('Sunday');
  const [smartSuggestions, setSmartSuggestions] = useState(true);

  // Modals & Navigation Sheets
  const [isAccountsOpen, setIsAccountsOpen] = useState(false);
  const [isAccountsEditing, setIsAccountsEditing] = useState(false);
  const [isNewExpenseOpen, setIsNewExpenseOpen] = useState(false);
  const [isCategoryPickerOpen, setIsCategoryPickerOpen] = useState(false);
  const [isPaymentPickerOpen, setIsPaymentPickerOpen] = useState(false);
  const [isDatePickerOpen, setIsDatePickerOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isProModalOpen, setIsProModalOpen] = useState(false);
  const [isAddAccountModalOpen, setIsAddAccountModalOpen] = useState(false);
  const [showVirtualKeyboard, setShowVirtualKeyboard] = useState(false);

  // Search & Filter State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilterCategory, setSelectedFilterCategory] = useState('all');

  // Form State for New Expense
  const [newExpenseTitle, setNewExpenseTitle] = useState('');
  const [newExpenseAmount, setNewExpenseAmount] = useState('');
  const [newExpenseCategory, setNewExpenseCategory] = useState('none');
  const [newExpensePayment, setNewExpensePayment] = useState('none');
  const [newExpenseDate, setNewExpenseDate] = useState('2026-08-29'); // Matches Aug 29 2026 in screenshot

  // Calendar Picker Internal State (Month / Year browsing)
  const [calendarMonth, setCalendarMonth] = useState(7); // 0-indexed: 7 is August
  const [calendarYear, setCalendarYear] = useState(2026);

  // New Account Form State
  const [newAccountName, setNewAccountName] = useState('');

  // Active account reference
  const currentAccount = accounts.find(a => a.id === activeAccountId) || accounts[0];

  // Helper formatting for currency
  const formatMoney = (val) => {
    const num = Number(val || 0);
    // Format: "R 1 475,00"
    const parts = num.toFixed(2).split('.');
    const integerPart = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    return `${currency.symbol} ${integerPart},${parts[1]}`;
  };

  // Helper formatting for date display e.g. "28 Aug 2026"
  const formatDateDisplay = (dateString) => {
    if (!dateString) return '';
    const dateObj = new Date(dateString + 'T00:00:00');
    const day = dateObj.getDate();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${day} ${months[dateObj.getMonth()]} ${dateObj.getFullYear()}`;
  };

  // Helper for day name
  const getDayName = (dateString) => {
    const dateObj = new Date(dateString + 'T00:00:00');
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dateObj.getDay()];
  };

  // Filtered expenses for active account
  const accountExpenses = useMemo(() => {
    return expenses.filter(e => e.accountId === activeAccountId);
  }, [expenses, activeAccountId]);

  // Total spent this week (calculated from current active account expenses)
  const weeklyTotal = useMemo(() => {
    return accountExpenses.reduce((acc, curr) => acc + curr.amount, 0);
  }, [accountExpenses]);

  // Weekly breakdown by day for the chart
  // Days order depending on `startWeekOn`
  const weekDays = useMemo(() => {
    if (startWeekOn === 'Sunday') {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }, [startWeekOn]);

  const weeklyChartData = useMemo(() => {
    const dayTotals = { Sun: 0, Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0 };
    accountExpenses.forEach(exp => {
      const dateObj = new Date(exp.date + 'T00:00:00');
      const dayShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][dateObj.getDay()];
      if (dayTotals[dayShort] !== undefined) {
        dayTotals[dayShort] += exp.amount;
      }
    });
    return weekDays.map(day => ({
      day,
      amount: dayTotals[day] || 0
    }));
  }, [accountExpenses, weekDays]);

  // Grouped expenses by day for list rendering
  const groupedExpenses = useMemo(() => {
    let filtered = accountExpenses;
    if (searchQuery.trim()) {
      filtered = filtered.filter(e =>
        e.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        e.amount.toString().includes(searchQuery)
      );
    }
    if (selectedFilterCategory !== 'all') {
      filtered = filtered.filter(e => e.category === selectedFilterCategory);
    }

    const groups = {};
    filtered.forEach(exp => {
      const dayName = getDayName(exp.date);
      if (!groups[dayName]) groups[dayName] = [];
      groups[dayName].push(exp);
    });
    return groups;
  }, [accountExpenses, searchQuery, selectedFilterCategory]);

  // Calendar Day Generation
  const calendarDays = useMemo(() => {
    const firstDayIndex = new Date(calendarYear, calendarMonth, 1).getDay();
    const daysInMonth = new Date(calendarYear, calendarMonth + 1, 0).getDate();
    const daysArray = [];

    // Blank cells before day 1
    for (let i = 0; i < firstDayIndex; i++) {
      daysArray.push(null);
    }

    // Month days
    for (let d = 1; d <= daysInMonth; d++) {
      const dateString = `${calendarYear}-${String(calendarMonth + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      daysArray.push({
        dayNumber: d,
        dateString
      });
    }

    return daysArray;
  }, [calendarMonth, calendarYear]);

  // Reset/Open New Expense Modal
  const handleOpenNewExpense = () => {
    setNewExpenseTitle('');
    setNewExpenseAmount('');
    setNewExpenseCategory('none');
    setNewExpensePayment('none');
    setNewExpenseDate('2026-08-29');
    setIsNewExpenseOpen(true);
    setShowVirtualKeyboard(false);
  };

  // Save New Expense
  const handleSaveExpense = () => {
    const parsedAmount = parseFloat(newExpenseAmount);
    if (!newExpenseTitle.trim() || isNaN(parsedAmount) || parsedAmount <= 0) {
      return;
    }

    const newExp = {
      id: `exp-${Date.now()}`,
      accountId: activeAccountId,
      title: newExpenseTitle.trim(),
      amount: parsedAmount,
      category: newExpenseCategory,
      paymentMethod: newExpensePayment,
      date: newExpenseDate
    };

    setExpenses([newExp, ...expenses]);
    setIsNewExpenseOpen(false);
    setShowVirtualKeyboard(false);
  };

  // Delete Expense
  const handleDeleteExpense = (id, e) => {
    e.stopPropagation();
    setExpenses(expenses.filter(item => item.id !== id));
  };

  // Handle Account Creation
  const handleAddAccount = () => {
    if (!newAccountName.trim()) return;
    const newAcc = {
      id: `acc-${Date.now()}`,
      name: newAccountName.trim(),
      icon: 'briefcase',
      balance: 0.00,
      isDefault: false
    };
    setAccounts([...accounts, newAcc]);
    setActiveAccountId(newAcc.id);
    setNewAccountName('');
    setIsAddAccountModalOpen(false);
  };

  // Delete Account
  const handleDeleteAccount = (accId) => {
    if (accounts.length <= 1) return;
    const remaining = accounts.filter(a => a.id !== accId);
    setAccounts(remaining);
    if (activeAccountId === accId) {
      setActiveAccountId(remaining[0].id);
    }
  };

  const selectedCategoryObj = CATEGORIES.find(c => c.id === newExpenseCategory) || CATEGORIES[0];
  const selectedPaymentObj = PAYMENT_METHODS.find(p => p.id === newExpensePayment) || PAYMENT_METHODS[0];

  return (
    <div className="min-h-screen bg-[#E5E5EA] text-[#1C1C1E] flex justify-center items-start sm:py-8 font-sans select-none antialiased">
      {/* iPhone Device Wrapper */}
      <div className="relative w-full max-w-[430px] min-h-screen sm:min-h-[900px] sm:h-[915px] sm:rounded-[52px] bg-[#F2F2F7] shadow-2xl overflow-hidden flex flex-col border sm:border-[#D1D1D6]/70">

        {/* Top iOS Dynamic Island & Status Bar */}
        <div className="pt-3 px-7 pb-2 flex items-center justify-between z-30 shrink-0 select-none">
          <span className="text-[15px] font-semibold tracking-tight text-black">15:18</span>

          {/* Dynamic Island pill */}
          <div className="w-28 h-7 bg-black rounded-full mx-auto shadow-inner flex items-center justify-end px-2.5">
            <div className="w-2.5 h-2.5 rounded-full bg-[#1c1c1e] ring-1 ring-neutral-800" />
          </div>

          <div className="flex items-center gap-1.5 text-black">
            {/* Cellular Bars */}
            <svg className="w-4 h-3.5 fill-current" viewBox="0 0 17 12">
              <rect x="0" y="8.5" width="2.5" height="3.5" rx="0.5" />
              <rect x="4" y="6" width="2.5" height="6" rx="0.5" />
              <rect x="8" y="3.5" width="2.5" height="8.5" rx="0.5" />
              <rect x="12" y="0.5" width="2.5" height="11.5" rx="0.5" />
            </svg>
            {/* Wifi Icon */}
            <svg className="w-4 h-3.5 fill-current" viewBox="0 0 16 12">
              <path d="M8 9.5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3zm-4.2-2.8a5.9 5.9 0 0 1 8.4 0 .8.8 0 0 0 1.1-1.1 7.5 7.5 0 0 0-10.6 0 .8.8 0 1 0 1.1 1.1zm-2.8-2.8a9.9 9.9 0 0 1 14 0 .8.8 0 0 0 1.1-1.1 11.5 11.5 0 0 0-16.2 0 .8.8 0 0 0 1.1 1.1z" />
            </svg>
            {/* Battery */}
            <div className="w-5 h-2.5 border border-black/80 rounded-[3px] p-0.5 flex items-center relative">
              <div className="h-full w-full bg-black rounded-[1px]"></div>
              <div className="w-0.5 h-1 bg-black/80 absolute -right-1 rounded-r-sm top-0.5"></div>
            </div>
          </div>
        </div>

        {/* Top Header Bar */}
        <div className="px-5 pt-1.5 pb-3 flex items-center justify-between z-20">
          {/* Account Selector Pill */}
          <button
            onClick={() => {
              setIsAccountsEditing(false);
              setIsAccountsOpen(true);
            }}
            className="flex items-center gap-1.5 px-3.5 py-1.5 bg-white/70 backdrop-blur-md rounded-full text-[15px] font-semibold text-black hover:bg-white active:scale-95 transition-all shadow-sm border border-black/5"
          >
            <span>{currentAccount.name}</span>
            <ChevronDown className="w-4 h-4 text-neutral-600 stroke-[2.5]" />
          </button>

          {/* Action Icons */}
          <div className="flex items-center gap-4 text-neutral-800">
            <button
              onClick={() => setIsSearchOpen(true)}
              className="p-1 hover:text-black active:scale-90 transition-transform"
              title="Search expenses"
            >
              <Search className="w-5 h-5 stroke-[2.2]" />
            </button>
            <button
              onClick={() => {
                setSelectedFilterCategory(prev => (prev === 'all' ? 'health' : 'all'));
              }}
              className={`p-1 hover:text-black active:scale-90 transition-transform ${selectedFilterCategory !== 'all' ? 'text-blue-600' : ''}`}
              title="Filter categories"
            >
              <SlidersHorizontal className="w-5 h-5 stroke-[2.2]" />
            </button>
            <button
              onClick={() => setIsSettingsOpen(true)}
              className="p-1 hover:text-black active:scale-90 transition-transform"
              title="Settings"
            >
              <Settings className="w-5 h-5 stroke-[2.2]" />
            </button>
          </div>
        </div>

        {/* Main Content Area (Scrollable iOS View) */}
        <div className="flex-1 overflow-y-auto px-4 pb-28 pt-1 space-y-5 scrollbar-none">
          {/* Filter Notice pill if applied */}
          {selectedFilterCategory !== 'all' && (
            <div className="flex items-center justify-between px-4 py-2 bg-blue-50 border border-blue-200/80 rounded-2xl text-xs text-blue-800">
              <span>Filtered by: <strong>{CATEGORIES.find(c => c.id === selectedFilterCategory)?.name}</strong></span>
              <button
                onClick={() => setSelectedFilterCategory('all')}
                className="font-medium underline hover:text-blue-950"
              >
                Clear
              </button>
            </div>
          )}

          {/* Weekly Spending Big Card */}
          <div className="bg-white rounded-[28px] p-6 shadow-[0_4px_24px_rgba(0,0,0,0.03)] border border-neutral-100 relative">
            <p className="text-[14px] font-normal text-neutral-400">Spent this week</p>
            <h1 className="text-[34px] font-bold text-black tracking-tight mt-0.5 mb-6">
              {formatMoney(weeklyTotal)}
            </h1>

            {/* Custom iOS Bar Chart */}
            <div className="relative pt-4 pb-2">
              {/* Horizontal Guidelines */}
              <div className="absolute inset-0 flex flex-col justify-between pointer-events-none pb-7">
                <div className="flex items-center justify-between w-full">
                  <div className="w-full border-b border-neutral-200/60" />
                  <span className="text-[11px] font-medium text-neutral-400 pl-2 w-10 text-right">1 500</span>
                </div>
                <div className="flex items-center justify-between w-full">
                  <div className="w-full border-b border-neutral-200/60" />
                  <span className="text-[11px] font-medium text-neutral-400 pl-2 w-10 text-right">1 000</span>
                </div>
                <div className="flex items-center justify-between w-full">
                  <div className="w-full border-b border-neutral-200/60" />
                  <span className="text-[11px] font-medium text-neutral-400 pl-2 w-10 text-right">500</span>
                </div>
                <div className="flex items-center justify-between w-full">
                  <div className="w-full border-b border-neutral-200/60" />
                  <span className="text-[11px] font-medium text-neutral-400 pl-2 w-10 text-right">0</span>
                </div>
              </div>

              {/* Bars Container */}
              <div className="h-44 flex items-end justify-between pr-10 pl-2 pt-2 z-10 relative">
                {weeklyChartData.map((item) => {
                  const maxChartVal = 1600;
                  const heightPercent = Math.min(100, Math.max(0, (item.amount / maxChartVal) * 100));
                  const isHighSpend = item.amount > 0;

                  return (
                    <div key={item.day} className="flex flex-col items-center h-full justify-end group">
                      {/* Bar Column */}
                      <div className="w-6 sm:w-7 h-full flex items-end justify-center">
                        <div
                          style={{ height: `${heightPercent}%` }}
                          className={`w-full rounded-t-full rounded-b-md transition-all duration-500 ease-out cursor-pointer ${
                            isHighSpend ? 'bg-black shadow-sm' : 'bg-transparent'
                          }`}
                          title={`${item.day}: ${formatMoney(item.amount)}`}
                        >
                          {/* Tooltip on tap/hover */}
                          {item.amount > 0 && (
                            <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-8 bg-neutral-900 text-white text-[10px] font-semibold py-1 px-2 rounded-md shadow-lg pointer-events-none -translate-x-1/4 whitespace-nowrap">
                              {formatMoney(item.amount)}
                            </div>
                          )}
                        </div>
                      </div>
                      {/* X-axis Day Label */}
                      <span className="text-[11px] font-medium text-neutral-400 mt-3">{item.day}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Grouped Expenses List */}
          <div className="space-y-4">
            {Object.keys(groupedExpenses).length === 0 ? (
              <div className="text-center py-12 px-4">
                <div className="w-14 h-14 rounded-full bg-neutral-200/70 flex items-center justify-center mx-auto mb-3 text-neutral-400">
                  <CreditCard className="w-7 h-7" />
                </div>
                <p className="text-[16px] font-semibold text-neutral-700">No expenses found</p>
                <p className="text-[13px] text-neutral-400 mt-1 max-w-xs mx-auto">
                  Tap the black plus button below to log your first purchase in {currentAccount.name}.
                </p>
              </div>
            ) : (
              Object.entries(groupedExpenses).map(([dayTitle, dayItems]) => (
                <div key={dayTitle} className="space-y-2">
                  <h2 className="text-[15px] font-semibold text-neutral-500 px-2">{dayTitle}</h2>
                  <div className="bg-white rounded-[24px] overflow-hidden shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-neutral-100 divide-y divide-neutral-100">
                    {dayItems.map((expense) => {
                      const categoryObj = CATEGORIES.find(c => c.id === expense.category) || CATEGORIES[0];
                      const IconComponent = categoryObj.icon;

                      return (
                        <div
                          key={expense.id}
                          className="flex items-center justify-between p-4 hover:bg-neutral-50/80 transition-colors group"
                        >
                          <div className="flex items-center gap-3.5">
                            {/* Category Icon Badge */}
                            <div className="w-11 h-11 rounded-[14px] bg-[#F2F2F7] flex items-center justify-center text-black shadow-inner">
                              <IconComponent className="w-5 h-5 fill-current" />
                            </div>
                            <div>
                              <p className="text-[16px] font-semibold text-black tracking-tight">
                                {expense.title}
                              </p>
                              <p className="text-[12px] font-normal text-neutral-400">
                                {formatDateDisplay(expense.date)}
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-3">
                            <span className="text-[16px] font-semibold text-black">
                              {formatMoney(expense.amount)}
                            </span>
                            <button
                              onClick={(e) => handleDeleteExpense(expense.id, e)}
                              className="opacity-0 group-hover:opacity-100 text-neutral-300 hover:text-red-500 transition-opacity p-1"
                              title="Delete transaction"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Floating Action Button (FAB) */}
        <div className="absolute bottom-6 right-6 z-20">
          <button
            onClick={handleOpenNewExpense}
            className="w-14 h-14 rounded-full bg-black text-white flex items-center justify-center shadow-[0_8px_24px_rgba(0,0,0,0.3)] hover:scale-105 active:scale-95 transition-all"
            aria-label="Add New Expense"
          >
            <Plus className="w-7 h-7 stroke-[2.5]" />
          </button>
        </div>

        {/* ------------------------------------------------------------- */}
        {/* MODAL 1: NEW EXPENSE SHEET */}
        {/* ------------------------------------------------------------- */}
        {isNewExpenseOpen && (
          <div className="absolute inset-0 z-40 bg-black/35 backdrop-blur-sm flex flex-col justify-end transition-all">
            <div className="bg-[#F2F2F7] rounded-t-[34px] shadow-2xl overflow-hidden flex flex-col animate-in slide-in-from-bottom duration-300 max-h-[92%]">
              {/* Modal Top Nav */}
              <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-neutral-200/50">
                <button
                  onClick={() => setIsNewExpenseOpen(false)}
                  className="px-4 py-1.5 bg-white rounded-full text-[14px] font-medium text-neutral-800 shadow-sm border border-neutral-200/60 active:scale-95 transition-transform"
                >
                  Cancel
                </button>
                <h3 className="text-[16px] font-bold text-black tracking-tight">New Expense</h3>
                <button
                  onClick={handleSaveExpense}
                  disabled={!newExpenseTitle.trim() || !newExpenseAmount}
                  className={`px-4 py-1.5 rounded-full text-[14px] font-semibold transition-all shadow-sm ${
                    newExpenseTitle.trim() && newExpenseAmount
                      ? 'bg-black text-white active:scale-95'
                      : 'bg-neutral-200/80 text-neutral-400 cursor-not-allowed'
                  }`}
                >
                  Save
                </button>
              </div>

              {/* Form Inset Group */}
              <div className="p-4 space-y-4 overflow-y-auto">
                <div className="bg-white rounded-[22px] overflow-hidden shadow-sm border border-neutral-200/60 divide-y divide-neutral-200/70">
                  {/* Title Row */}
                  <div className="px-4 py-3.5 flex items-center">
                    <input
                      type="text"
                      placeholder="Title"
                      value={newExpenseTitle}
                      onChange={(e) => setNewExpenseTitle(e.target.value)}
                      onFocus={() => setShowVirtualKeyboard(true)}
                      className="w-full text-[16px] font-normal text-black placeholder-neutral-400 bg-transparent focus:outline-none"
                      autoFocus
                    />
                  </div>

                  {/* Amount Row */}
                  <div className="px-4 py-3.5 flex items-center justify-between">
                    <span className="text-[15px] font-normal text-neutral-800">Amount</span>
                    <div className="flex items-center gap-1">
                      <span className="text-[14px] text-neutral-400">{currency.code}</span>
                      <input
                        type="number"
                        step="0.01"
                        placeholder="0.00"
                        value={newExpenseAmount}
                        onChange={(e) => setNewExpenseAmount(e.target.value)}
                        className="text-right text-[15px] font-medium text-neutral-900 placeholder-neutral-400 bg-transparent focus:outline-none w-28"
                      />
                    </div>
                  </div>

                  {/* Category Row */}
                  <div
                    onClick={() => setIsCategoryPickerOpen(true)}
                    className="px-4 py-3.5 flex items-center justify-between cursor-pointer hover:bg-neutral-50 active:bg-neutral-100 transition-colors"
                  >
                    <span className="text-[15px] font-normal text-neutral-800">Category</span>
                    <div className="flex items-center gap-1.5 text-neutral-600">
                      <span className="text-[15px] font-normal">{selectedCategoryObj.name}</span>
                      <div className="flex flex-col -space-y-1 text-neutral-400">
                        <ChevronUp className="w-3 h-3" />
                        <ChevronDown className="w-3 h-3" />
                      </div>
                    </div>
                  </div>

                  {/* Payment Row */}
                  <div
                    onClick={() => setIsPaymentPickerOpen(true)}
                    className="px-4 py-3.5 flex items-center justify-between cursor-pointer hover:bg-neutral-50 active:bg-neutral-100 transition-colors"
                  >
                    <span className="text-[15px] font-normal text-neutral-800">Payment</span>
                    <div className="flex items-center gap-1.5 text-neutral-600">
                      <span className="text-[15px] font-normal">{selectedPaymentObj.name}</span>
                      <div className="flex flex-col -space-y-1 text-neutral-400">
                        <ChevronUp className="w-3 h-3" />
                        <ChevronDown className="w-3 h-3" />
                      </div>
                    </div>
                  </div>

                  {/* Date Row */}
                  <div className="px-4 py-3.5 flex items-center justify-between">
                    <span className="text-[15px] font-normal text-neutral-800">Date</span>
                    <button
                      onClick={() => setIsDatePickerOpen(true)}
                      className="px-3.5 py-1.5 bg-neutral-200/70 hover:bg-neutral-200 text-neutral-900 rounded-xl text-[14px] font-medium active:scale-95 transition-all shadow-inner"
                    >
                      {formatDateDisplay(newExpenseDate)}
                    </button>
                  </div>
                </div>

                {/* Quick Smart Suggestion Pills if enabled */}
                {smartSuggestions && (
                  <div className="pt-1">
                    <div className="flex items-center gap-1.5 text-[12px] font-medium text-neutral-400 px-1 mb-2">
                      <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                      <span>Smart quick tags</span>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {[
                        { title: 'Coffee & Snack', amount: '65.00', cat: 'food' },
                        { title: 'Uber Ride', amount: '120.00', cat: 'transportation' },
                        { title: 'Groceries', amount: '450.00', cat: 'shopping' },
                        { title: 'Gym Supps', amount: '350.00', cat: 'health' }
                      ].map((sugg, i) => (
                        <button
                          key={i}
                          type="button"
                          onClick={() => {
                            setNewExpenseTitle(sugg.title);
                            setNewExpenseAmount(sugg.amount);
                            setNewExpenseCategory(sugg.cat);
                          }}
                          className="px-3 py-1.5 bg-white border border-neutral-200 rounded-full text-[12px] text-neutral-700 font-medium hover:bg-neutral-100 active:scale-95 shadow-2xs transition-all"
                        >
                          + {sugg.title} ({currency.symbol}{sugg.amount})
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Interactive Virtual iOS Keyboard Simulation */}
              {showVirtualKeyboard && (
                <div className="bg-[#D1D3D9] pt-2 pb-5 px-1.5 border-t border-neutral-300 shadow-inner select-none animate-in slide-in-from-bottom-5">
                  {/* Top Word Suggestions Bar */}
                  <div className="flex justify-around items-center py-1.5 mb-1.5 text-[14px] text-neutral-700 font-normal border-b border-neutral-300/60">
                    <span className="hover:text-black cursor-pointer">I</span>
                    <span className="hover:text-black cursor-pointer font-medium">The</span>
                    <span className="hover:text-black cursor-pointer">I'm</span>
                  </div>

                  {/* Keyboard Keys Layout */}
                  <div className="space-y-2">
                    {/* Row 1 */}
                    <div className="flex justify-center gap-1.5 px-0.5">
                      {['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'].map((k) => (
                        <button
                          key={k}
                          onClick={() => setNewExpenseTitle(prev => prev + k)}
                          className="flex-1 h-10 bg-white rounded-md shadow-[0_1px_1px_rgba(0,0,0,0.25)] flex items-center justify-center text-[18px] font-normal text-black active:bg-neutral-200 transition-colors"
                        >
                          {k}
                        </button>
                      ))}
                    </div>
                    {/* Row 2 */}
                    <div className="flex justify-center gap-1.5 px-3">
                      {['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'].map((k) => (
                        <button
                          key={k}
                          onClick={() => setNewExpenseTitle(prev => prev + k)}
                          className="flex-1 h-10 bg-white rounded-md shadow-[0_1px_1px_rgba(0,0,0,0.25)] flex items-center justify-center text-[18px] font-normal text-black active:bg-neutral-200 transition-colors"
                        >
                          {k}
                        </button>
                      ))}
                    </div>
                    {/* Row 3 with Shift and Backspace */}
                    <div className="flex justify-between gap-1.5 px-0.5">
                      <button className="w-10 h-10 bg-[#B4B7BF] rounded-md shadow-xs flex items-center justify-center text-black active:bg-white">
                        <ChevronUp className="w-5 h-5 stroke-[2.5]" />
                      </button>
                      <div className="flex-1 flex gap-1.5">
                        {['Z', 'X', 'C', 'V', 'B', 'N', 'M'].map((k) => (
                          <button
                            key={k}
                            onClick={() => setNewExpenseTitle(prev => prev + k)}
                            className="flex-1 h-10 bg-white rounded-md shadow-[0_1px_1px_rgba(0,0,0,0.25)] flex items-center justify-center text-[18px] font-normal text-black active:bg-neutral-200"
                          >
                            {k}
                          </button>
                        ))}
                      </div>
                      <button
                        onClick={() => setNewExpenseTitle(prev => prev.slice(0, -1))}
                        className="w-10 h-10 bg-[#B4B7BF] rounded-md shadow-xs flex items-center justify-center text-black active:bg-white"
                      >
                        <Delete className="w-5 h-5" />
                      </button>
                    </div>
                    {/* Row 4 Bottom Bar */}
                    <div className="flex justify-between gap-1.5 px-0.5 pt-1">
                      <button className="w-10 h-10 bg-[#B4B7BF] rounded-md flex items-center justify-center text-[13px] font-semibold text-black">
                        123
                      </button>
                      <button className="w-10 h-10 bg-[#B4B7BF] rounded-md flex items-center justify-center text-black">
                        <Smile className="w-5 h-5" />
                      </button>
                      <button
                        onClick={() => setNewExpenseTitle(prev => prev + ' ')}
                        className="flex-1 h-10 bg-white rounded-md shadow-xs flex items-center justify-center text-[14px] text-neutral-400"
                      >
                        space
                      </button>
                      <button
                        onClick={() => setShowVirtualKeyboard(false)}
                        className="w-14 h-10 bg-[#B4B7BF] rounded-md flex items-center justify-center text-[13px] font-medium text-black"
                      >
                        return
                      </button>
                      <button className="w-10 h-10 bg-[#B4B7BF] rounded-md flex items-center justify-center text-black">
                        <Mic className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 2: CATEGORY PICKER POPOVER / MENU */}
        {/* ------------------------------------------------------------- */}
        {isCategoryPickerOpen && (
          <div
            onClick={() => setIsCategoryPickerOpen(false)}
            className="absolute inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-6 animate-in fade-in duration-200"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-[290px] bg-white/95 backdrop-blur-xl rounded-[26px] shadow-2xl border border-white/40 overflow-hidden py-2 divide-y divide-neutral-100 animate-in zoom-in-95 duration-200"
            >
              <div className="px-4 py-2">
                <span className="text-[12px] font-semibold text-neutral-400 uppercase tracking-wider">Select Category</span>
              </div>
              <div className="max-h-72 overflow-y-auto divide-y divide-neutral-100">
                {CATEGORIES.map((cat) => {
                  const isSelected = newExpenseCategory === cat.id;
                  const Icon = cat.icon;
                  return (
                    <button
                      key={cat.id}
                      onClick={() => {
                        setNewExpenseCategory(cat.id);
                        setIsCategoryPickerOpen(false);
                      }}
                      className="w-full px-4 py-3 flex items-center justify-between text-left hover:bg-neutral-100/80 active:bg-neutral-200 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-7 h-7 rounded-lg flex items-center justify-center ${cat.color}`}>
                          <Icon className="w-4 h-4" />
                        </div>
                        <span className={`text-[15px] ${isSelected ? 'font-semibold text-black' : 'text-neutral-800'}`}>
                          {cat.name}
                        </span>
                      </div>
                      {isSelected && <Check className="w-4 h-4 text-black stroke-[3]" />}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 3: PAYMENT METHOD PICKER */}
        {/* ------------------------------------------------------------- */}
        {isPaymentPickerOpen && (
          <div
            onClick={() => setIsPaymentPickerOpen(false)}
            className="absolute inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-6 animate-in fade-in duration-200"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-[280px] bg-white/95 backdrop-blur-xl rounded-[26px] shadow-2xl border border-white/40 overflow-hidden py-2 animate-in zoom-in-95 duration-200"
            >
              <div className="px-4 py-2 border-b border-neutral-100">
                <span className="text-[12px] font-semibold text-neutral-400 uppercase tracking-wider">Payment Method</span>
              </div>
              <div className="divide-y divide-neutral-100">
                {PAYMENT_METHODS.map((method) => {
                  const isSelected = newExpensePayment === method.id;
                  return (
                    <button
                      key={method.id}
                      onClick={() => {
                        setNewExpensePayment(method.id);
                        setIsPaymentPickerOpen(false);
                      }}
                      className="w-full px-4 py-3 flex items-center justify-between text-left hover:bg-neutral-100 active:bg-neutral-200 transition-colors"
                    >
                      <span className={`text-[15px] ${isSelected ? 'font-semibold text-black' : 'text-neutral-800'}`}>
                        {method.name}
                      </span>
                      {isSelected && <Check className="w-4 h-4 text-black stroke-[3]" />}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 4: CALENDAR DATE PICKER SHEET */}
        {/* ------------------------------------------------------------- */}
        {isDatePickerOpen && (
          <div className="absolute inset-0 z-50 bg-black/30 backdrop-blur-xs flex flex-col justify-end transition-all">
            <div className="bg-[#F2F2F7] rounded-t-[36px] shadow-2xl p-5 pb-8 animate-in slide-in-from-bottom duration-300">
              {/* Header with Close and Title */}
              <div className="flex items-center justify-between mb-4">
                <button
                  onClick={() => setIsDatePickerOpen(false)}
                  className="w-8 h-8 rounded-full bg-neutral-200/80 flex items-center justify-center text-neutral-600 hover:text-black active:scale-90 transition-transform"
                >
                  <X className="w-4 h-4 stroke-[2.5]" />
                </button>
                <h4 className="text-[16px] font-bold text-black tracking-tight">Date</h4>
                <div className="w-8" />
              </div>

              {/* Month Selector Navigation */}
              <div className="flex items-center justify-between px-2 mb-3">
                <div className="flex items-center gap-1.5 cursor-pointer">
                  <span className="text-[17px] font-bold text-black">
                    {['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][calendarMonth]} {calendarYear}
                  </span>
                  <ChevronRight className="w-4 h-4 text-neutral-500" />
                </div>
                <div className="flex items-center gap-4 text-neutral-800">
                  <button
                    onClick={() => {
                      if (calendarMonth === 0) {
                        setCalendarMonth(11);
                        setCalendarYear(calendarYear - 1);
                      } else {
                        setCalendarMonth(calendarMonth - 1);
                      }
                    }}
                    className="p-1 hover:text-black active:scale-90 transition-transform"
                  >
                    <ChevronLeft className="w-5 h-5 stroke-[2.5]" />
                  </button>
                  <button
                    onClick={() => {
                      if (calendarMonth === 11) {
                        setCalendarMonth(0);
                        setCalendarYear(calendarYear + 1);
                      } else {
                        setCalendarMonth(calendarMonth + 1);
                      }
                    }}
                    className="p-1 hover:text-black active:scale-90 transition-transform"
                  >
                    <ChevronRight className="w-5 h-5 stroke-[2.5]" />
                  </button>
                </div>
              </div>

              {/* Days Header */}
              <div className="grid grid-cols-7 text-center mb-2">
                {['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((d) => (
                  <span key={d} className="text-[11px] font-semibold text-neutral-400 tracking-wider">
                    {d}
                  </span>
                ))}
              </div>

              {/* Calendar Days Grid */}
              <div className="grid grid-cols-7 gap-y-1.5 text-center">
                {calendarDays.map((dayItem, index) => {
                  if (!dayItem) {
                    return <div key={`empty-${index}`} className="h-10" />;
                  }

                  const isSelected = newExpenseDate === dayItem.dateString;
                  const isToday = dayItem.dateString === '2026-08-28';

                  return (
                    <div key={dayItem.dateString} className="h-10 flex items-center justify-center">
                      <button
                        onClick={() => {
                          setNewExpenseDate(dayItem.dateString);
                          setIsDatePickerOpen(false);
                        }}
                        className={`w-9 h-9 rounded-full flex items-center justify-center text-[15px] font-medium transition-all ${
                          isSelected
                            ? 'bg-black text-white font-bold shadow-md scale-105'
                            : isToday
                            ? 'bg-neutral-300 text-black font-semibold'
                            : 'text-neutral-800 hover:bg-neutral-200 active:scale-95'
                        }`}
                      >
                        {dayItem.dayNumber}
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 5: ACCOUNTS SHEET (NORMAL & EDIT MODES) */}
        {/* ------------------------------------------------------------- */}
        {isAccountsOpen && (
          <div className="absolute inset-0 z-40 bg-black/35 backdrop-blur-xs flex flex-col justify-end transition-all">
            <div className="bg-[#F2F2F7] rounded-t-[36px] shadow-2xl p-5 pb-8 animate-in slide-in-from-bottom duration-300">
              {/* Handle Bar */}
              <div className="w-10 h-1 bg-neutral-300 rounded-full mx-auto mb-3" />

              {/* Header */}
              <div className="flex items-center justify-between mb-4 px-1">
                {isAccountsEditing ? (
                  <button
                    onClick={() => setIsAccountsEditing(false)}
                    className="px-3.5 py-1.5 bg-neutral-200/80 rounded-full text-[14px] font-medium text-neutral-800"
                  >
                    Cancel
                  </button>
                ) : (
                  <button
                    onClick={() => setIsAccountsOpen(false)}
                    className="w-8 h-8 rounded-full bg-neutral-200/80 flex items-center justify-center text-neutral-600 hover:text-black active:scale-90 transition-transform"
                  >
                    <X className="w-4 h-4 stroke-[2.5]" />
                  </button>
                )}

                <h3 className="text-[16px] font-bold text-black tracking-tight">Accounts</h3>

                <button
                  onClick={() => setIsAccountsEditing(!isAccountsEditing)}
                  className="px-3.5 py-1.5 bg-neutral-200/80 hover:bg-neutral-300 rounded-full text-[14px] font-semibold text-black transition-all active:scale-95"
                >
                  {isAccountsEditing ? 'Done' : 'Edit'}
                </button>
              </div>

              {/* Accounts Inset List */}
              <div className="space-y-3 mt-4">
                {accounts.map((acc) => {
                  const isSelected = activeAccountId === acc.id;

                  return (
                    <div
                      key={acc.id}
                      onClick={() => {
                        if (!isAccountsEditing) {
                          setActiveAccountId(acc.id);
                          setIsAccountsOpen(false);
                        }
                      }}
                      className={`flex items-center justify-between p-4 bg-neutral-200/70 hover:bg-neutral-200 rounded-[20px] transition-all cursor-pointer ${
                        isSelected && !isAccountsEditing ? 'ring-2 ring-black/10' : ''
                      }`}
                    >
                      <div className="flex items-center gap-3.5">
                        {/* Edit delete red button */}
                        {isAccountsEditing && (
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeleteAccount(acc.id);
                            }}
                            className="w-6 h-6 rounded-full bg-red-500 text-white flex items-center justify-center active:scale-90 transition-transform"
                          >
                            <Minus className="w-4 h-4 stroke-[3]" />
                          </button>
                        )}

                        {/* Account Avatar Badge */}
                        <div className="w-10 h-10 rounded-[14px] bg-white flex items-center justify-center shadow-xs">
                          {acc.icon === 'briefcase' ? (
                            <Briefcase className="w-5 h-5 text-neutral-800" />
                          ) : (
                            <User className="w-5 h-5 text-neutral-800 fill-neutral-800" />
                          )}
                        </div>

                        <div>
                          <p className="text-[16px] font-semibold text-black">{acc.name}</p>
                          <p className="text-[12px] text-neutral-400">{formatMoney(acc.balance)}</p>
                        </div>
                      </div>

                      {/* Right Indicator / Actions */}
                      <div>
                        {isAccountsEditing ? (
                          <Menu className="w-5 h-5 text-neutral-400 cursor-grab" />
                        ) : (
                          isSelected && <Check className="w-5 h-5 text-black stroke-[3]" />
                        )}
                      </div>
                    </div>
                  );
                })}

                {/* Add Account Button Row */}
                <button
                  onClick={() => setIsAddAccountModalOpen(true)}
                  className="w-full flex items-center justify-start p-4 bg-neutral-200/70 hover:bg-neutral-200 rounded-[20px] transition-colors text-[15px] font-semibold text-black active:scale-[0.99]"
                >
                  <span className="ml-1">Add Account</span>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 6: SETTINGS VIEW */}
        {/* ------------------------------------------------------------- */}
        {isSettingsOpen && (
          <div className="absolute inset-0 z-50 bg-[#F2F2F7] flex flex-col animate-in slide-in-from-right duration-300">
            {/* Settings Top Bar */}
            <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-neutral-200/70">
              <button
                onClick={() => setIsSettingsOpen(false)}
                className="w-8 h-8 rounded-full bg-white flex items-center justify-center text-neutral-600 shadow-xs active:scale-90 transition-transform"
              >
                <X className="w-4 h-4 stroke-[2.5]" />
              </button>
              <h3 className="text-[16px] font-bold text-black tracking-tight">Settings</h3>
              <div className="w-8" />
            </div>

            {/* Scrollable Settings Content */}
            <div className="flex-1 overflow-y-auto p-4 space-y-5 pb-12">
              {/* Pro Cosmic Upgrade Banner (Matches Screenshot 3) */}
              <div
                onClick={() => setIsProModalOpen(true)}
                className="relative overflow-hidden rounded-[26px] bg-black p-5 text-white shadow-xl cursor-pointer group"
                style={{
                  backgroundImage: 'radial-gradient(ellipse at 80% 20%, rgba(255,255,255,0.2) 0%, transparent 60%), radial-gradient(ellipse at 20% 80%, rgba(120,119,198,0.25) 0%, transparent 70%)'
                }}
              >
                {/* Subtle stars SVG dots */}
                <div className="absolute inset-0 opacity-40 pointer-events-none">
                  <div className="absolute top-3 left-8 w-1 h-1 bg-white rounded-full animate-ping" />
                  <div className="absolute top-8 right-16 w-1.5 h-1.5 bg-white rounded-full" />
                  <div className="absolute bottom-4 left-1/3 w-1 h-1 bg-white rounded-full" />
                  <div className="absolute bottom-6 right-8 w-1 h-1 bg-white rounded-full" />
                </div>

                <div className="flex items-center justify-between relative z-10">
                  <div>
                    <h4 className="text-[18px] font-bold tracking-tight">SyncSpend Pro</h4>
                    <p className="text-[12px] text-neutral-400 mt-0.5">7 days left in trial</p>
                  </div>
                  <button className="px-4 py-1.5 bg-white text-black text-[13px] font-bold rounded-full shadow-md group-hover:scale-105 active:scale-95 transition-all">
                    Upgrade
                  </button>
                </div>
              </div>

              {/* Account Info Card */}
              <div className="bg-white rounded-[24px] p-4 shadow-sm border border-neutral-100 flex items-center justify-between cursor-pointer hover:bg-neutral-50 transition-colors">
                <div className="flex items-center gap-3.5">
                  <div className="w-12 h-12 rounded-full bg-neutral-100 flex items-center justify-center text-[20px] font-bold text-black border border-neutral-200">
                    P
                  </div>
                  <div>
                    <h5 className="text-[16px] font-bold text-black">{currentAccount.name}</h5>
                    <p className="text-[12px] text-neutral-400">Account info, categories and payments</p>
                  </div>
                </div>
                <ChevronRight className="w-4 h-4 text-neutral-400" />
              </div>

              {/* Preferences Section */}
              <div className="space-y-2">
                <span className="text-[13px] font-medium text-neutral-400 px-3">Preferences</span>
                <div className="bg-white rounded-[24px] shadow-sm border border-neutral-100 divide-y divide-neutral-100 overflow-hidden">
                  {/* Currency Picker Row */}
                  <div
                    onClick={() => {
                      const currIdx = CURRENCIES.findIndex(c => c.code === currency.code);
                      const next = CURRENCIES[(currIdx + 1) % CURRENCIES.length];
                      setCurrency(next);
                    }}
                    className="p-4 flex items-center justify-between cursor-pointer hover:bg-neutral-50 active:bg-neutral-100 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-[10px] bg-neutral-100 flex items-center justify-center text-black">
                        <DollarSign className="w-4 h-4 stroke-[2.5]" />
                      </div>
                      <span className="text-[15px] font-medium text-black">Currency</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-neutral-400">
                      <span className="text-[15px] font-medium text-neutral-500">{currency.code}</span>
                      <ChevronRight className="w-4 h-4" />
                    </div>
                  </div>

                  {/* Start Week On Row */}
                  <div
                    onClick={() => setStartWeekOn(prev => (prev === 'Sunday' ? 'Monday' : 'Sunday'))}
                    className="p-4 flex items-center justify-between cursor-pointer hover:bg-neutral-50 active:bg-neutral-100 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-[10px] bg-neutral-100 flex items-center justify-center text-black">
                        <CalendarIcon className="w-4 h-4" />
                      </div>
                      <span className="text-[15px] font-medium text-black">Start Week On</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-neutral-400">
                      <span className="text-[15px] font-medium text-neutral-500">{startWeekOn}</span>
                      <ChevronRight className="w-4 h-4" />
                    </div>
                  </div>

                  {/* Smart Suggestions Toggle */}
                  <div className="p-4 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-[10px] bg-neutral-100 flex items-center justify-center text-black">
                        <Sparkles className="w-4 h-4" />
                      </div>
                      <span className="text-[15px] font-medium text-black">Smart Suggestions</span>
                    </div>
                    <button
                      onClick={() => setSmartSuggestions(!smartSuggestions)}
                      className={`w-12 h-7 rounded-full transition-colors relative p-0.5 ${
                        smartSuggestions ? 'bg-black' : 'bg-neutral-300'
                      }`}
                    >
                      <div
                        className={`w-6 h-6 rounded-full bg-white shadow-md transform transition-transform ${
                          smartSuggestions ? 'translate-x-5' : 'translate-x-0'
                        }`}
                      />
                    </button>
                  </div>

                  {/* Shortcut Row */}
                  <div className="p-4 flex items-center justify-between cursor-pointer hover:bg-neutral-50">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-[10px] bg-neutral-100 flex items-center justify-center text-black">
                        <Command className="w-4 h-4" />
                      </div>
                      <span className="text-[15px] font-medium text-black">Shortcut</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-neutral-400" />
                  </div>
                </div>
              </div>

              {/* Support Section */}
              <div className="space-y-2">
                <span className="text-[13px] font-medium text-neutral-400 px-3">Support</span>
                <div className="bg-white rounded-[24px] shadow-sm border border-neutral-100 divide-y divide-neutral-100 overflow-hidden">
                  <div className="p-4 flex items-center justify-between cursor-pointer hover:bg-neutral-50">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-[10px] bg-neutral-100 flex items-center justify-center text-black">
                        <FileText className="w-4 h-4" />
                      </div>
                      <span className="text-[15px] font-medium text-black">Tutorials</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-neutral-400" />
                  </div>

                  <div className="p-4 flex items-center justify-between cursor-pointer hover:bg-neutral-50">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-[10px] bg-neutral-100 flex items-center justify-center text-black">
                        <Sparkles className="w-4 h-4" />
                      </div>
                      <span className="text-[15px] font-medium text-black">What's New</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-neutral-400" />
                  </div>
                </div>
              </div>

              {/* App Version Info */}
              <div className="text-center pt-4">
                <p className="text-[12px] text-neutral-400 font-medium">SyncSpend iOS 2.4.1 (Build 2026)</p>
              </div>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 7: SEARCH & INSTANT FILTER SHEET */}
        {/* ------------------------------------------------------------- */}
        {isSearchOpen && (
          <div className="absolute inset-0 z-50 bg-[#F2F2F7] flex flex-col animate-in fade-in duration-200">
            <div className="px-5 pt-4 pb-3 flex items-center gap-3 border-b border-neutral-200">
              <div className="flex-1 flex items-center gap-2 bg-white px-3.5 py-2 rounded-full border border-neutral-200/80 shadow-xs">
                <Search className="w-4 h-4 text-neutral-400" />
                <input
                  type="text"
                  placeholder="Search transactions..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full text-[14px] bg-transparent focus:outline-none text-black"
                  autoFocus
                />
                {searchQuery && (
                  <button onClick={() => setSearchQuery('')}>
                    <X className="w-4 h-4 text-neutral-400" />
                  </button>
                )}
              </div>
              <button
                onClick={() => {
                  setSearchQuery('');
                  setIsSearchOpen(false);
                }}
                className="text-[14px] font-semibold text-neutral-800"
              >
                Done
              </button>
            </div>

            {/* Filter tags inside search */}
            <div className="p-4 flex-1 overflow-y-auto space-y-4">
              <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
                <button
                  onClick={() => setSelectedFilterCategory('all')}
                  className={`px-3 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-colors ${
                    selectedFilterCategory === 'all'
                      ? 'bg-black text-white'
                      : 'bg-white text-neutral-700 border border-neutral-200'
                  }`}
                >
                  All Categories
                </button>
                {CATEGORIES.filter(c => c.id !== 'none').map(c => (
                  <button
                    key={c.id}
                    onClick={() => setSelectedFilterCategory(c.id)}
                    className={`px-3 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-colors ${
                      selectedFilterCategory === c.id
                        ? 'bg-black text-white'
                        : 'bg-white text-neutral-700 border border-neutral-200'
                    }`}
                  >
                    {c.name}
                  </button>
                ))}
              </div>

              {/* Quick Results */}
              <div className="space-y-2">
                <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider">
                  Matching Transactions ({accountExpenses.filter(e => e.title.toLowerCase().includes(searchQuery.toLowerCase())).length})
                </p>
                <div className="bg-white rounded-2xl divide-y divide-neutral-100 overflow-hidden shadow-xs border border-neutral-200/60">
                  {accountExpenses
                    .filter(e => e.title.toLowerCase().includes(searchQuery.toLowerCase()))
                    .map(exp => (
                      <div key={exp.id} className="p-3.5 flex items-center justify-between">
                        <div>
                          <p className="text-sm font-semibold text-black">{exp.title}</p>
                          <p className="text-xs text-neutral-400">{formatDateDisplay(exp.date)}</p>
                        </div>
                        <span className="text-sm font-bold text-black">{formatMoney(exp.amount)}</span>
                      </div>
                    ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 8: PRO UPGRADE MODAL */}
        {/* ------------------------------------------------------------- */}
        {isProModalOpen && (
          <div
            onClick={() => setIsProModalOpen(false)}
            className="absolute inset-0 z-50 bg-black/60 backdrop-blur-md flex items-center justify-center p-6 animate-in fade-in"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-[340px] bg-neutral-900 text-white rounded-[32px] p-6 shadow-2xl border border-neutral-800 relative overflow-hidden"
            >
              <div className="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center mx-auto mb-4">
                <Sparkles className="w-6 h-6 text-amber-400" />
              </div>

              <h3 className="text-[20px] font-bold text-center tracking-tight">SyncSpend Pro</h3>
              <p className="text-[13px] text-neutral-400 text-center mt-1 mb-6">
                Unlimited cloud sync, smart receipt OCR scan, multi-currency exports, and recurring budgets.
              </p>

              <div className="space-y-2.5 mb-6">
                <div className="flex items-center gap-2.5 text-[13px] text-neutral-300">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  <span>Real-time multi-device sync</span>
                </div>
                <div className="flex items-center gap-2.5 text-[13px] text-neutral-300">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  <span>Unlimited custom categories</span>
                </div>
                <div className="flex items-center gap-2.5 text-[13px] text-neutral-300">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  <span>CSV and PDF tax export</span>
                </div>
              </div>

              <button
                onClick={() => setIsProModalOpen(false)}
                className="w-full py-3 bg-white text-black font-bold rounded-2xl text-[15px] hover:bg-neutral-100 active:scale-95 transition-all shadow-lg"
              >
                Start 7-Day Free Trial
              </button>

              <button
                onClick={() => setIsProModalOpen(false)}
                className="w-full mt-2.5 py-2 text-neutral-400 text-[13px] font-medium hover:text-white"
              >
                Maybe Later
              </button>
            </div>
          </div>
        )}

        {/* ------------------------------------------------------------- */}
        {/* MODAL 9: ADD ACCOUNT MODAL */}
        {/* ------------------------------------------------------------- */}
        {isAddAccountModalOpen && (
          <div
            onClick={() => setIsAddAccountModalOpen(false)}
            className="absolute inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-6 animate-in fade-in"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-[300px] bg-white rounded-[28px] p-5 shadow-2xl border border-neutral-200"
            >
              <h4 className="text-[17px] font-bold text-black text-center mb-4">New Account</h4>
              <input
                type="text"
                placeholder="e.g. Travel, Investments"
                value={newAccountName}
                onChange={(e) => setNewAccountName(e.target.value)}
                className="w-full px-4 py-3 bg-neutral-100 rounded-xl text-[15px] text-black focus:outline-none mb-4"
                autoFocus
              />
              <div className="flex gap-2">
                <button
                  onClick={() => setIsAddAccountModalOpen(false)}
                  className="flex-1 py-2.5 bg-neutral-100 text-neutral-700 font-semibold rounded-xl text-[14px]"
                >
                  Cancel
                </button>
                <button
                  onClick={handleAddAccount}
                  disabled={!newAccountName.trim()}
                  className="flex-1 py-2.5 bg-black text-white font-semibold rounded-xl text-[14px] disabled:opacity-40"
                >
                  Create
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Bottom iOS Home Indicator Bar */}
        <div className="absolute bottom-1.5 inset-x-0 flex justify-center pointer-events-none z-30">
          <div className="w-36 h-1 bg-black/80 rounded-full" />
        </div>
      </div>
    </div>
  );
}