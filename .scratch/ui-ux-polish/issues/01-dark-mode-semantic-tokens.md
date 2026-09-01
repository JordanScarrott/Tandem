# 01: Adaptive Dark Mode & Semantic Design System Tokens

**What to build:**
Refactor the design token system in `Theme.swift` to use adaptive SwiftUI system colors (`Color(.systemGroupedBackground)`, `Color(.secondarySystemGroupedBackground)`, `Color(.label)`, `Color(.secondaryLabel)`) with fallback Hex support so that all cards, texts, backgrounds, and sheets automatically adapt between Light Mode and Dark Mode with high contrast and sleek glassmorphism styling.

**Blocked by:** None (can start immediately)

**Status:** completed

- [x] Update `Theme.swift` color definitions to dynamically support Dark and Light mode.
- [x] Ensure card background and stroke borders adapt gracefully with subtle shadows in Dark mode.
- [x] Add standardized haptic helper utilities (`Haptics.selection()`, `Haptics.impact(.medium)`, `Haptics.notification(.success)`).
- [x] Verify views consuming `Theme` render cleanly in both color schemes without unreadable text.

