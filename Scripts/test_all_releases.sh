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
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }
print_step() { echo -e "${BLUE}→${NC} $1"; }
print_release() { echo -e "${MAGENTA}📦${NC} $1"; }

echo "================================================"
echo "    XCFramework Signature Test - All Releases"
echo "================================================"
echo ""

# Step 0: Run setup if config doesn't exist
if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
    print_info "Configuration not found. Running setup..."
    "$SCRIPT_DIR/setup.sh"

    # Source the newly created config
    source "$SCRIPT_DIR/config.sh"
fi

# Display certificate info
echo "Certificate Configuration:"
echo "-------------------------"
echo "Apple Certificate: ${APPLE_CERT_ID:0:8}..."
echo "Self-Signed Certificate: ${SELF_SIGNED_CERT_ID:0:8}..."
echo ""

# Step 1: Build XCFramework if not exists
if [ ! -d "$PROJECT_ROOT/build/TestLibrary.xcframework" ]; then
    print_step "Building XCFramework..."
    "$SCRIPT_DIR/build_xcframework.sh"
else
    print_info "XCFramework already built, skipping build step"
fi

echo ""
echo "Creating Three Releases:"
echo "========================"
echo ""

# Release 1.0.0 - Apple Distribution Certificate
print_release "Release 1.0.0 - Apple Distribution Certificate"
echo "-----------------------------------------------"
"$SCRIPT_DIR/sign_and_release.sh" \
    "1.0.0" \
    "$APPLE_CERT_ID" \
    "Initial release signed with Apple Distribution certificate"

echo ""
sleep 2  # Small delay to ensure GitHub processes the release

# Release 1.0.1 - Self-Signed Certificate
print_release "Release 1.0.1 - Self-Signed Certificate"
echo "-----------------------------------------"
"$SCRIPT_DIR/sign_and_release.sh" \
    "1.0.1" \
    "$SELF_SIGNED_CERT_ID" \
    "Updated to self-signed certificate for testing"

echo ""
sleep 2  # Small delay to ensure GitHub processes the release

# Release 1.0.2 - Back to Apple Distribution Certificate
print_release "Release 1.0.2 - Apple Distribution Certificate (Round Trip)"
echo "-----------------------------------------------------------"
"$SCRIPT_DIR/sign_and_release.sh" \
    "1.0.2" \
    "$APPLE_CERT_ID" \
    "Switched back to Apple Distribution certificate"

echo ""
echo "================================================"
echo "            All Releases Completed!"
echo "================================================"
echo ""

# Display release summary
echo "Release Summary:"
echo "---------------"
gh release list --repo "${GITHUB_USER}/${REPO_NAME}" --limit 3

echo ""
echo "Repository URL:"
echo "  ${REPO_URL}"
echo ""
echo "Releases:"
echo "  - v1.0.0: Apple Distribution signature"
echo "  - v1.0.1: Self-signed certificate"
echo "  - v1.0.2: Apple Distribution (round trip)"
echo ""
echo "To test signature behavior in Xcode:"
echo "1. Create a new iOS project"
echo "2. Add package dependency: ${REPO_URL}.git"
echo "3. Select version 1.0.0 and build"
echo "4. Update to version 1.0.1 and observe Xcode's behavior"
echo "5. Update to version 1.0.2 and observe again"
echo ""
echo "Expected behaviors to observe:"
echo "- Trust prompts when switching certificates"
echo "- Build warnings or errors"
echo "- Security & Privacy settings requirements"
echo "- SPM cache behavior"