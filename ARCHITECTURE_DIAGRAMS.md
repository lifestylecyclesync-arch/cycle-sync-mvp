# Phase System - Visual Architecture

## Single Source of Truth Flow

```
INPUT (User Data)
├── Last Period Start Date
├── Cycle Length (default 28)
├── Menstrual Length (default 5)
└── Current Date
    │
    ├──────────────────────────────────┐
    │                                  │
    v                                  v
getCyclePhase()                   Ovulation Day
(day-based calculation)           = Cycle - 14
    │                                  │
    └──────────┬───────────────────────┘
              │
              v
    Phase Name String
    (e.g., "Ovulation")
    │
    └──────────────────────────────────┐
                                       │
                    ┌──────────────────┘
                    │
                    v
        CyclePhases.findPhaseByName()
                    │
                    v
    ┌───────────────────────────────────────────────┐
    │        Phase Object (Single Source)           │
    ├───────────────────────────────────────────────┤
    │ name: "Ovulation"                             │
    │ emoji: "✨"                                    │
    │ description: "Peak Energy"                    │
    │ hormonalBasis: "Estrogen peak, LH surge"      │ ← HORMONAL
    │ workoutPhase: "Manifestation Phase"           │ ← WORKOUT
    │ nutritionApproach: "Hormone Feasting"         │ ← NUTRITION
    │ fastingType: "Manifestation Fasting"          │ ← FASTING
    │ workoutEmoji: "✨"                            │
    │ nutritionEmoji: "🍲"                          │
    └───────────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┬──────────────┐
        │           │           │              │
        v           v           v              v
    Dashboard  Calendar    Suggestions    Other Screens
        │           │           │              │
    Shows:      Shows:      Shows:         Uses:
    • Hormonal  • Phase +    • Workout      • Guidance
    • Workout   • Guidance   • Nutrition    • Fasting
    • Nutrition • Fertile    • Fasting      • Details
              Window        Options
```

## Phase Model - Complete Data Structure

```
CyclePhases.phases = [
  
  ╔═══════════════════════════════════════════════════════════╗
  ║              MENSTRUAL (Days 1-5)                         ║
  ╠═══════════════════════════════════════════════════════════╣
  ║ emoji: 🩸                                                 ║
  ║ description: Rest & Restore                              ║
  ║ hormonalBasis: Estrogen low, Progesterone declining      ║
  ║ workoutPhase: Power Phase                   emoji: 💪    ║
  ║ nutritionApproach: Ketobiotic              emoji: 🥗    ║
  ║ fastingType: Power Fasting                               ║
  ╚═══════════════════════════════════════════════════════════╝
  
  ╔═══════════════════════════════════════════════════════════╗
  ║              FOLLICULAR (Days 6-12)                       ║
  ╠═══════════════════════════════════════════════════════════╣
  ║ emoji: 🌱                                                 ║
  ║ description: High Energy Day                             ║
  ║ hormonalBasis: Estrogen rising, FSH increasing           ║
  ║ workoutPhase: Power Phase (continued)      emoji: 💪    ║
  ║ nutritionApproach: Ketobiotic              emoji: 🥗    ║
  ║ fastingType: Power Fasting                               ║
  ╚═══════════════════════════════════════════════════════════╝
  
  ╔═══════════════════════════════════════════════════════════╗
  ║              OVULATION (Days 13-15)                       ║
  ╠═══════════════════════════════════════════════════════════╣
  ║ emoji: ✨                                                 ║
  ║ description: Peak Energy                                 ║
  ║ hormonalBasis: Estrogen peak, LH surge                   ║
  ║ workoutPhase: Manifestation Phase         emoji: ✨     ║
  ║ nutritionApproach: Hormone Feasting        emoji: 🍲    ║
  ║ fastingType: Manifestation Fasting                       ║
  ╚═══════════════════════════════════════════════════════════╝
  
  ╔═══════════════════════════════════════════════════════════╗
  ║              EARLY LUTEAL (Days 16-20)                    ║
  ╠═══════════════════════════════════════════════════════════╣
  ║ emoji: 🌙                                                 ║
  ║ description: Building Energy                             ║
  ║ hormonalBasis: Progesterone rising, estrogen stable      ║
  ║ workoutPhase: Power Phase (again)          emoji: 💪    ║
  ║ nutritionApproach: Ketobiotic              emoji: 🥗    ║
  ║ fastingType: Power Fasting                               ║
  ╚═══════════════════════════════════════════════════════════╝
  
  ╔═══════════════════════════════════════════════════════════╗
  ║              LUTEAL (Days 21-28)                          ║
  ╠═══════════════════════════════════════════════════════════╣
  ║ emoji: 🌙                                                 ║
  ║ description: Inward Focus                                ║
  ║ hormonalBasis: Progesterone dominant, metabolism elevated║
  ║ workoutPhase: Nurture Phase                emoji: 🌸    ║
  ║ nutritionApproach: Hormone Feasting        emoji: 🍲    ║
  ║ fastingType: Nurture Fasting                             ║
  ╚═══════════════════════════════════════════════════════════╝
]
```

