# CellLab launch kit — US English

Style B was selected. The kit contains five iPhone screenshots and five separately captured iPad screenshots, with matching upload order. Marketing files are outside both shipping targets.

## Upload the screenshots

In App Store Connect, open **My Apps → CellLab → iOS App version 1.0 → English (U.S.) → App Previews and Screenshots**. Use Media Manager to select the display sizes below if necessary.

| Local folder | App Store Connect display set | PNG dimensions |
| --- | --- | --- |
| `iPhone/` | iPhone with Dynamic Island (medium display) | 1206 × 2622, portrait |
| `iPad/` | iPad 13-inch display | 2064 × 2752, portrait |

Upload these **five files from each folder**, in this exact order:

| Order | Filename (identical in both device folders) | Reason to download |
| --- | --- | --- |
| 1 | `01-Build-DNA.png` | Build a real strand and choose the next complementary base. |
| 2 | `02-Explore-an-Animal-Cell.png` | Tap organelles and connect their structures to their jobs. |
| 3 | `03-See-Cells-Divide.png` | Follow chromosome movement through the phases of mitosis. |
| 4 | `04-Meet-Your-Axolotl-Guide.png` | Listen to a friendly recorded explanation while exploring. |
| 5 | `05-Daily-Biology-Widget.png` | Bring small or medium daily-fact widgets to the Home Screen. |

The numbered images are finished upload assets. `Previews/` contains contact sheets for review. `Concepts/`, `Captures/`, `Artwork/`, and `Tools/` contain supporting material; upload only the numbered PNGs in the two device folders. The ZIP contains the upload assets, copy, instructions, and final previews.

Apple's current specifications require the medium-display iPhone set and a 13-inch iPad set for this app. The exported sizes above are accepted, with RGB color and no alpha channels. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

## Paste the listing copy

Use `AppStore-Listing.md`. Paste the field contents only, without Markdown headings or character-count notes.

- **App Information, English (U.S.):** Name and Subtitle.
- **iOS version 1.0, English (U.S.):** Promotional Text, Description, and Keywords.
- **App Privacy / version information:** Supply the owner details listed in `Owner-Inputs.md`.

`Listing-Fields.json` provides the same text as separate exact values. `Listing-Validation.json` records the field counts. The recommended name is **CellLab: Biology You Can Play**; confirm its availability in your App Store Connect account.

## What was verified

Real captures came from **iPhone 17 Pro** and **iPad Pro 13-inch (M5)** simulators running iOS/iPadOS 26.2. Six feature checks per device passed across focused capture runs:

1. Enter DNA replication from CellLab, unzip, stabilize, prime, build four DNA bases, proofread a mismatch, and select C for the next G template base.
2. Open Cell Structures and select Mitochondria; verify the diagram selection.
3. Select Metaphase and Anaphase in the mitosis carousel.
4. Select “Write the RNA,” start the recorded axolotl guide, verify Speaking/Stop, and stop it.
5. Place the real medium Home Screen widget, verify a fact appears, and tap back to CellLab.
6. Switch to the real small widget, verify its short fact appears, and tap back to CellLab.

The screenshots preserve actual UI and biology. The two mitosis phase cards are taken from separate real captures. The iPad DNA image uses close-ups of its actual diagram, color key, and action row. The large axolotl on image 4 is rendered from CellLab's existing vector artwork. The widget images are crops of real placed widgets, excluding unrelated Home Screen icons.

All ten exports were checked for dimensions, RGB color, absence of alpha, headline bounds, and recognizable feature text. Full-size images and the two contact sheets were visually checked for clipping, label readability, and order. The selected iPhone opening is byte-for-byte the approved B option. `Validation.json` contains the per-image results and SHA-256 hashes.

## Build and device limits

This marketing task used the existing current Simulator app build, installed and run on both devices. The isolated UI capture runner was compiled for the checks. A fresh full-project test build was stopped while Xcode scanned the audio library; this task did **not** produce a new Release archive or upload a build. The app and widget implementation and target membership were not changed.

The initial widget automation selected hidden/duplicate icons and then the iPad Dock icon; those capture attempts failed. The final widget checks select the visible Home Screen element and passed on both devices. The combined earlier iPhone scene run therefore records three passing scene checks and a superseded widget failure; the separate final widget JSON reports record the passing checks.

Before submitting, use your signed Release build on a physical supported iPhone/iPad to check speaker/headphone playback, touch interactions, and widget opening. Automatic local-midnight widget refresh and actual reminder delivery were not re-tested in this marketing task. Optional local reminders use a rolling window of up to 30 dates; if the app remains unopened longer than that window, alerts can pause until it opens again.

## Add the widget

Touch and hold an empty area of the Home Screen, choose **Edit → Add Widget**, search **CellLab**, choose the small or medium Daily Biology Fact widget, tap **Add Widget**, then **Done**. On supported OS versions, you can also touch and hold the CellLab icon and choose a widget size directly. Tapping either size opens the main CellLab page.

Checked against Apple's documentation on November 20, 2026.
