# Quick Reference - Phase Prediction System

## Single Source of Truth: Phase Model

**Location:** `lib/models/phase.dart` → `CyclePhases.phases`

Every phase has these properties:

```dart
Phase(
  name: 'Menstrual',                              // Phase name
  emoji: '🩸',                                     // Phase emoji
  description: 'Rest & Restore',                  // Description
  hormonalBasis: 'Estrogen low, Progesterone declining',  // Hormonal state
  workoutPhase: 'Power Phase',                    // Dr. Mindy Pelz workout
  nutritionApproach: 'Ketobiotic',                // Dr. Indy Kensington nutrition
  fastingType: 'Power Fasting',                   // Fasting approach
  workoutEmoji: '💪',                             // Workout phase emoji
  nutritionEmoji: '🥗',                           // Nutrition emoji
  fastingDetails: 'IF 13-15h',                    // Core recommendation
  startPercentage: 0.0,                           // Derived from day-based boundaries
  endPercentage: 0.179,                           // For visualization only
)
```

## The 5 Phases

| Phase | Days (28-day, ML=5) | Hormonal | Workout | Nutrition | Fasting |
|-------|------|----------|---------|-----------|---------|
| **Menstrual** | 1-5 | Estrogen ↓, Progesterone ↓ | Power 💪 | Ketobiotic 🥗 | Power ⏱️ |
| **Follicular** | 6-12 | Estrogen ↑ | Power 💪 | Ketobiotic 🥗 | Power ⏱️ |
| **Ovulation** | 12-16 | Estrogen ↑↑, LH surge | Manifestation ✨ | Hormone Feasting 🍲 | Manifestation ⏱️ |
| **Early Luteal** | 17-21 | Progesterone ↑ | Power 💪 | Ketobiotic 🥗 | Power ⏱️ |
| **Luteal** | 22-28 | Progesterone ↑↑ | Nurture 🌸 | Hormone Feasting 🍲 | Nurture ⏱️ |

## 28-Day Cycle: Day-by-Day Breakdown

Complete daily guide for a standard 28-day cycle with 5-day menstrual period:

| Day | Phase | Hormonal State | Diet Type | Fasting | Workout Type | Key Focus |
|-----|-------|---|---|---|---|---|
| **1** | 🩸 Menstrual | Estrogen ↓, Progesterone ↓ | Ketobiotic | IF 13-15h | Low-Impact | Recovery mode • Rest days ok |
| **2** | 🩸 Menstrual | Estrogen low | Ketobiotic | IF 13-15h | Low-Impact | Strength gentle • Iron-rich foods |
| **3** | 🩸 Menstrual | Estrogen low | Ketobiotic | IF 13-15h | Low-Impact | Gentle stretching • Self-care |
| **4** | 🩸 Menstrual | Estrogen rising slightly | Ketobiotic | IF 13-15h | Low-Impact | Light movement • Cramp relief |
| **5** | 🩸 Menstrual | Estrogen rising | Ketobiotic | IF 13-15h | Low-Impact | Energy returning • Last period day |
| **6** | 🌱 Follicular | Estrogen ↑ | Ketobiotic | IF 17h | Mid-Impact | Energy rising • HIIT effective |
| **7** | 🌱 Follicular | Estrogen rising | Ketobiotic | IF 17h | Mid-Impact | Sprint workouts • High intensity ok |
| **8** | 🌱 Follicular | Estrogen climbing | Ketobiotic | IF 17h | Mid-Impact | Peak fasting window • HIIT possible |
| **9** | 🌱 Follicular | Estrogen ↑ | Ketobiotic | IF 17h | Mid-Impact | Great for new projects • Confidence up |
| **10** | 🌱 Follicular | High estrogen | Ketobiotic | IF 17h | Mid-Impact | Maximum intensity possible |
| **11** | 🌱 Follicular | High estrogen | Ketobiotic | IF 17h | Mid-Impact | Best learning window • Lean proteins |
| **12** | 🌱 Follicular → 🌱 Ovulation* | Estrogen peak begins | Ketobiotic | IF 13h | Mid-Impact → Strength | Transition day • Pre-ovulation |
| **13** | ✨ Ovulation | Estrogen ↑↑ | Hormone Feasting | IF 13h | Strength Training | DO HARD THINGS • Peak confidence |
| **14** | ✨ Ovulation | LH surge (Ovulation Day) | Hormone Feasting | IF 13h | Strength Training | **PEAK DAY** • Max intensity • Fertile |
| **15** | ✨ Ovulation | Post-ovulation | Hormone Feasting | IF 13h | Strength Training | 5-day window continues • High energy |
| **16** | ✨ Ovulation | Estrogen high | Hormone Feasting | IF 13h | Strength Training | Still powerful • Last high-intensity day |
| **17** | 🌙 Early Luteal | Progesterone ↑ | Ketobiotic | IF 15h | Mid-Impact | Transition phase • Moderate intensity |
| **18** | 🌙 Early Luteal | Progesterone rising | Ketobiotic | IF 15h | Mid-Impact | Energy stable • Build endurance |
| **19** | 🌙 Early Luteal | Progesterone ↑ | Ketobiotic | IF 15h | Mid-Impact | Maintain strength • Listen to body |
| **20** | 🌙 Early Luteal | Progesterone climbing | Ketobiotic | IF 15h | Mid-Impact | Feel more grounded • Moderate pace |
| **21** | 🌙 Early Luteal | Progesterone ↑ | Ketobiotic | IF 15h | Mid-Impact | Last power phase day • Consistency |
| **22** | 🌙 Luteal | Progesterone ↑↑ | Hormone Feasting | No IF | Nurture | Switch to nourishing meals • Yoga ok |
| **23** | 🌙 Luteal | Progesterone peak | Hormone Feasting | No IF | Nurture | Eat 3x daily • Mood matters |
| **24** | 🌙 Luteal | Progesterone dominant | Hormone Feasting | No IF | Nurture | Elevated metabolism • Carbs welcome |
| **25** | 🌙 Luteal | High progesterone | Hormone Feasting | No IF | Nurture | Self-compassion meals • Rest days |
| **26** | 🌙 Luteal | Progesterone ↑↑ | Hormone Feasting | No IF | Nurture | PMS window • Gentle activity |
| **27** | 🌙 Luteal | Progesterone high → declining | Hormone Feasting | No IF | Nurture | Prioritize sleep • Support mood |
| **28** | 🌙 Luteal | Progesterone declining | Hormone Feasting | No IF | Nurture | Last cycle day • Prepare for menstrual |

