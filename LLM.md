# LLM.md - EcoScanner Project Context (Current)

Last updated: 2026-02-17

## Project Overview

**EcoScanner** is a Swift Playground App Package (`.swiftpm`) built for the Apple Swift Student Challenge.
It uses camera + CoreML detection/classification to identify recyclable materials in real time, then teaches disposal and tracks user impact through XP, levels, streaks, and achievements.

- Format: Swift Playground App (`.swiftpm`)
- Language: Swift 6 (`swift-tools-version: 6.0`, `swiftLanguageModes: [.version("6")]`)
- Platform target: iOS `26.0`+
- Bundle ID: `com.devcelio.EcoScanner`
- App category: Education
- Main capability: Camera permission configured in `Package.swift`
- Accent color config: system default (`accentColor: nil` in `Package.swift`)

## Model Experiments Summary

- Current integrated baseline in app: **v3-litterati-v2** (`80/46/53` on train/val/test, `61` on extra test).
- Latest evaluated candidate (not promoted yet): **v3b-taco-v1 / MyObjectDetector 7** (`75/46/54` on fixed main test with 505 items, `12` on `extra_test_taco` with 144 items; evaluated on 2026-02-15).
- Historical experiment log, dataset mappings, upsides/downsides, and model checksums:
  - `MODEL_EXPERIMENTS.md`

## Current Architecture

```text
EcoScannerApp (@main, MyApp.swift)
  -> SwiftData ModelContainer (UserProfile, CollectionEntry)
  -> EnvironmentObjects:
     - CameraManager
     - WasteDetector
     - UserProfileManager

Main UI
  -> OnboardingView (5 pages, including visual tutorial image) if hasCompletedOnboarding == false
  -> GuidedFirstScanView if hasCompletedOnboarding == true and hasCompletedFirstGuidedScan == false
     - ScannerView(isGuidedMode: true)
     - GuidedCompletionView
  -> MainTabView (NavigationSplitView) otherwise
     - ScannerView
       - ScannerAVCaptureView (camera preview + frame updates)
       - ScannerGuideView (corner frame overlay)
       - FeedbackView (inline sheet-like overlay after collection)
     - EcoHistoryView
     - ProfileView
       - ProfileAchievementsSection (separated file)
     - Support sheets from drawer:
       - HelpTutorialView
       - CreditsView

Onboarding files:
  - OnboardingView.swift (main flow)
  - OnboardingPage.swift (model + static pages factory)
  - OnboardingCard.swift (card model)
  - GuidedFirstScanView.swift

Layers
  Core/
    - DesignSystem (colors, spacing, typography tokens)
    - Localization (code-based en + pt-BR dictionaries)
  Domain/
    - Models (WasteCategory, UserProfile, CollectionEntry, Achievement, MaterialFact)
  Services/
    - Camera/CameraManager
    - Detection/WasteDetector
    - Profile/UserProfileManager
  Resources/
    - Data/MaterialFacts.json
    - MLModel/EcoScanner.mlmodelc
    - Assets.xcassets (includes `TutorialImageEN`, `TutorialImagePT`)
```

## Data and Feature Flows

### 1) Detection Pipeline

```text
AVCaptureSession frames
  -> ScannerAVCaptureView.Coordinator.captureOutput(...)
  -> WasteDetector.onImageReceived(buffer:) (~5 FPS)
  -> VNCoreMLRequest (imageCropAndScaleOption: .scaleFill)
  -> multi-candidate scoring: 55% confidence + 15% area + 30% center proximity
  -> ROI: central 60% soft region (scoring weight, not hard filter)
  -> label mapping to WasteCategory
  -> focus lock: once a category gets 3 consistent hits, lock onto it
     - same-category updates allowed if IoU >= 0.30
     - different category breaks lock only if score margin > 0.20
     - lock auto-expires after 1.5s of no matching candidate
  -> confidence smoothing:
     - new display requires confidence >= 0.58 and 3 consistent hits
     - displayed result is kept while confidence >= 0.50
     - bounding box smoothed with alpha=0.25 (reset if IoU < 0.25)
     - clear after 5 missed frames
  -> @Published currentDetection
  -> ScannerView detection card + enabled scan button
```

