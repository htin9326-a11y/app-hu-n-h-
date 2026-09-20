# Aujunpeak File Browser

SwiftUI file manager for iPhone, iOS 16+.

## Features
- Clean white/light UI
- Browse the app's Documents sandbox
- Import files from Apple's Files picker
- Search files
- Open folders
- Share files
- Supports `.3105` document declaration and `threeoneosfive://` URL scheme
- GitHub Actions build workflow

## Important iOS limitation
`Info.plist` cannot grant an app unrestricted access to every other app's sandbox. This project intentionally uses Apple's supported sandbox and document-provider APIs.

## GitHub build
The workflow installs XcodeGen, generates the Xcode project, and performs an unsigned device build. To produce an installable App Store/TestFlight IPA, configure Apple signing certificates and provisioning in GitHub Actions.