## Guidance Functions - No Duplication

```
BEFORE (Hardcoded - Bad):
┌────────────────────────────────────┐
│ function getHormonalBasis(phase) {│
│   switch(phase) {                  │
│     case 'Menstrual':              │
│       return 'Estrogen low...';    │
│     case 'Follicular':             │
│       return 'Estrogen rising...'; │
│     ...                            │
│   }                                │
│ }                                  │
│                                    │
│ function getWorkoutPhase(phase) {  │
│   switch(phase) {                  │
│     case 'Menstrual':              │
│       return 'Power Phase';        │
│     case 'Follicular':             │
│       return 'Power Phase...';     │
│     ...                            │
│   }                                │
│ }                                  │
│                                    │
│ function getNutritionGuidance() {  │
│   // Similar switch...             │
│ }                                  │
│                                    │
│ function getFastingPhase() {       │
│   // Similar switch...             │
│ }                                  │
│                                    │
│ function getWorkoutPhaseEmoji() {  │
│   // Similar switch...             │
│ }                                  │
│                                    │
│ function getNutritionPhaseEmoji(){ │
│   // Similar switch...             │
│ }                                  │
│                                    │
│ MANY LINES OF CODE! Data spread    │
│ across multiple functions!         │
└────────────────────────────────────┘
         ↓ (Update nightmare!)
   Need to update 6+ places!


AFTER (Single Source - Good):
┌────────────────────────────────────────────┐
│        Phase Model (SINGLE SOURCE)        │
├────────────────────────────────────────────┤
│ Menstrual: {hormonal, workout, nutrition}  │
│ Follicular: {hormonal, workout, nutrition} │
│ Ovulation: {hormonal, workout, nutrition}  │
│ Early Luteal: {hormonal, workout, nutrition}│
│ Luteal: {hormonal, workout, nutrition}    │
└────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────┐
│   Simple Functions (NO switch statements)  │
├────────────────────────────────────────────┤
│ function getHormonalBasis(phase) {         │
│   return CyclePhases.findPhaseByName(phase)│
│     ?.hormonalBasis;                       │
│ }                                          │
│                                            │
│ function getWorkoutPhase(phase) {          │
│   return CyclePhases.findPhaseByName(phase)│
│     ?.workoutPhase;                        │
│ }                                          │
│                                            │
│ function getNutritionGuidance(phase) {     │
│   return CyclePhases.findPhaseByName(phase)│
│     ?.nutritionApproach;                   │
│ }                                          │
│ ... all similar, NO DUPLICATION!           │
└────────────────────────────────────────────┘
         ↓ (Update easily!)
   ONE place to update all!
```

## Update Flow - Simplicity

```
UPDATE SCENARIO: Need to change Ovulation workout phase

┌─────────────────────────────────────┐
│  Old Way (Before SSoT)              │
├─────────────────────────────────────┤
│ 1. Find switch in getWorkoutPhase() │
│ 2. Update 'Ovulation' case          │
│ 3. Check if getWorkoutPhaseEmoji()  │
│    also needs update                │
│ 4. Check all screens for hardcoded  │
│    values                           │
│ 5. Test all scenarios               │
│ 6. Risk: Missed updates = bugs      │
│ TOTAL: 5-6 places to check          │
└─────────────────────────────────────┘
              vs
┌─────────────────────────────────────┐
│  New Way (With SSoT)                │
├─────────────────────────────────────┤
│ 1. Edit Phase.dart                  │
│ 2. Find Ovulation phase             │
│ 3. Update workoutPhase & emoji      │
│ 4. Update workoutEmoji if needed    │
│ 5. Save                             │
│ 6. ALL screens auto-updated ✅      │
│ TOTAL: 1 place to change!           │
└─────────────────────────────────────┘
```