**BOX toggle**: `debugBoundingBoxEnabled` is stored in `@AppStorage` by `ScannerView` and passed to `ScannerAVCaptureView` as a plain `Bool` prop (not `@AppStorage` in the `UIViewRepresentable` — that pattern fails because SwiftUI doesn't observe it as a view dependency). Toggling shows a restart alert since the camera layer needs reinitialization.

**Accent color**: Set in `Package.swift` as `.presetColor(.green)` to ensure NavigationSplitView selection highlight and all interactive elements use green instead of system blue.

### 2) Collection Pipeline

```text
User taps scan button
  -> WasteDetector.confirmDetection()
  -> UserProfileManager.recordCollection(category, confidence)
     - create CollectionEntry with streak multiplier
     - update profile XP/stats/streak/CO2
     - unlock achievements
     - persist in SwiftData
  -> MaterialFact.randomFact(for:)
  -> FeedbackView shown with result + fact + disposal guidance
  -> Level-up / achievement banners queued on scanner screen
```

### 3) Onboarding and Guided First Scan

```text
Launch
  -> OnboardingView (5 pages)
     - page 5 shows localized tutorial image (`TutorialImageEN` / `TutorialImagePT`)
  -> GuidedFirstScanView
     - user must complete one real scan in guided mode
     - FeedbackView dismiss triggers GuidedCompletionView
  -> MainTabView
```

### 4) History and Profile

- `EcoHistoryView`: filter chips by category, summary header, list of all entries.
- `ProfileView`: level progress, CO2 card, stats grid, adaptive achievements grid, level detail sheet, achievement detail sheet with progress bars.
- `HelpTutorialView`: practical recap + button to restart onboarding and guided first scan.
- `CreditsView`: datasets, repository, and social links.

### 5) Glass Effect Scope

Glass effects (`.glassEffect(.clear, ...)` and `GlassEffectContainer`) are used **only** in:
- `OnboardingView` — cards and category section
- `ScannerView` — interactive capsule buttons (`.scannerCapsuleClearInteractiveGlass()`)

All other views (Profile, History, Help, Credits) use manual `RoundedRectangle` backgrounds with `Color.white.opacity(0.06)` fill and `Color.surfaceStroke` border.

Modals (Levels sheet, Achievement popover) retain close buttons, `NavigationStack`, and dark toolbar with `Color.ecoInk` background.

### 6) Sidebar

`MainTabView` uses `.tint(.ecoPrimary)` on the sidebar `List` to ensure selected tab highlight matches the app's green accent color.

## Gamification (Current Rules)

### XP by Category

- plastic: 10
- glass: 15
- metal: 15
- paper: 10
- cardboard: 12
- electronic: 25
- biodegradable: 8
- textile: 20

### Streak Multiplier

Computed in `UserProfileManager.recordCollection`:

```swift
min(1.0 + Double(currentStreak) * 0.1, 2.0)
```

### Levels (8 total)

`EcoLevel` thresholds:

1. Eco Iniciante: 0 XP
2. Eco Aprendiz: 50 XP
3. Eco Coletor: 200 XP
4. Eco Guardiao: 500 XP
5. Eco Warrior: 1000 XP
6. Eco Heroi: 1800 XP
7. Eco Champion: 3000 XP
8. Eco Lenda: 5000 XP

### Achievements

- Total defined achievements: 19
- Requirement types:
  - total collections
  - per-category collections
  - streak days
  - CO2 saved
  - level reached

## SwiftData Schema

### UserProfile (`@Model`)

- `name: String`
- `totalXP: Int`
- `currentStreak: Int`
- `lastCollectionDate: Date?`
- `totalCollections: Int`
- `totalCO2Saved: Double`
- `unlockedAchievementIDs: [String]`

Derived values include `currentLevel`, `nextLevel`, `levelProgress`, `xpToNextLevel`, and streak updates via `updateStreak()`.

### CollectionEntry (`@Model`)

- `categoryRawValue: String`
- `confidence: Double`
- `xpEarned: Int`
- `co2Saved: Double`
- `timestamp: Date`

## ML Model Details (Current)

- Resource: `Resources/MLModel/EcoScanner.mlmodelc`
- Source model integrated: `/Users/celio/Documents/untitled folder/EcoScannerObjDetec.mlmodel`
- Source SHA-256: `ee295fd138815de11ed440011ecee16f26dba295d75c11417a0b632ae33ebc9d`
- Compiled payload size: ~7.0 MB
- Input: color image `299x299`, RGB (size-flexible)
- Output: `confidence` (boxes x classes) + `coordinates` (boxes x `[x,y,width,height]`)
- Model preview type: `objectDetector`
- Model classes: `BIODEGRADABLE`, `CARDBOARD`, `GLASS`, `METAL`, `PAPER`, `PLASTIC`
- Inference gate: `confidence >= 0.50` for candidate processing
- Display gate: `confidence >= 0.58` to show/switch category
- Keep gate: current category can stay visible down to `0.50` (hysteresis)
- Inference cadence: ~`5 FPS` (`minInferenceInterval = 0.20s`)
- Region of interest: central `60%` (`x:0.2, y:0.2, width:0.6, height:0.6`)

### Label Mapping Behavior

`WasteDetector.mapLabel` uses:

- explicit mapping for current object detector labels:
  - `PLASTIC` -> `.plastic`
  - `GLASS` -> `.glass`
  - `METAL` -> `.metal`
  - `PAPER` -> `.paper`
  - `CARDBOARD` -> `.cardboard`
  - `BIODEGRADABLE` -> `.biodegradable`
- unsupported labels are ignored (`nil`) to avoid scanner noise.
- a legacy fallback mapping for old classifier labels is kept for compatibility.

## Localization

`Core/Localization/Localization.swift` uses dictionary-based localization (no `.lproj` in this setup):

- Languages: English (`en`) and Portuguese Brazil (`ptBR`)
- Approx. key count: 450 total dictionary entries (both languages combined)
- Language decision: based on `Locale.preferredLanguages` + locale identifiers (more reliable on iPad/iPhone language settings)
- API:
  - `"some.key".localized`
  - `"some.key".localized(with: args...)`

## Resources Snapshot

- `Resources/MLModel/EcoScanner.mlmodelc`: ~7.1 MB
- `Resources/Data/MaterialFacts.json`: 24 facts, ~4 KB
- `Assets.xcassets`: ~5.8 MB
- Project folder total: ~19 MB
- Example full zip of folder: ~18 MB

## Build and Run

```bash
# Open in Xcode / Swift Playgrounds-compatible environment
open /Users/celio/Documents/untitled\ folder/EcoScanner.swiftpm

# Optional size check
cd /tmp
zip -qr EcoScanner.zip /Users/celio/Documents/untitled\ folder/EcoScanner.swiftpm
ls -lh EcoScanner.zip
```

## Student Challenge Fit (Current Status)

- Under 25 MB zipped: yes (well below limit in local check)
- Offline-friendly: yes (no network layer in code)
- Camera-first core loop: yes (scan -> collect -> feedback)
- Fast 3-minute core experience: yes (onboarding and first guided scan are short and lead directly to the main loop)

## Migration Notes from Old CLAUDE.md

Major changes that required this document update:

- Target platform changed from iOS 17 to iOS 26.
- Project structure is now fully layered (`Core/Domain/Services/Features/Resources`).
- App icon/resources changed (logo asset set now PNG-based in assets).
- Onboarding content and visuals were redesigned.
- Onboarding now has 5 pages and includes a dedicated visual tutorial page.
- After onboarding, first guided scan is mandatory once (`hasCompletedFirstGuidedScan` gate).
- Scanner UI now has:
  - custom guide frame
  - animated scan button
  - in-screen achievement/level-up banners
  - feedback overlay flow
- Drawer now includes Help and Credits entries.
- Help screen can restart onboarding + guided first scan.
- Help and Credits use `Color.ecoInk` background (aligned with History/Profile).
- Levels increased from 6 to 8, with new XP thresholds.
- Achievements expanded from 8 to 19.
- Material facts file currently has 24 entries.
- Localization content was expanded significantly.
- Localization language resolution now prioritizes preferred system languages.
- App accent color is now system default (`accentColor: nil`), and `AccentColor.colorset` is removed.
- `SupportingInfo.plist` is no longer a central config point for camera purpose; capability is declared in `Package.swift`.

## Maintenance Rule

Whenever gameplay rules, ML labels/mapping, platform target, or feature module structure changes, update this file in the same pull request so LLM context stays accurate.

## LLM Token Usage Directive (Mandatory)

When editing UI/UX code in this project, LLM agents must always prefer design tokens over hardcoded visual values.

### Required Rules

1. Do not introduce raw visual constants in feature views for:
   - spacing/padding/margins
   - font sizes
   - corner radius
   - line width/stroke
   - opacity/alpha
   - icon/view sizes
   - max widths/layout constraints
   - animation durations/damping/scale
   - shadows/blur
2. Use tokens from:
   - `Core/DesignSystem/DesignTokens.swift`
   - `Core/DesignSystem/Color+EcoScanner.swift`
3. If a needed token does not exist:
   - create a token in the correct category instead of hardcoding in a feature file;
   - keep the current naming/grouping style (`spacing`, `fontSize`, `borderRadius`, `lineWidth`, `iconSize`, `size`, `maxWidth`, `opacity`, `duration`, etc.).
4. Waste/material category colors must stay centralized in `Color+EcoScanner.swift` and be consumed through `WasteCategory.color` (no duplicated hex values in feature files).
5. Literal numbers are allowed only for business/domain constants (for example XP thresholds, CO2 factors, or model confidence gates), not for visual styling.

### Enforcement Hint

Before finalizing edits, run a quick search for visual hardcodes (examples: `cornerRadius: 16`, `opacity(0.8)`, `.font(.system(size: 24))`) and migrate them to tokens.
