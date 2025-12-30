# Cycle Sync MVP - Architecture & Design Principles

## Design Principles

### 1. **Separation of Concerns**
- **Models/** - Data structures (Phase, User, Cycle)
- **Services/** - Supabase integration & business logic
- **Screens/** - UI only (no business logic)
- **Utils/** - Helpers (cycle math, validators)
- **Widgets/** - Reusable UI components

### 2. **Single Source of Truth**
- Supabase is the authoritative data store
- All cycle data flows through `supabase_cycle_manager.dart`
- Local SharedPreferences used only for temporary caching
- No duplicate data sources

### 3. **Minimal Clutter - MVP Features Only**
Period tracking app focuses ONLY on:
- ✅ Cycle tracking (period dates, cycle length)
- ✅ Phase detection (menstrual, follicular, ovulation, luteal)
- ✅ Calendar view (monthly phases)
- ✅ Dashboard (current phase, cycle day info)
- ✅ Predictions (next period, ovulation date)
- ✅ User profile (basic info)
- ✅ Authentication (login/register)

**NOT in MVP** (Future layers):
- ❌ Lifestyle tracking (fasting, fitness, nutrition - saved for Phase 2)
- ❌ Goals module (saved for Phase 2)
- ❌ Advanced analytics (saved for Phase 2)
- ❌ Symptom logging (saved for Phase 2)

### 4. **Extensibility**
The following screens/services are ready for future expansion:
```
Phase 2: Lifestyle Tracking
├── fasting_suggestions_screen.dart
├── fitness_suggestions_screen.dart
├── nutrition_suggestions_screen.dart
└── supabase_goal_manager.dart

Phase 3: Analytics
├── insights_screen.dart (ready for data)
└── Advanced reports

Phase 4: Wearables & Integrations
└── (Future integration layer)
```

## Core Data Flow

### 1. Authentication Flow
```
LoginScreen/RegisterScreen 
  → supabase_user_manager.dart 
  → Supabase Auth 
  → MainNavigation
```

### 2. Cycle Data Flow
```
OnboardingCycleInputScreen 
  → supabase_cycle_manager.dart 
  → Supabase Database
  → (Dashboard, Calendar, ProfileScreen use this data)
```

### 3. Phase Calculation
```
cycle_utils.dart (pure functions)
  ← lastPeriodStart, cycleLength from Supabase
  → Returns: currentPhase, cycleDay, predictions
```

## Database Schema (Supabase)

### users table
```
- id (UUID, PK)
- email (unique)
- created_at
```

### user_preferences table
```
- id (UUID, PK)
- user_id (FK)
- cycle_length (int)
- period_length (int)
- last_period_start (timestamp)
- created_at
- updated_at
```

**Single source of truth:** All cycle calculations derive from `user_preferences`

## Key Services

### supabase_service.dart
- Supabase client initialization
- Session management

### supabase_cycle_manager.dart
- `saveCycleData()` - Save period dates
- `getCycleData()` - Retrieve cycle info
- `calculatePhase()` - Uses cycle_utils

### supabase_user_manager.dart
- Authentication (login, register, logout)
- Password reset

### cycle_utils.dart
- Pure functions for calculations
- No external dependencies
- `getCyclePhase()` - Calculates current phase
- `getHormonalBasis()` - Pulls from Phase model
- `getWorkoutPhase()` - Pulls from Phase model
- `getNutritionGuidance()` - Pulls from Phase model
- `getFastingPhase()` - Pulls from Phase model
- `getPhaseGuidance()` - Returns all guidance from Phase model
- `getWorkoutPhaseEmoji()` - Pulls from Phase model
- `getNutritionPhaseEmoji()` - Pulls from Phase model

### **Phase Model - Single Source of Truth** ⭐
**File**: `lib/models/phase.dart`

ALL phase-related predictions come from this single model:
- ✅ Hormonal basis (estrogen/progesterone states)
- ✅ Workout phases (Power, Manifestation, Nurture - Dr. Mindy Pelz)
- ✅ Nutrition approaches (Ketobiotic, Hormone Feasting - Dr. Indy Kensington)
- ✅ Fasting recommendations
- ✅ Phase emojis and descriptions

**Update cycle guidance?** Edit ONE place: `CyclePhases.phases` in `phase.dart`  
All screens automatically use the updated data. No switch statements. Pure SSoT design.

See `PHASE_PREDICTIONS_GUIDE.md` for detailed guidance system documentation.

## UI Architecture

### Main Navigation Structure
```
MainNavigation (BottomAppBar with 4 tabs + centered FAB)
├── Dashboard (1) - Current phase, cycle day
├── Calendar (2) - Monthly view with phases
├── FAB (center) - Quick actions
├── Insights (3) - Phase insights (expandable for Phase 2)
└── Profile (4) - User settings, cycle config
```

### Design System
- **Minimalist**: No gradients, no shadows
- **Divider-based**: Use borders instead of cards
- **Consistent colors**: Phase colors only
- **Clean typography**: 2-3 font sizes max

## Testing Strategy

### Unit Tests
- `cycle_utils.dart` - Phase calculations
- `supabase_cycle_manager.dart` - Data persistence

### Integration Tests
- Full auth flow
- Cycle data save/retrieve
- Phase predictions

### Manual Testing (MVP)
1. ✅ Register → cycle config → dashboard shows correct phase
2. ✅ Calendar shows correct phases for month
3. ✅ Predictions show next period/ovulation
4. ✅ Edit cycle info → updates predictions

## Performance Considerations

1. **Caching**: Use SharedPreferences for temporary caching (reduce Supabase calls)
2. **Calculations**: `cycle_utils` functions are pure, can be cached
3. **Lazy loading**: Load only visible month in calendar
4. **Minimal queries**: Only fetch what's needed per screen

## Future Roadmap

### Phase 2: Lifestyle Tracking
- Add symptom logging
- Add goal tracking
- Enable fasting/fitness/nutrition recommendations

### Phase 3: Analytics
- Generate insights from period patterns
- Period prediction accuracy tracking
- Health trends

### Phase 4: Integrations
- Calendar app sync (Google Calendar, Apple Calendar)
- Wearable device integration
- Third-party health app integration

## Code Quality Checklist

- [ ] No business logic in UI (screens have no calculations)
- [ ] All cycle calculations in `cycle_utils.dart`
- [ ] All Supabase calls through services
- [ ] No duplicate data sources
- [ ] Supabase is single source of truth
- [ ] Minimal dependencies per screen
- [ ] Reusable widgets in `widgets/`
- [ ] No hard-coded values (use constants)
- [ ] Tests for critical functions
- [ ] Clean error handling

## Getting Started for Contributors

1. **Adding a new screen?** - Use services, don't call Supabase directly
2. **New calculation?** - Add to `cycle_utils.dart`, make it pure
3. **New feature?** - Check if it belongs in current MVP or Phase 2+
4. **Design changes?** - Keep minimalist, use dividers, no gradients