## Information Flow Diagram

```
                    ┌─────────────┐
                    │  User Input │
                    │ • Period    │
                    │ • Cycle Len │
                    │ • Menstrual │
                    └──────┬──────┘
                           │
                    ┌──────v──────┐
                    │ getCyclePhase│
                    │  (day-based) │
                    └──────┬──────┘
                           │
                           v
                    ┌─────────────┐
                    │ Phase Name  │
                    │ (String)    │
                    └──────┬──────┘
                           │
                    ┌──────v──────────────────┐
                    │ CyclePhases             │
                    │ .findPhaseByName()      │
                    └──────┬──────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           v               v               v
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │ Hormonal   │  │ Workout    │  │ Nutrition  │
    │ State      │  │ Phase      │  │ Approach   │
    ├────────────┤  ├────────────┤  ├────────────┤
    │ Estrogen   │  │ Power      │  │ Ketobiotic │
    │ peak       │  │ Manifest.  │  │ Feasting   │
    │ LH surge   │  │ Nurture    │  │            │
    └────────────┘  └────────────┘  └────────────┘
           │               │               │
           └───────────────┼───────────────┘
                           │
                ┌──────────v──────────┐
                │   UI Screens        │
                ├─────────────────────┤
                │ • Dashboard         │
                │ • Calendar          │
                │ • Day Details       │
                │ • Suggestions       │
                └─────────────────────┘
```

## Phase Boundaries - Adaptive

```
User Input:
  cycleLength = 28 (variable)
  menstrualLength = 5 (variable)
  lutealLength = 14 (fixed reference)

Calculation:
  ovulationDay = cycleLength - lutealLength
              = 28 - 14
              = 14

Phase Ranges:
  ├─ Menstrual:    Days 1 → menstrualLength (1→5)
  ├─ Follicular:   Days (menstrualLength+1) → (OD-1)      (6→13)
  ├─ Ovulation:    Days OD → (OD+2)                       (14→16)
  ├─ Early Luteal: Days (OD+3) → (OD+6)                   (17→20)
  └─ Luteal:       Days (OD+7) → cycleLength              (21→28)

Result:
  ✅ Adapts to user's cycle length
  ✅ Adapts to user's menstrual length
  ✅ Fixed luteal reference (14) ensures ovulation consistency
```

## No Hardcoded Switch Statements

```
❌ BAD (Old Way):
switch(phase) {
  case 'Menstrual': return 'Power Phase';
  case 'Follicular': return 'Power Phase (continued)';
  case 'Ovulation': return 'Manifestation Phase';
  case 'Early Luteal': return 'Power Phase (again)';
  case 'Luteal': return 'Nurture Phase';
  default: return 'Unknown';
}

✅ GOOD (New Way):
final phaseData = CyclePhases.findPhaseByName(phase);
return phaseData?.workoutPhase ?? 'Unknown';

Benefit: Update Phase model → everywhere updates!
```

## File Update Locations

```
When you need to change phase guidance:

┌────────────────────────────────┐
│ ONLY edit: lib/models/phase.dart│
│                                │
│ Find: CyclePhases.phases[...]  │
│ Update: Any field              │
│ Save                           │
│                                │
│ Result:                        │
│ ✅ Dashboard updated           │
│ ✅ Calendar updated            │
│ ✅ Day Details updated         │
│ ✅ Suggestions updated         │
│ ✅ All functions updated       │
│                                │
│ NO other files need changes!   │
└────────────────────────────────┘
```

## Extension Example

```
Want to add "Sleep Quality" guidance?

1. Add to Phase class:
   final String sleepQuality;

2. Update all 5 phases:
   sleepQuality: 'Prioritize recovery',
   sleepQuality: 'Optimize for early rising',
   ... etc

3. Create function:
   String getSleepQuality(String phase) {
     return CyclePhases.findPhaseByName(phase)
       ?.sleepQuality ?? 'Sleep normally';
   }

4. Use everywhere:
   String quality = getSleepQuality(currentPhase);

✅ Done! No duplicate logic, SSoT maintained!
```

---

**Architecture Philosophy:**  
Data in one place → Functions pull from it → UI displays it  
Change data → Everything updates automatically ✨
