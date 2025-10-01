# 💰 Flutter Money Manager App - Development Log

This document outlines all tasks, features, and fixes in the development of your Flutter money manager application.

---

## ✅ Completed Features & Improvements

### 🔨 Functionality

- ✅ Auto-appear name in "Person Name" field
- ✅ Automatic cursor focus: Expense first, then Income
- ✅ Setting: Auto scrolls to top in Add Transaction window
- ✅ Deleting from main screen also deletes from people screen
- ✅ Created "People Transaction" button on the home screen
- ✅ Transactions update the main balance (both give/take)
- ✅ History entry on main page for people transactions
- ✅ Auto-focus amount field in "People Transaction Modal" (based on setting)
- ✅ Fixed double-subtraction bug in balance update
- ✅ Removed Net Balance, added “You owe” and “Owes you” in People Manager
- ✅ Replaced income card "+" prefix with clean numbers
- ✅ Replaced "Pay back"/"Collect from" card messages with simpler entries
- ✅ Improved people manager icons and "settled" card design
- ✅ Applied colored card theme across the app (income: green, expense: red, settled: gray)
- ✅ Home screen: Placed FABs side by side with improved layout
- ✅ Date format changed to `dd-mm-yy HH:MM AM/PM`
- ✅ Infinitely scrollable Recent Transactions list with fade-in/out FAB animations
- ✅ Placed "Expense" on left and "Income" on right in Add Transaction modal
- ✅ Rearranged amount and name fields in "People Transaction" modal
- ✅ Person Detail: Owe claim now persists and reflects correctly
- ✅ Removed "+" prefix in income cards
- ✅ Improved card designs across Monthly Summary
- ✅ Placed "owes you" on left and "you owe" on right in People Manager
- ✅ Fix crash issue in People Manager screen when locking/unlocking phone
- ✅ Fix People Manager crash issue after screen off/on (text scatter bug)
- ✅ implement share people transaction feature - user can share their transaction history between people via whatsapp.
- ✅ implement app bar navigation
- ✅ improve FABs
- ✅ improve add_people_transaction_modal
- 


---

## ⬜ Pending Tasks (TODO)

- ⬜ edit feature coming soon problem
- ⬜ Implement chart for financial visualization in balance card
- ⬜ Onboarding: Progressive cards showing app value propositions
- ⬜ Add balance update animations with positive/negative feedback
- ⬜ Add widget support for quick insights

---

## 🗑️ Cancelled

- 🗑️ Insufficient funds error — negative balances are allowed

---

## 🐛 Known Bugs & Fixes

- ⬜ Scrambled UI issue on People Manager screen after screen lock

---

## 🎨 UX / UI Enhancements

- ✅ Added focus transitions between fields using keyboard "tick"
- ✅ Dual FABs placed side by side at the bottom-center for better usability
- ✅ Smooth scroll animations with fade for buttons
- ✅ Implemented consistent themes for cards (income, expense, settled, owe, etc.)
- ⬜ Add animations for positive/negative balance changes
- ⬜ Guided onboarding and first action prompts
- ⬜ Improve error/warning/info message presentation

---

## 🧠 Future Enhancements & Ideas

- ⬜ Export/import feature for transaction history
- ⬜ Shared expenses: sync transactions with contacts

---

