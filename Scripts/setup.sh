#!/bin/bash

set -e

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== XCFramework Signature Test Setup ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

# Check prerequisites
echo "Checking prerequisites..."

# Check if gh is installed and authenticated
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed"
    echo "Please install it: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI is not authenticated"
    echo "Please run: gh auth login"
    exit 1
fi
print_success "GitHub CLI is authenticated"

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    print_error "xcodebuild is not available"
    echo "Please install Xcode or Xcode Command Line Tools"
    exit 1
fi
print_success "xcodebuild is available"

# List available certificates
echo ""
echo "Available code signing identities:"
security find-identity -v -p codesigning | grep -E "Apple (Development|Distribution)" | head -5

# Create self-signed certificate
echo ""
echo "Creating self-signed certificate for testing..."

CERT_NAME="Test XCFramework Signing"

# Remove any existing test certificates first
security delete-certificate -c "$CERT_NAME" 2>/dev/null || true
security delete-certificate -c "$CERT_NAME" 2>/dev/null || true  # Run twice in case there are multiple

# Always create new certificate
print_info "Creating new self-signed certificate: $CERT_NAME"

# Create certificate configuration
cat > /tmp/cert_config.conf <<EOF
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
C = US
ST = Test State
L = Test City
O = Test Organization
CN = $CERT_NAME

[ v3_ca ]
keyUsage = critical, digitalSignature, keyAgreement
extendedKeyUsage = codeSigning
EOF

# Generate private key
openssl genrsa -out /tmp/test_key.pem 2048 2>/dev/null

# Generate certificate
openssl req -new -x509 -key /tmp/test_key.pem -out /tmp/test_cert.pem -days 365 -config /tmp/cert_config.conf 2>/dev/null

# Convert to p12 with legacy support for macOS
openssl pkcs12 -export \
    -legacy \
    -inkey /tmp/test_key.pem \
    -in /tmp/test_cert.pem \
    -out /tmp/test_cert.p12 \
    -passout pass:testpass

# Import PKCS12 (contains both cert and private key) to login keychain
# The -A flag allows any application to access it
security import /tmp/test_cert.p12 \
    -f pkcs12 \
    -k ~/Library/Keychains/login.keychain-db \
    -P testpass \
    -A \
    || {
    print_error "Failed to import certificate to keychain"
    print_info "Trying to delete existing and retry..."

    # Try to delete existing certificate if any
    security delete-certificate -c "$CERT_NAME" 2>/dev/null || true

    # Retry import
    security import /tmp/test_cert.p12 -f pkcs12 -P testpass -A || {
        print_error "Import failed even after cleanup"
    }
}

# Wait for keychain to process the certificate
sleep 2

# Get the certificate ID - first try codesigning, then all identities
SELF_SIGNED_ID=$(security find-identity -v -p codesigning | grep "$CERT_NAME" | awk '{print $2}' | head -1)

if [ -z "$SELF_SIGNED_ID" ]; then
    print_info "Certificate not found in codesigning identities, checking all identities..."
    SELF_SIGNED_ID=$(security find-identity -v | grep "$CERT_NAME" | awk '{print $2}' | head -1)
fi

if [ -z "$SELF_SIGNED_ID" ]; then
    # If still not found, we'll use the certificate hash directly
    print_info "Identity not found, extracting certificate hash..."

    # Export the certificate to get its SHA-1 hash
    CERT_SHA=$(openssl x509 -in /tmp/test_cert.pem -outform DER 2>/dev/null | openssl sha1 | awk '{print $2}')

    if [ -n "$CERT_SHA" ]; then
        SELF_SIGNED_ID=$(echo "$CERT_SHA" | tr '[:lower:]' '[:upper:]')  # Convert to uppercase
        print_info "Will use certificate SHA-1: $SELF_SIGNED_ID"
    else
        print_error "Failed to create usable self-signed certificate"
        print_info "Will use ad-hoc signing as fallback"
        SELF_SIGNED_ID="-"  # Ad-hoc signing
    fi
fi

# Clean up temp files
rm -f /tmp/test_key.pem /tmp/test_cert.pem /tmp/test_cert.p12 /tmp/cert_config.conf

print_success "Created self-signed certificate with ID: $SELF_SIGNED_ID"

# Find Apple Distribution certificate
APPLE_DIST_ID=$(security find-identity -v -p codesigning | grep "Apple Distribution" | awk '{print $2}' | head -1)
if [ -z "$APPLE_DIST_ID" ]; then
    print_error "No Apple Distribution certificate found"
    print_info "Will use Apple Development certificate instead"
    APPLE_DIST_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | awk '{print $2}' | head -1)
fi

if [ -z "$APPLE_DIST_ID" ]; then
    print_error "No Apple certificates found for signing"
    exit 1
fi

# Save certificate IDs to config file
echo ""
echo "Saving configuration..."
cat > Scripts/config.sh <<EOF
#!/bin/bash
# Auto-generated configuration

# Certificate IDs
export APPLE_CERT_ID="$APPLE_DIST_ID"
export SELF_SIGNED_CERT_ID="$SELF_SIGNED_ID"

# Repository info
export GITHUB_USER="OdNairy"
export REPO_NAME="TestBinaryDependency"
export REPO_URL="https://github.com/\$GITHUB_USER/\$REPO_NAME"

# Library info
export FRAMEWORK_NAME="TestLibrary"
EOF

chmod +x Scripts/config.sh
print_success "Configuration saved to Scripts/config.sh"

echo ""
echo "Certificate IDs:"
echo "  Apple Certificate: $APPLE_DIST_ID"
echo "  Self-Signed Certificate: $SELF_SIGNED_ID"

echo ""
print_success "Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Create the library source files"
echo "2. Create the Xcode project"
echo "3. Run ./Scripts/build_xcframework.sh to build"
echo "4. Run ./Scripts/test_all_releases.sh to create and test releases"