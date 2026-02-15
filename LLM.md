# LLM.md - EcoScanner Project Context (Current)

Last updated: 2026-02-15

## Project Overview

**EcoScanner** is a Swift Playground App Package (`.swiftpm`) built for the Apple Swift Student Challenge.
It uses camera + CoreML classification to identify recyclable materials in real time, then teaches disposal and tracks user impact through XP, levels, streaks, and achievements.

- Format: Swift Playground App (`.swiftpm`)
- Language: Swift 6 (`swift-tools-version: 6.0`, `swiftLanguageModes: [.version("6")]`)
- Platform target: iOS `26.0`+
- Bundle ID: `com.devcelio.EcoScanner`
- App category: Education
- Main capability: Camera permission configured in `Package.swift`

## Current Architecture

```text
EcoScannerApp (@main, MyApp.swift)
  -> SwiftData ModelContainer (UserProfile, CollectionEntry)
  -> EnvironmentObjects:
     - CameraManager
     - WasteDetector
     - UserProfileManager

Main UI
  -> OnboardingView (4 pages) if hasCompletedOnboarding == false
  -> MainTabView (NavigationSplitView) otherwise
     - ScannerView
       - ScannerAVCaptureView (camera preview + frame updates)
       - ScannerGuideView (corner frame overlay)
       - FeedbackView (inline sheet-like overlay after collection)
     - EcoHistoryView
     - ProfileView
       - ProfileAchievementsSection (separated file)

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
```

## Data and Feature Flows

### 1) Detection Pipeline

```text
AVCaptureSession frames
  -> ScannerAVCaptureView.Coordinator.captureOutput(...)
  -> WasteDetector.onImageReceived(buffer:)
  -> VNCoreMLRequest
  -> top classification (confidence >= 0.3)
  -> label mapping to WasteCategory
  -> @Published currentDetection
  -> ScannerView detection card + enabled scan button
```

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

### 3) History and Profile

- `EcoHistoryView`: filter chips by category, summary header, list of all entries.
- `ProfileView`: level progress, CO2 card, stats grid, adaptive achievements grid, level detail sheet, achievement detail sheet with progress bars.

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
- Size on disk: ~196 KB
- Input: color image `299x299`, BGR
- Output: `target` (label string) + `targetProbability` dictionary
- Inference gate: `confidence >= 0.50` for candidate processing
- Display gate: `confidence >= 0.58` to show/switch category
- Keep gate: current category can stay visible down to `0.50` (hysteresis)
- Inference cadence: ~`5 FPS` (`minInferenceInterval = 0.20s`)
- Region of interest: central `60%` (`x:0.2, y:0.2, width:0.6, height:0.6`)
- Class labels in metadata:
  - `battery`, `biological`, `brown-glass`, `cardboard`, `clothes`, `green-glass`, `metal`, `paper`, `plastic`, `shoes`, `trash`, `white-glass`

### Label Mapping Behavior

`WasteDetector.mapLabel` uses:

- explicit mapping for all current model labels:
  - `plastic` -> `.plastic`
  - `glass`, `green-glass`, `brown-glass`, `white-glass` -> `.glass`
  - `metal` -> `.metal`
  - `paper` -> `.paper`
  - `cardboard` -> `.cardboard`
  - `battery` -> `.electronic`
  - `biological` -> `.biodegradable`
  - `clothes`, `shoes` -> `.textile`
  - `trash` -> ignored (`nil`, non-recyclable)
- plus a keyword fallback for legacy/free-form labels.

## Localization

`Core/Localization/Localization.swift` uses dictionary-based localization (no `.lproj` in this setup):

- Languages: English (`en`) and Portuguese Brazil (`ptBR`)
- Approx. key count: 374 total dictionary entries (both languages combined)
- API:
  - `"some.key".localized`
  - `"some.key".localized(with: args...)`

## Resources Snapshot

- `Resources/MLModel/EcoScanner.mlmodelc`: ~196 KB
- `Resources/Data/MaterialFacts.json`: 24 facts, ~4 KB
- `Assets.xcassets`: ~312 KB
- Project folder total: ~1.3 MB
- Example full zip of folder (including git metadata): ~1.0 MB

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
- Fast 3-minute core experience: yes (onboarding can be skipped, scanner flow is immediate)

## Migration Notes from Old CLAUDE.md

Major changes that required this document update:

- Target platform changed from iOS 17 to iOS 26.
- Project structure is now fully layered (`Core/Domain/Services/Features/Resources`).
- App icon/resources changed (logo asset set now PNG-based in assets).
- Onboarding content and visuals were redesigned.
- Scanner UI now has:
  - custom guide frame
  - animated scan button
  - in-screen achievement/level-up banners
  - feedback overlay flow
- Levels increased from 6 to 8, with new XP thresholds.
- Achievements expanded from 8 to 19.
- Material facts file currently has 24 entries.
- Localization content was expanded significantly.
- `SupportingInfo.plist` is no longer a central config point for camera purpose; capability is declared in `Package.swift`.

## Maintenance Rule

Whenever gameplay rules, ML labels/mapping, platform target, or feature module structure changes, update this file in the same pull request so LLM context stays accurate.