**Day 12 Note:** Transition day - follows Follicular logic in morning, Ovulation logic in afternoon/evening as OD approaches.

## Comprehensive Cycle Timeline with Recommendations

### Adaptive Calculation (28-day cycle, menstrualLength=5)

```
ANCHOR POINTS:
- Day 1 = Start of menstruation (user input)
- Ovulation Day (OD) = Cycle Length - 14 = 14
- Luteal Length = 14 days (fixed reference)
```

### Phase-by-Phase Breakdown (NEW BOUNDARIES)

| Days (Adaptive Formula) | Hormonal Phase | Workout & Fasting Phase | Diet Guidance | Fasting Guidance | Recommendations & Tips |
|------|-------|---|---|---|---|
| **Day 1 → (ML-1)** | Menstrual (low estrogen & progesterone) | Power Phase 💪 | Low-Carb Gut-Support 🥗 | IF 13h | Gentle strength focus • Rest when needed • Iron-rich foods (spinach, red meat) • Keep fasts short • Gentle movement helps cramps |
| **Day ML** | Menstrual (low estrogen & progesterone) | Power Phase 💪 | Low-Carb Gut-Support 🥗 | IF 15h | Final recovery day • Easier fasting • Support body transition • Prepare for follicular energy rise |
| **Day (ML+1) → (ML+5)** | Follicular (estrogen rising) | Power Phase 💪 | Low-Carb Gut-Support 🥗 | IF 17h | Energy rising • HIIT & sprints effective • Lean proteins • Great time to start new projects • High intensity possible |
| **Day (ML+6) → (OD-2)** | Follicular→Ovulation Transition | Manifestation Phase ✨ | High-Carb Hormone Support 🍲 | IF 13h | Building momentum • Start strength & resistance • Increase carbs • Nutrient density peaks • Beginning of power window |
| **Day (OD-1) → (OD+1)** | Ovulation (estrogen peak, LH surge) | Manifestation Phase ✨ | High-Carb Hormone Support 🍲 | IF 13h | **DO HARD THINGS** • 3-day peak window • Max intensity possible • Confident & social • Carb-loading optimal • Nutrient absorption peaks • Celebrate this window |
| **Day (OD+2) → (OD+5)** | Early Luteal (progesterone rising) | Power Phase 💪 | Low-Carb Gut-Support 🥗 | IF 15h | Moderate-high intensity • Build endurance • Transition back to lower carbs • Maintain strength gained • Energy still good |
| **Day (OD+6) → CycleLength** | Late Luteal (progesterone dominant, PMS possible) | Nurture Phase 🌸 | High-Carb Hormone Support 🍲 | No fasting | Gentle activity (yoga, pilates, walking) • Elevated metabolism = more calories • Eat 3x daily or when hungry • Self-compassion meals • Support mood with nutrients • Prioritize sleep |

