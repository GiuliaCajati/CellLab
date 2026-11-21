# CellLab

A native iPhone and iPad biology app with interactive lessons, hands-on games, and an axolotl audio guide.

## Open the project

Open `CellLab.xcodeproj` in Xcode and select the `CellLab` scheme. The project currently targets iOS/iPadOS 26.2 and includes a Daily Biology Fact WidgetKit extension.

The checked-in project uses the installed iOS SDK. To meet Apple's April 2027 submission requirement, install Xcode 27 or later, build and test with its iOS 27 SDK, and create a new archive. The build SDK and minimum supported OS are separate settings.

## Project layout

- `CellLab/`: SwiftUI app, lessons, games, artwork, and bundled offline audio.
- `CellLabDailyFactsWidget/`: Home Screen widget.
- `SharedFacts/`: Shared fact model and deterministic date selector.
- `CellLab/daily-facts.json`: Canonical collection of 69 biology facts and sources.
- `CellLabTests/` and `CellLabUITests/`: Unit and interface tests.
- `Tools/`: Local narration generation and supporting tools; model caches and virtual environments are ignored.
- `Docs/`: Feature handoff notes.
- `Marketing/AppStore/en-US/`: App Store screenshots, copy, creative assets, and upload instructions.

Audio recordings are bundled for offline use. The local generation scripts use Kokoro; see each script's help and the narration guides for details.
