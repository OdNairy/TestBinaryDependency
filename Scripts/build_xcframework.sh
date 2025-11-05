#!/bin/bash

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

echo "=== Building XCFramework ==="
echo ""

# Framework configuration
FRAMEWORK_NAME="TestLibrary"
SCHEME_NAME="TestLibrary"
BUILD_DIR="$PROJECT_ROOT/build"
XCFRAMEWORK_PATH="$BUILD_DIR/${FRAMEWORK_NAME}.xcframework"

# Clean previous builds
print_info "Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Generate Xcode project if needed
if [ ! -d "$PROJECT_ROOT/TestLibrary.xcodeproj" ]; then
    print_info "Generating Xcode project with XcodeGen..."
    cd "$PROJECT_ROOT"
    xcodegen generate
fi

# Build for iOS Device (arm64)
print_info "Building for iOS Device (arm64)..."
xcodebuild archive \
  -project "$PROJECT_ROOT/TestLibrary.xcodeproj" \
  -scheme "$SCHEME_NAME" \
  -archivePath "$BUILD_DIR/ios-device.xcarchive" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO 2>&1 | grep -E "^\*\*|error:|warning:|^$" || true

if [ ! -d "$BUILD_DIR/ios-device.xcarchive" ]; then
    print_error "Failed to build for iOS device"
    exit 1
fi
print_success "iOS Device build completed"

# Build for iOS Simulator (arm64, x86_64)
print_info "Building for iOS Simulator..."
xcodebuild archive \
  -project "$PROJECT_ROOT/TestLibrary.xcodeproj" \
  -scheme "$SCHEME_NAME" \
  -archivePath "$BUILD_DIR/ios-simulator.xcarchive" \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  EXCLUDED_ARCHS="" 2>&1 | grep -E "^\*\*|error:|warning:|^$" || true

if [ ! -d "$BUILD_DIR/ios-simulator.xcarchive" ]; then
    print_error "Failed to build for iOS Simulator"
    exit 1
fi
print_success "iOS Simulator build completed"

# Check if frameworks exist
DEVICE_FRAMEWORK="$BUILD_DIR/ios-device.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
SIMULATOR_FRAMEWORK="$BUILD_DIR/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"

# If frameworks are not in expected location, try alternative locations
if [ ! -d "$DEVICE_FRAMEWORK" ]; then
    print_info "Framework not found at expected location, searching..."
    DEVICE_FRAMEWORK=$(find "$BUILD_DIR/ios-device.xcarchive" -name "${FRAMEWORK_NAME}.framework" -type d | head -1)
    if [ -z "$DEVICE_FRAMEWORK" ]; then
        print_error "Cannot find device framework"
        exit 1
    fi
    print_info "Found device framework at: $DEVICE_FRAMEWORK"
fi

if [ ! -d "$SIMULATOR_FRAMEWORK" ]; then
    print_info "Framework not found at expected location, searching..."
    SIMULATOR_FRAMEWORK=$(find "$BUILD_DIR/ios-simulator.xcarchive" -name "${FRAMEWORK_NAME}.framework" -type d | head -1)
    if [ -z "$SIMULATOR_FRAMEWORK" ]; then
        print_error "Cannot find simulator framework"
        exit 1
    fi
    print_info "Found simulator framework at: $SIMULATOR_FRAMEWORK"
fi

# Create XCFramework
print_info "Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$DEVICE_FRAMEWORK" \
  -framework "$SIMULATOR_FRAMEWORK" \
  -output "$XCFRAMEWORK_PATH"

if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    print_error "Failed to create XCFramework"
    exit 1
fi

# Verify XCFramework structure
print_info "Verifying XCFramework..."
if [ -f "$XCFRAMEWORK_PATH/Info.plist" ]; then
    print_success "XCFramework structure verified"

    # Display framework info
    echo ""
    echo "XCFramework Info:"
    echo "-----------------"
    # List available architectures
    find "$XCFRAMEWORK_PATH" -name "*.framework" -type d | while read framework; do
        ARCH_INFO=$(lipo -info "$framework/$(basename "$framework" .framework)" 2>/dev/null || echo "Binary not found")
        echo "  $(basename "$(dirname "$framework")"): $ARCH_INFO"
    done
else
    print_error "XCFramework structure is invalid"
    exit 1
fi

echo ""
print_success "XCFramework created successfully at:"
echo "  $XCFRAMEWORK_PATH"
echo ""
echo "Next steps:"
echo "1. Sign the framework using: ./Scripts/sign_and_release.sh"
echo "2. Or run all releases using: ./Scripts/test_all_releases.sh"