> **Legend:** ML = MenstrualLength (user input) | OD = Ovulation Day (OD = CycleLength - 14) | lutealLength = 14 (fixed) | **Follicular ends at (OD-2)** | **Ovulation is 3-day peak (OD-1 to OD+1)** | **Early Luteal is 4 days (OD+2 to OD+5)**

> **📌 NOTE:** This table assumes menstrualLength=5. See "Menstrual Length Variability" below for how phases adapt to different period lengths (3-7 days).

## Menstrual Length Variability

Your **menstrual length** completely shifts all phase boundaries. The table above is for a **5-day menstrual period**. Here's how it adapts:

### Short Menstrual (3 Days)
```
28-day cycle, menstrualLength=3, OD=14

Days 1-2:     MENSTRUAL (IF 13h)
Day 3:        MENSTRUAL (IF 15h)
Days 4-8:     FOLLICULAR (IF 17h)
Days 9-12:    Transition/Manifestation (IF 13h)
Days 13-15:   OVULATION (IF 13h, peak window)
Days 16-19:   EARLY LUTEAL (IF 15h)
Days 20-28:   LUTEAL (No IF)

⚠️ Impact: Energy rises faster, follicular phase lasts longer
```

### Standard Menstrual (5 Days) - TABLE ABOVE
```
28-day cycle, menstrualLength=5, OD=14
Days 1-4:     MENSTRUAL (IF 13h)
Day 5:        MENSTRUAL (IF 15h)
Days 6-10:    FOLLICULAR (IF 17h)
Days 11-12:   Transition/Manifestation (IF 13h)
Days 13-15:   OVULATION (IF 13h, peak window)
Days 16-19:   EARLY LUTEAL (IF 15h)
Days 20-28:   LUTEAL (No IF)
```

### Long Menstrual (7 Days)
```
28-day cycle, menstrualLength=7, OD=14

Days 1-6:     MENSTRUAL (IF 13h)
Day 7:        MENSTRUAL (IF 15h)
Days 8-12:    FOLLICULAR (IF 17h)
Days 13:      Transition/Manifestation (IF 13h)
Days 14-16:   OVULATION (IF 13h, peak window)
Days 17-20:   EARLY LUTEAL (IF 15h)
Days 21-28:   LUTEAL (No IF)
```
Days 12-16:   OVULATION → 5-day window (OD-2 to OD+2)
Days 17-21:   EARLY LUTEAL → 5 days (OD+3 to OD+7)
Days 22-28:   LUTEAL → Same (~7 days)

⚠️ Impact: Recovery phase lasts longer, less pre-ovulation energy days
```

## Late Luteal Scaling for Longer Cycles

The **PMS window** (late luteal) expands proportionally in longer cycles:

### 26-Day Cycle (menstrualLength=5)
```
OD = 26 - 14 = 12

Days 1-5:      MENSTRUAL
Days 6-10:     FOLLICULAR (OD-6 to OD-2)
Days 10-14:    OVULATION (5-day window: OD-2 to OD+2)
Days 15-19:    EARLY LUTEAL (OD+3 to OD+7)
Days 20-26:    LUTEAL (OD+8 to cycle end)

⚠️ Overall faster cycle: Each phase compressed by 2 days
```

### 28-Day Cycle (menstrualLength=5) - STANDARD
```
OD = 28 - 14 = 14

Days 1-5:      MENSTRUAL
Days 6-12:     FOLLICULAR (OD-8 to OD-2)
Days 12-16:    OVULATION (5-day window: OD-2 to OD+2)
Days 17-21:    EARLY LUTEAL (OD+3 to OD+7)
Days 22-28:    LUTEAL (OD+8 to cycle end)

⚠️ Standard timing (reference table above)
```

### 32-Day Cycle (menstrualLength=5)
```
OD = 32 - 14 = 18

Days 1-5:      MENSTRUAL
Days 6-16:     FOLLICULAR (OD-12 to OD-2)
Days 16-20:    OVULATION (5-day window: OD-2 to OD+2)
Days 21-25:    EARLY LUTEAL (OD+3 to OD+7)
Days 26-32:    LUTEAL (OD+8 to cycle end)

