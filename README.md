# kKr

A SwiftUI iPhone app created with kKr from the "Blank SwiftUI" template.

## Build and install

1. In kKr open this repository, then tap the ▶️ button (Actions).
2. Tap **Run** next to "Build Unsigned IPA" and wait for the green check mark.
3. Open the finished run, download the artifact and unzip it in the Files app to get the .ipa file.
4. Install the .ipa with SideStore or AltStore. It is unsigned, so it has to be signed with your Apple ID.

## Files

- `project.yml`: describes the Xcode project. XcodeGen builds the project from it.
- `.github/workflows/build.yml`: the build recipe that GitHub runs on a Mac in the cloud.
- `Finance/`: the app's source code. Every Swift file in here is part of the app.
- `Finance/Theme.swift`: the colors of the app.
- `LEARN.md`: small experiments to try.

Each build uses GitHub Actions minutes. Private repositories on a free plan can run out quickly.