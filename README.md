# TestBinaryDependency

Testing XCFramework signature updates from Apple Distribution to local certificate and back.

## Purpose

This repository demonstrates and tests Xcode's behavior when updating binary dependency signatures, specifically transitioning from Apple Distribution certificates to self-signed certificates and back.

## Project Structure

```
TestBinaryDependency/
├── Sources/TestLibrary/      # Library source code
├── Scripts/
│   ├── setup.sh              # Environment setup and certificate creation
│   ├── build_xcframework.sh  # Build XCFramework without signing
│   ├── sign_and_release.sh   # Sign and create GitHub release
│   └── test_all_releases.sh  # Run all three releases
├── Package.swift             # SPM manifest (updated per release)
└── build/                    # Build artifacts (gitignored)
```

## Quick Start

### 1. Setup and Run All Tests

```bash
# Clone the repository
git clone https://github.com/OdNairy/TestBinaryDependency.git
cd TestBinaryDependency

# Run all releases at once
./Scripts/test_all_releases.sh
```

This will:
1. Run setup (create self-signed certificate)
2. Build the XCFramework
3. Create three releases:
   - v1.0.0: Signed with Apple Distribution
   - v1.0.1: Signed with self-signed certificate
   - v1.0.2: Signed with Apple Distribution (round trip)

### 2. Manual Step-by-Step

```bash
# Step 1: Setup environment
./Scripts/setup.sh

# Step 2: Build XCFramework
./Scripts/build_xcframework.sh

# Step 3: Create releases individually
./Scripts/sign_and_release.sh 1.0.0 APPLE "Apple Distribution signature"
./Scripts/sign_and_release.sh 1.0.1 SELF "Self-signed certificate"
./Scripts/sign_and_release.sh 1.0.2 APPLE "Back to Apple Distribution"
```

## Testing in Your Project

### 1. Create a New iOS App

Create a new iOS project in Xcode.

### 2. Add Package Dependency

1. File → Add Package Dependencies
2. Enter: `https://github.com/OdNairy/TestBinaryDependency.git`
3. Select version: 1.0.0

### 3. Use the Library

```swift
import TestLibrary

let library = TestLibrary()
print(library.greet(name: "World"))
// Output: Hello, World! This is TestLibrary v1.0.0
```

### 4. Test Signature Changes

1. **Initial state (v1.0.0)**: Build and run - should work with Apple Distribution signature
2. **Update to v1.0.1**:
   - File → Packages → Update to Latest Package Versions
   - Or manually change version in Package.swift to 1.0.1
   - Build and observe behavior with self-signed certificate
3. **Update to v1.0.2**:
   - Update package version to 1.0.2
   - Build and observe behavior switching back to Apple Distribution

## Expected Behaviors

### When updating from Apple Distribution to Self-Signed (v1.0.0 → v1.0.1):
- Xcode may show code signing warnings
- macOS may prompt to allow the unsigned framework
- Build may fail with "code signature verification failed"
- May need to allow in System Settings → Privacy & Security
- SPM cache may need clearing

### When updating back to Apple Distribution (v1.0.1 → v1.0.2):
- Should restore normal behavior
- No security prompts expected
- Build should succeed without warnings

## Troubleshooting

### Clear SPM Cache
```bash
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
swift package resolve
```

### Verify Signatures
```bash
# Check signature of a specific release
codesign -dv --verbose=4 path/to/TestLibrary.xcframework
```

### Check Certificate IDs
```bash
# List available certificates
security find-identity -v -p codesigning
```

## Scripts Reference

### setup.sh
- Creates self-signed certificate for testing
- Verifies GitHub CLI authentication
- Saves certificate IDs to config.sh

### build_xcframework.sh
- Builds for iOS device (arm64)
- Builds for iOS simulator (arm64, x86_64)
- Creates XCFramework without signing

### sign_and_release.sh
Arguments: `<version> <cert_id> <description>`
- Signs XCFramework with specified certificate
- Creates ZIP archive
- Calculates checksum
- Updates Package.swift
- Creates GitHub release

### test_all_releases.sh
- Runs complete test cycle
- Creates all three releases automatically
- Displays summary and instructions

## Requirements

- Xcode 14.0+
- macOS 12.0+
- GitHub CLI (`gh`) authenticated
- Valid Apple Developer certificates (or use self-signed for testing)

## Notes

- This is a test repository for demonstrating signature behavior
- The library itself is minimal and for testing purposes only
- Releases are created as GitHub releases with binary artifacts
- Each release updates Package.swift to point to the new binary

## License

MIT - This is a test project for educational purposes.