⚠️ Follicular phase stretched (11 days) • Ovulation hits later • Luteal phase extended
```

### 35-Day Cycle (menstrualLength=5)
```
OD = 35 - 14 = 21

Days 1-5:      MENSTRUAL
Days 6-19:     FOLLICULAR (OD-15 to OD-2)
Days 19-23:    OVULATION (5-day window: OD-2 to OD+2)
Days 24-28:    EARLY LUTEAL (OD+3 to OD+7)
Days 29-35:    LUTEAL (OD+8 to cycle end)

⚠️ Entire cycle delayed: Follicular is very long (14 days) • Ovulation late (Day 21) • Extra luteal days
```

**Key Insight:** The 5-day ovulation window **(OD-2 → OD+2)** is FIXED, but all other phases shift based on cycle length and menstrual length. This creates the "variable phase compressed/extended" effect. 📊

## Recalculated Phase Tables for Different Cycle Lengths

## Recalculated Phase Tables for Different Cycle Lengths

### 26-Day Cycle (menstrualLength=5, OD=12)

| Days | Phase | Hormonal State | Workout | Diet | Fasting | Recommendations |
|------|-------|---|---|---|---|---|
| 1-5 | Menstrual | Dropping → Lowest | Power 💪 | Ketobiotic 🥗 | IF 13-15h | Strength focus • Iron-rich foods • Rest days important |
| 6-10 | Follicular | Rising energy | Power 💪 | Ketobiotic 🥗 | IF 17h | HIIT effective • Peak fasting window • High intensity possible |
| 10-14 | Ovulation (5-day) | Peak hormones | Manifestation ✨ | Hormone Feasting 🍲 | IF 13h | **DO HARD THINGS** • Max intensity • Carbs + nutrients • Fertile window |
| 15-19 | Early Luteal | Progesterone ↑ | Power 💪 | Ketobiotic 🥗 | IF 15h | Moderate intensity • Build endurance • Maintain strength |
| 20-26 | Luteal & PMS | Progesterone peak | Nurture 🌸 | Hormone Feasting 🍲 | No IF | Yoga/pilates/walking • Rest days • 8-9h sleep • Eat 3x daily |

**Cycle Summary:** Fastest cycle • Follicular **compressed** (5 days) • Each phase tighter • More intense energy swings

---

### 32-Day Cycle (menstrualLength=5, OD=18)

| Days | Phase | Hormonal State | Workout | Diet | Fasting | Recommendations |
|------|-------|---|---|---|---|---|
| 1-5 | Menstrual | Dropping → Lowest | Power 💪 | Ketobiotic 🥗 | IF 13-15h | Strength focus • Iron-rich foods • Rest days important |
| 6-16 | Follicular | Rising energy | Power 💪 | Ketobiotic 🥗 | IF 17h | HIIT effective • Peak fasting capacity • Best time for new projects • High intensity |
| 16-20 | Ovulation (5-day) | Peak hormones | Manifestation ✨ | Hormone Feasting 🍲 | IF 13h | **DO HARD THINGS** • Max intensity • Confident & social • Carbs + nutrients |
| 21-25 | Early Luteal | Progesterone ↑ | Power 💪 | Ketobiotic 🥗 | IF 15h | Moderate intensity • Build endurance • Maintain strength • Listen to body |
| 26-32 | Luteal & PMS | Progesterone peak | Nurture 🌸 | Hormone Feasting 🍲 | No IF | Yoga/pilates/walking • 2-3 rest days • 8-9h sleep • Eat 3x daily • Self-compassion |

**Cycle Summary:** Follicular is **expanded** (11 days) • Ovulation later (Days 16-20) • Luteal extended (Days 26-32)

---

### 35-Day Cycle (menstrualLength=5, OD=21)

| Days | Phase | Hormonal State | Workout | Diet | Fasting | Recommendations |
|------|-------|---|---|---|---|---|
| 1-5 | Menstrual | Dropping → Lowest | Power 💪 | Ketobiotic 🥗 | IF 13-15h | Strength focus • Iron-rich foods • Rest days important |
| 6-19 | Follicular | Rising energy | Power 💪 | Ketobiotic 🥗 | IF 17h | HIIT effective • Peak fasting capacity • **Longest energy window** • High intensity |
| 19-23 | Ovulation (5-day) | Peak hormones | Manifestation ✨ | Hormone Feasting 🍲 | IF 13h | **DO HARD THINGS** • Max intensity • Confident & social • Carbs + nutrients |
| 24-28 | Early Luteal | Progesterone ↑ | Power 💪 | Ketobiotic 🥗 | IF 15h | Moderate intensity • Build endurance • Maintain strength • Listen to body |
| 29-35 | Luteal & PMS | Progesterone peak | Nurture 🌸 | Hormone Feasting 🍲 | No IF | Yoga/pilates/walking • 2-3 rest days • 8-9h sleep • Eat 3x daily • Self-compassion |

**Cycle Summary:** Follicular is **longest** (14 days) • Ovulation much later (Days 19-23) • Everything delayed • Longer PMS (Days 29-35)

---

### Key Takeaways Across Cycle Lengths

| Metric | 26-day | 28-day (std) | 32-day | 35-day |
|--------|--------|--------|--------|--------|
| **Follicular Days** | 6-10 (5 days) | 6-12 (7 days) | 6-16 (11 days) | 6-19 (14 days) |
| **Ovulation Days** | 10-14 (5-day) | 12-16 (5-day) | 16-20 (5-day) | 19-23 (5-day) |
| **Ovulation Window** | OD-2 to OD+2 | OD-2 to OD+2 | OD-2 to OD+2 | OD-2 to OD+2 |
| **Early Luteal Days** | 15-19 | 17-21 | 21-25 | 24-28 |
| **Luteal/PMS Days** | 20-26 | 22-28 | 26-32 | 29-35 |

**Bottom line:** The 5-day ovulation window **(OD-2 to OD+2)** is FIXED. But **follicular expands/contracts** based on cycle length, shifting when all other phases occur. Use your actual cycle length to find your PMS window and all phase timings! 🎯

## Adaptive Cycle Phases Prediction Table

This table shows how phases adapt based on your cycle length and menstrual length using day-based calculations:

**Formula:** `OvulationDay (OD) = CycleLength - 14` (fixed 14-day luteal reference)

### Universal Phase Boundaries (For ANY Cycle Length)

| Component | Formula | Description |
|-----------|---------|-------------|
| **Menstrual** | Day 1 → ML | Your period length (default 5 days) |
| **Follicular** | Day (ML+1) → (OD-2) | Rising energy window |
| **Ovulation** | Day (OD-2) → (OD+2) | **5-day power window** ✨ |
| **Early Luteal** | Day (OD+3) → (OD+7) | Transition phase (5 days) |
| **Late Luteal** | Day (OD+8) → CycleLength | PMS & restoration |

### Quick Reference: Phase Predictions by Cycle Length

| Cycle | ML=5 | OD | Menstrual | Follicular | Ovulation (5-day) | Early Luteal | Late Luteal |
|-------|------|----|----|----|----|----|----|
| **26-day** | 1-5 | 12 | 1-5 | 6-10 | **10-14** | 15-19 | 20-26 |
| **28-day** | 1-5 | 14 | 1-5 | 6-12 | **12-16** | 17-21 | 22-28 |
| **30-day** | 1-5 | 16 | 1-5 | 6-14 | **14-18** | 19-23 | 24-30 |
| **32-day** | 1-5 | 18 | 1-5 | 6-16 | **16-20** | 21-25 | 26-32 |
| **35-day** | 1-5 | 21 | 1-5 | 6-19 | **19-23** | 24-28 | 29-35 |

**📌 To use your own values:**
1. Enter your cycleLength and menstrualLength
2. Calculate: `OD = cycleLength - 14`
3. Apply the formulas above
4. Use day ranges for all guidance

### Find Your Phase Today

**Given:**
- Last Period Start: December 15, 2025
- Cycle Length: 28 days
- Menstrual Length: 5 days
- Today: December 30, 2025

**Calculate:**
```
Days since period start: 15 days
OD = 28 - 14 = 14
Current phase: Days 6-12 = FOLLICULAR 🌱
Next phase: Ovulation in 2 days (December 31-January 4)
```

**Your Guidance Today:**
- 🌱 **Phase:** Follicular (rising energy)
- 💪 **Workout:** Power Phase - HIIT & sprints effective
- 🥗 **Nutrition:** Ketobiotic - lean proteins, quality fats
- ⏱️ **Fasting:** IF 17h - peak fasting window!

### How Phase Calculations Work in Code

```dart
import '../utils/cycle_utils.dart';

