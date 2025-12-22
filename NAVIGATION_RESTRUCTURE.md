# Navigation Restructure - Dashboard & Calendar Split

## Overview
Restructured the app to separate **Dashboard** (Statistics & Insights) from **Calendar** (Day-by-Day Planning) with bottom navigation between them.

## Architecture Changes

### Previous Structure
```
main.dart
  └── OnboardingWelcomeScreen
  └── OnboardingCycleInputScreen  
  └── OnboardingLifestyleScreen
  └── DashboardScreen (Calendar + Bottom Nav)
```

### New Structure
```
main.dart
  └── OnboardingWelcomeScreen
  └── OnboardingCycleInputScreen
  └── OnboardingLifestyleScreen
  └── HomeScreen (Navigation Container)
      ├── DashboardScreen (Statistics & Graphs)
      └── CalendarScreen (Calendar & Day Details)
```

## Files Changed

### 1. **lib/screens/home_screen.dart** (NEW)
- **Purpose**: Main navigation hub with bottom navigation bar
- **Navigation Items**: 
  - Dashboard (bar chart icon) → Shows statistics, insights, cycle timeline
  - Calendar (calendar icon) → Shows calendar view and day details modal
- **State**: Manages tab switching between Dashboard and Calendar

### 2. **lib/screens/dashboard_screen.dart** (REFACTORED)
- **Previous Role**: Calendar + Navigation
- **New Role**: Statistics & Insights Dashboard
- **Features**:
  - Phase progress card with circular progress indicator
  - Statistics grid: Completed Workouts, Meals, Fasting Days
  - Current phase details (Diet, Workout, Fasting, Energy)
  - Cycle phases timeline (horizontal scrollable)
  - Completion summary with progress bar
  - No calendar - just data visualization

### 3. **lib/screens/calendar_screen.dart** (NEW)
- **Previous Name**: DashboardScreen (renamed)
- **Purpose**: Calendar-based cycle planning
- **Features**:
  - Full month calendar view
  - Phase-colored day indicators
  - Click day → Shows DayDetailsModal
  - All lifestyle cards (Fitness, Nutrition, Fasting)
  - Same day details modal as before

### 4. **lib/main.dart** (UPDATED)
- **Import Change**: `dashboard_screen.dart` → `home_screen.dart`
- **Route Change**: `/dashboard` → `/home`
- **Home Screen**: Now `HomeScreen()` instead of `DashboardScreen()`

### 5. **lib/screens/onboarding_lifecycle_screen.dart** (UPDATED)
- **Navigation**: `pushReplacementNamed('/dashboard')` → `pushReplacementNamed('/home')`
- After onboarding completes, users land on HomeScreen

## User Flow

### Onboarding → App
```
OnboardingWelcomeScreen
    ↓
OnboardingCycleInputScreen
    ↓
OnboardingLifestyleScreen
    ↓
HomeScreen (Dashboard Tab Active)
```

### Navigation In-App
```
HomeScreen
├─ Dashboard Tab (Selected)
│  ├─ Phase Progress Card
│  ├─ Statistics Grid
│  ├─ Phase Details
│  ├─ Cycle Timeline
│  └─ Completion Summary
│
└─ Calendar Tab
   ├─ Month Calendar
   ├─ Click Day → DayDetailsModal
   │  ├─ Nutrition Card
   │  ├─ Fitness Card
   │  └─ Fasting Card
   └─ Select Options → Navigate to Suggestion Screens
```

## Screen Purpose Clarification

### Dashboard Screen (New)
**Goal**: Show overall cycle insights at a glance
- **Data Type**: Aggregated statistics
- **Interactions**: View-only (no direct modifications)
- **Visualizations**: 
  - Progress bars
  - Timeline
  - Statistics counters
  - Charts/graphs

### Calendar Screen (Renamed)
**Goal**: Plan personalized recommendations day-by-day
- **Data Type**: Day-specific selections
- **Interactions**: Click dates → Customize → Save
- **Visualizations**:
  - Calendar grid
  - Phase colors
  - Modal dialogs

## Benefits of This Structure

1. **Clarity**: Dashboard ≠ Calendar (different purposes)
2. **Navigation**: Bottom nav makes tab switching obvious
3. **Performance**: Each screen only loads its data
4. **UX**: Users know where to find stats (Dashboard) vs plan (Calendar)
5. **Scalability**: Easy to add "Trackers" or "Analysis" tabs later

## Bottom Navigation Items

| Icon | Label | Screen |
|------|-------|--------|
| 📊 | Dashboard | Statistics, insights, timeline, completion |
| 📅 | Calendar | Calendar view, day details, customization |

## Future Expansion

The bottom navigation structure is ready for additional tabs:
- Future: "Trackers" tab for logging mood/symptoms
- Future: "Analysis" tab for long-term patterns
- Future: "Settings" tab for preferences

Just add items to the `BottomNavigationBar` in HomeScreen and create corresponding screens.
