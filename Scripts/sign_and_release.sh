#!/bin/bash

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source configuration if exists
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }
print_step() { echo -e "${BLUE}→${NC} $1"; }

# Check arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <version> <cert_identity> <description> [--no-version]"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.0 \"884983514A...\" \"Apple Distribution signature\""
    echo "  $0 1.0.1 \"SELF_SIGNED_ID\" \"Self-signed certificate\""
    echo "  $0 2.0.0 \"SELF_SIGNED_ID\" \"Self-signed certificate\" --no-version"
    echo ""
    echo "Options:"
    echo "  --no-version    Don't include version in XCFramework filename"
    echo ""
    echo "Available certificate IDs from config:"
    echo "  Apple: $APPLE_CERT_ID"
    echo "  Self-signed: $SELF_SIGNED_CERT_ID"
    exit 1
fi

VERSION="$1"
CERT_ID="$2"
DESCRIPTION="$3"
NO_VERSION_IN_FILENAME="${4:-}"

# Replace placeholder with actual certificate ID if needed
if [ "$CERT_ID" == "APPLE" ]; then
    CERT_ID="$APPLE_CERT_ID"
elif [ "$CERT_ID" == "SELF" ]; then
    CERT_ID="$SELF_SIGNED_CERT_ID"
fi

echo "=== Signing and Releasing v$VERSION ==="
echo ""
print_info "Version: $VERSION"
print_info "Certificate: $CERT_ID"
print_info "Description: $DESCRIPTION"
echo ""

# Paths
BUILD_DIR="$PROJECT_ROOT/build"
XCFRAMEWORK_PATH="$BUILD_DIR/${FRAMEWORK_NAME}.xcframework"

# Determine paths based on versioning flag
if [ "$NO_VERSION_IN_FILENAME" == "--no-version" ]; then
    VERSIONED_PATH="$BUILD_DIR/${FRAMEWORK_NAME}.xcframework"
    ZIP_PATH="$BUILD_DIR/${FRAMEWORK_NAME}.xcframework.zip"
    ZIP_FILENAME="${FRAMEWORK_NAME}.xcframework.zip"
else
    VERSIONED_PATH="$BUILD_DIR/${FRAMEWORK_NAME}-v${VERSION}.xcframework"
    ZIP_PATH="$BUILD_DIR/${FRAMEWORK_NAME}-v${VERSION}.xcframework.zip"
    ZIP_FILENAME="${FRAMEWORK_NAME}-v${VERSION}.xcframework.zip"
fi

# Check if XCFramework exists
if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    print_error "XCFramework not found at: $XCFRAMEWORK_PATH"
    print_info "Please run ./Scripts/build_xcframework.sh first"
    exit 1
fi

# Step 1: Copy XCFramework to versioned/target path
if [ "$NO_VERSION_IN_FILENAME" == "--no-version" ]; then
    print_step "Using XCFramework without version in filename..."
    # No need to copy, just use the original path
else
    print_step "Copying XCFramework to versioned path..."
    rm -rf "$VERSIONED_PATH"
    cp -R "$XCFRAMEWORK_PATH" "$VERSIONED_PATH"
    print_success "Copied to: $VERSIONED_PATH"
fi

# Step 2: Sign the XCFramework itself
print_step "Signing XCFramework..."
codesign --force --sign "$CERT_ID" --timestamp "$VERSIONED_PATH" 2>&1 | grep -E "replacing|signed" || true

# Verify signature
if codesign -dv "$VERSIONED_PATH" 2>&1 | grep -q "Format=bundle"; then
    print_success "XCFramework signed successfully"
else
    print_error "Failed to sign XCFramework"
    exit 1
fi

# Step 3: Create ZIP archive
print_step "Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r -q "$(basename "$ZIP_PATH")" "$(basename "$VERSIONED_PATH")"
cd - > /dev/null
print_success "Created: $ZIP_PATH"

# Step 4: Calculate checksum
print_step "Calculating checksum..."
CHECKSUM=$(swift package compute-checksum "$ZIP_PATH")
echo "$CHECKSUM" > "${ZIP_PATH}.checksum"
print_success "Checksum: $CHECKSUM"

# Step 5: Update Package.swift
print_step "Updating Package.swift..."
PACKAGE_FILE="$PROJECT_ROOT/Package.swift"
PACKAGE_BACKUP="$PROJECT_ROOT/Package.swift.backup"

# Backup current Package.swift
cp "$PACKAGE_FILE" "$PACKAGE_BACKUP"

# Create new Package.swift for binary distribution
cat > "$PACKAGE_FILE" <<EOF
// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestLibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TestLibrary",
            targets: ["TestLibrary"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "TestLibrary",
            url: "https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${VERSION}/${ZIP_FILENAME}",
            checksum: "$CHECKSUM"
        )
    ]
)
EOF
print_success "Package.swift updated"

# Step 6: Git operations
print_step "Committing changes..."
cd "$PROJECT_ROOT"

# Initialize git if needed
if [ ! -d .git ]; then
    git init
    git remote add origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
fi

# Add and commit
git add .
git commit -m "Release v${VERSION} - ${DESCRIPTION}" || {
    print_info "Nothing to commit"
}

# Create tag (without v prefix)
git tag -a "${VERSION}" -m "Version ${VERSION} - ${DESCRIPTION}" --force

# Push to remote
print_step "Pushing to GitHub..."
git push origin main --force 2>/dev/null || {
    print_info "Creating initial commit..."
    git branch -M main
    git push -u origin main
}
git push origin "${VERSION}" --force
print_success "Pushed to GitHub"

# Step 7: Create GitHub release (without v prefix)
print_step "Creating GitHub release..."
gh release create "${VERSION}" \
  --title "${VERSION} - ${DESCRIPTION}" \
  --notes "$(cat <<EOF
## Release ${VERSION}

${DESCRIPTION}

### Signature Info
- Certificate ID: \`${CERT_ID}\`
- Checksum: \`${CHECKSUM}\`

### Installation

Add to your \`Package.swift\`:
\`\`\`swift
dependencies: [
    .package(url: "${REPO_URL}.git", from: "${VERSION}")
]
\`\`\`

### Files
- 📦 XCFramework: ${ZIP_FILENAME}
EOF
)" \
  "$ZIP_PATH" \
  --repo "${GITHUB_USER}/${REPO_NAME}" || {
    print_info "Release already exists, updating..."
    gh release delete "${VERSION}" --yes --repo "${GITHUB_USER}/${REPO_NAME}"
    gh release create "${VERSION}" \
      --title "${VERSION} - ${DESCRIPTION}" \
      --notes "Release ${VERSION} - ${DESCRIPTION}" \
      "$ZIP_PATH" \
      --repo "${GITHUB_USER}/${REPO_NAME}"
}

print_success "GitHub release created"

# Step 8: Display summary
echo ""
echo "========================================="
echo "Release ${VERSION} completed successfully!"
echo "========================================="
echo ""
echo "Release URL:"
echo "  ${REPO_URL}/releases/tag/${VERSION}"
echo ""
echo "Download URL:"
echo "  ${REPO_URL}/releases/download/${VERSION}/${ZIP_FILENAME}"
echo ""
echo "Checksum:"
echo "  $CHECKSUM"
echo ""
echo "To test this release in a project, add to Package.swift:"
echo "  .package(url: \"${REPO_URL}.git\", from: \"${VERSION}\")"