// Simple function call
String phase = getCyclePhase(
  lastPeriodStart: DateTime(2025, 12, 15),
  cycleLength: 28,
  today: DateTime.now(),
  menstrualLength: 5,  // Your actual period length
);
// Returns: 'Follicular'

// Get ovulation day
int ovulationDay = getOvulationDay(28);  // Returns: 14

// Check if fertile window
bool isFertile = isFertileWindow(
  DateTime(2025, 12, 15),  // Last period
  28,                       // Cycle length
  DateTime.now(),          // Today
);
// Returns: true (Dec 30 is in days 12-16 window for 28-day cycle)

// Get all guidance for phase
Map<String, String> guidance = getPhaseGuidance('Follicular');
// Returns complete guidance map

// Get days until next phase
int daysUntilChange = getDaysUntilNextPhase(
  DateTime(2025, 12, 15),
  28,
  5,
  DateTime.now(),
);
// Returns: 2 (days until Ovulation starts)
```

### Key Points to Remember

✅ **OD (Ovulation Day)** = CycleLength - 14 (fixed luteal assumption)
✅ **3-Day Ovulation Peak** = (OD-1) to (OD+1) = Manifestation Phase peak
✅ **Manifestation Transition Zone** = (OD-2) with follicular ending = 2 days
✅ **Follicular ends at** (OD-2), NOT (OD-1)
✅ **Early Luteal is 4 days** = (OD+2) to (OD+5)
✅ **All other phases** shift based on your menstrual length
✅ **Follicular phase** expands/contracts with cycle length  
✅ **Your values** (cycle length & menstrual length) are the variables
✅ **Day-based boundaries** are single source of truth (NO percentages)

---

## How to Find YOUR Phase Boundaries

Use this formula with your actual values:

```
INPUTS (User Provides):
- cycleLength (e.g., 28 days)
- menstrualLength (e.g., 5 days, default 5)
- lutealLength = 14 (fixed reference)

CALCULATION:
ovulationDay = cycleLength - 14 (fixed luteal length)

PHASE BOUNDARIES (Day-Based, Not Percentage):
- Menstrual:     Day 1 → (ML-1) [IF 13h], Day ML [IF 15h]
- Follicular:    Day (ML+1) → (ML+5) [IF 17h]
- Manifestation: Day (ML+6) → (OD-2) [IF 13h, transition]
- Ovulation:     Day (OD-1) → (OD+1) [IF 13h, 3-day peak]
- Early Luteal:  Day (OD+2) → (OD+5) [IF 15h]
- Late Luteal:   Day (OD+6) → cycleLength [No IF]

EXAMPLE: 28-day cycle, menstrualLength=5
ovulationDay = 28 - 14 = 14

- Menstrual:     Days 1-4 (IF 13h) + Day 5 (IF 15h)
- Follicular:    Days 6-10 (IF 17h)
- Manifestation: Days 11-12 (IF 13h, transition zone)
- Ovulation:     Days 13-15 (IF 13h, 3-day peak window: OD-1 to OD+1)
- Early Luteal:  Days 16-19 (IF 15h)
- Late Luteal:   Days 20-28 (No IF)
```

## Recommendations by Phase

### 🩸 **MENSTRUAL** (Days 1-5, with substages)
**Days 1-4 (IF 13h):**
- Strength training (Power Phase) - 2-3x/week
- Rest days important
- Gentle stretching/yoga
- **Fasting:** IF 13h (1pm-2pm window)

**Day 5 (IF 15h):**
- Can extend fasting slightly
- Still gentle movement
- Iron-rich nutrition
- **Diet:** Low-Carb Gut-Support - lean proteins, iron-rich foods, green vegetables, healthy fats
- Focus: Recovery & restoration

### 🌱 **FOLLICULAR** (Days 6-10: IF 17h)
**What to Do:**
- High-intensity training (Power Phase continues) - 4-5x/week
- HIIT workouts effective now
- Sprint/strength focus
- **Fasting:** IF 17h - your peak fasting window! Body ready for extended fasts
- **Diet:** Low-Carb Gut-Support - maintain lean nutrition, calories from quality fats
- Focus: Build strength & endurance

### 🔶 **MANIFESTATION TRANSITION** (Days 11-12: IF 13h)
**What to Do:**
- Strength & resistance training - building intensity
- Transition from follicular to ovulation
- Start increasing carbs for peak performance
- **Fasting:** IF 13h - begin shorter windows
- **Diet:** High-Carb Hormone Support - increase carbs and calories
- Focus: Prepare for ovulation power window

### ✨ **OVULATION** (Days 13-15: IF 13h)
**What to Do:**
- Max performance workouts - PRs possible!
- Intense strength & cardio
- This is your "do hard things" 3-day peak window
- **Fasting:** IF 13h - shorter windows during peak (13:00-02:00)
- **Diet:** High-Carb Hormone Support - increase carbs, nutrient absorption peaks, eat more
- Focus: Peak performance & celebration

### 🌙 **EARLY LUTEAL** (Days 16-19: IF 15h)
**What to Do:**
- Moderate-high intensity (Power Phase returns) - 3-4x/week
- Transition to endurance over intensity
- Build stability while energy is good
- **Fasting:** IF 15h - medium fasting window (15:00-06:00)
- **Diet:** Low-Carb Gut-Support - return to lower carbs, quality proteins
- Focus: Maintain strength, transition meals

### 🌙 **LUTEAL** (Days 20-28: No fasting)
**What to Do:**
- Gentle/restorative workouts (Nurture Phase) - 2-3x/week
- Yoga, pilates, walking, restorative workouts
- Low-impact activities
- **Fasting:** NO intermittent fasting - eat 3 meals + snacks when hungry
- **Diet:** High-Carb Hormone Support - carbs, satisfying foods, self-compassion meals
- Focus: Restoration, self-care, mood support

## Why This Matters

### Menstrual Phase Adaptation
Your **menstrualLength** (user input) controls where phases start/end:
- Short period (3 days) → Follicular starts earlier
- Long period (7 days) → Follicular starts later
- The ENTIRE cycle adjusts proportionally

### Example: Different Cycle Lengths (ML=5)
```
26-day cycle:
  Menstrual: 1-5, Follicular: 6-10, Transition: 11, Ovulation: 12-14, 
  Early Luteal: 15-18, Luteal: 19-26

28-day cycle:
  Menstrual: 1-5, Follicular: 6-10, Transition: 11-12, Ovulation: 13-15,
  Early Luteal: 16-19, Luteal: 20-28

32-day cycle:
  Menstrual: 1-5, Follicular: 6-14, Transition: 15-16, Ovulation: 17-19,
  Early Luteal: 20-23, Luteal: 24-32

35-day cycle:
  Menstrual: 1-5, Follicular: 6-17, Transition: 18-19, Ovulation: 20-22,
  Early Luteal: 23-26, Luteal: 27-35
```

All recommendations scale adaptively! 📊

## Using Guidance Functions

All these functions pull from Phase model automatically:

```dart
import '../utils/cycle_utils.dart';

// Get current phase
String phase = getCyclePhase(lastPeriodStart, cycleLength, today);

// Get hormonal state
String hormonal = getHormonalBasis('Ovulation');  // "Estrogen peak, LH surge"

// Get workout phase
String workout = getWorkoutPhase('Ovulation');    // "Manifestation Phase"

// Get nutrition approach
String nutrition = getNutritionGuidance('Ovulation');  // "Hormone Feasting"

// Get fasting type
String fasting = getFastingPhase('Ovulation');    // "Manifestation Fasting"

// Get all at once
Map<String, String> guidance = getPhaseGuidance('Ovulation');
// Returns: {
//   'phase': 'Ovulation',
//   'hormonal': 'Estrogen peak, LH surge',
//   'workout': 'Manifestation Phase',
//   'nutrition': 'Hormone Feasting',
//   'fasting': 'Manifestation Fasting',
// }

// Get emojis
String workoutEmoji = getWorkoutPhaseEmoji('Manifestation Phase');  // "✨"
String nutritionEmoji = getNutritionPhaseEmoji('Hormone Feasting');  // "🍲"
```

## Calculating Current Phase

```dart
import '../utils/cycle_utils.dart';

DateTime lastPeriodStart = DateTime(2025, 12, 15);
int cycleLength = 28;
int menstrualLength = 5;  // User's actual period length
DateTime today = DateTime.now();

// Get current phase
String currentPhase = getCyclePhase(
  lastPeriodStart,
  cycleLength,
  today,
  menstrualLength: menstrualLength,  // Important!
);
// Returns: 'Ovulation', 'Menstrual', 'Follicular', etc.

// Then get all guidance
Map<String, String> todayGuidance = getPhaseGuidance(currentPhase);
```

## Dashboard Example

```dart
String currentPhase = _getCurrentPhase();  // 'Ovulation'
Map<String, String> guidance = getPhaseGuidance(currentPhase);

// Display
Text(guidance['hormonal'])      // "Estrogen peak, LH surge"
Text(guidance['workout'])       // "Manifestation Phase"
Text(guidance['nutrition'])     // "Hormone Feasting"
```

## Calendar Day Details Example

```dart
String dayPhase = _getCyclePhase(widget.date);  // 'Ovulation'
final phaseData = CyclePhases.findPhaseByName(dayPhase);  // Get Phase object

// Display phase data
Text(phaseData?.emoji ?? '')           // "✨"
Text(phaseData?.description ?? '')     // "Peak Energy"
Text(phaseData?.hormonalBasis ?? '')   // "Estrogen peak, LH surge"

// Get guidance
Map<String, String> guidance = getPhaseGuidance(dayPhase);
Text(guidance['workout'])              // "Manifestation Phase"
Text(getWorkoutPhaseEmoji('Manifestation Phase'))  // "✨"
```

## Common Tasks

### Update Menstrual Phase Data
Edit: `lib/models/phase.dart`
```dart
Phase(
  name: 'Menstrual',
  hormonalBasis: 'NEW VALUE',  // ← Change here
  workoutPhase: 'NEW VALUE',   // ← Change here
  // ... rest stays same
)
```
✅ All screens auto-update

### Add New Guidance Type
1. Add field to Phase class
2. Update all 5 phases with new data
3. Create getter function in cycle_utils
✅ Ready to use everywhere

### Use Phase Guidance in New Screen
```dart
import '../utils/cycle_utils.dart';

// Calculate phase
String phase = getCyclePhase(lastPeriodStart, cycleLength, today, 
  menstrualLength: menstrualLength);

// Get guidance
Map<String, String> guidance = getPhaseGuidance(phase);

// Display
Text(guidance['hormonal'])
Text(guidance['workout'])
Text(guidance['nutrition'])
```

## Phase Model Lookup

```dart
// Find by name
final phase = CyclePhases.findPhaseByName('Ovulation');
phase?.hormonalBasis   // "Estrogen peak, LH surge"
phase?.workoutPhase    // "Manifestation Phase"
phase?.nutritionApproach  // "Hormone Feasting"

// Get all phases
for (final phase in CyclePhases.phases) {
  print(phase.name);
  print(phase.hormonalBasis);
}
```

## Ovulation & Fertile Window

```dart
import '../utils/cycle_utils.dart';

// Ovulation day = Cycle Length - 14 (fixed luteal)
int ovulationDay = getOvulationDay(28);  // Day 14 for 28-day cycle

// Fertile window = 5 days before + ovulation day (6 days total)
bool isFertile = isFertileWindow(lastPeriodStart, cycleLength, today);
```

## Phase Boundaries (Day-Based, Not Percentage)

```
menstrualLength = 5 (user adjustable, default: 5)
cycleLength = 28 (user adjustable, default: 28)
lutealLength = 14 (fixed reference)
ovulationDay (OD) = cycleLength - 14 = 14

ADAPTIVE BY DAY:
Menstrual:    Days 1 → menstrualLength
Follicular:   Days (menstrualLength + 1) → (OD - 1)
Ovulation:    Days OD → (OD + 2)
Early Luteal: Days (OD + 3) → (OD + 6)
Luteal:       Days (OD + 7) → cycleLength

EXAMPLE (28-day cycle, menstrualLength=5):
Menstrual:    Days 1-5
Follicular:   Days 6-13
Ovulation:    Days 14-16
Early Luteal: Days 17-20
Luteal:       Days 21-28
```

## Files to Know

| File | Purpose |
|------|---------|
| `lib/models/phase.dart` | **Phase model (SSoT)** |
| `lib/utils/cycle_utils.dart` | Guidance functions + calculations |
| `lib/screens/dashboard_screen.dart` | Shows today's guidance |
| `lib/screens/calendar_screen.dart` | Shows phase + guidance per day |
| `PHASE_PREDICTIONS_GUIDE.md` | Full documentation |
| `SINGLE_SOURCE_OF_TRUTH_SUMMARY.md` | Implementation details |

## Testing Phase Data

```dart
void testAllPhasesComplete() {
  for (final phase in CyclePhases.phases) {
    assert(phase.name.isNotEmpty);
    assert(phase.hormonalBasis.isNotEmpty);
    assert(phase.workoutPhase.isNotEmpty);
    assert(phase.nutritionApproach.isNotEmpty);
    assert(phase.fastingType.isNotEmpty);
    assert(phase.workoutEmoji.isNotEmpty);
    assert(phase.nutritionEmoji.isNotEmpty);
  }
}
```

---

**Remember:** All phase guidance comes from ONE place. Update `lib/models/phase.dart` and everything else auto-updates! ✨
