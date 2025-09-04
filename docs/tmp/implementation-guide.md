# Implementation Guide

## Quick Start

This guide provides step-by-step instructions for implementing the Homebrew distribution for Witco CLI tools.

## Prerequisites Setup

### 1. Apple Developer Account
```bash
# Verify codesign identity
security find-identity -v -p codesigning

# Expected output should include:
# "Developer ID Application: Your Company Name (TEAMID)"
```

### 2. AWS Configuration
```bash
# Configure SSO profile
aws configure sso
# SSO session name: witco
# SSO start URL: https://witco.awsapps.com/start
# SSO region: us-east-1
# SSO registration scopes: [default]
# CLI default profile: witco-cli
# CLI default region: us-east-1
# CLI default output format: json

# Test configuration
aws sso login --profile witco-cli
aws sts get-caller-identity --profile witco-cli
```

### 3. S3 Bucket Setup
```bash
# Create bucket
aws s3api create-bucket \
  --bucket witco-cli-releases \
  --region us-east-1 \
  --profile witco-cli

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket witco-cli-releases \
  --versioning-configuration Status=Enabled \
  --profile witco-cli

# Set bucket policy
aws s3api put-bucket-policy \
  --bucket witco-cli-releases \
  --policy file://bucket-policy.json \
  --profile witco-cli
```

## Building and Signing the Binary

### 1. Build Binary
```bash
# Build for Intel
GOOS=darwin GOARCH=amd64 go build -o witco-cli-darwin-amd64 ./cmd/witco-cli

# Build for Apple Silicon
GOOS=darwin GOARCH=arm64 go build -o witco-cli-darwin-arm64 ./cmd/witco-cli

# Or create universal binary
lipo -create witco-cli-darwin-amd64 witco-cli-darwin-arm64 \
     -output witco-cli-universal
```

### 2. Sign Binary (Optional but Recommended)
```bash
# Option A: Ad-hoc signing (simplest, no Developer ID needed)
codesign --force --sign - witco-cli-darwin-amd64
codesign --force --sign - witco-cli-darwin-arm64

# Option B: Developer ID signing (if available)
codesign --force \
         --sign "Developer ID Application: Witco Inc (TEAMID)" \
         --timestamp \
         witco-cli-darwin-amd64

# Verify signature
codesign --verify --verbose witco-cli-darwin-amd64
```

### 3. ~~Notarize Binary~~ (NOT REQUIRED)
Since Homebrew removes the quarantine attribute during installation, notarization is not necessary. The formula handles this with:
```ruby
system "xattr", "-d", "com.apple.quarantine", downloaded_file
```

### 4. Upload to S3
```bash
# Calculate SHA256
shasum -a 256 witco-cli-darwin-amd64 > witco-cli-darwin-amd64.sha256
shasum -a 256 witco-cli-darwin-arm64 > witco-cli-darwin-arm64.sha256

# Upload binaries
aws s3 cp witco-cli-darwin-amd64 \
  s3://witco-cli-releases/v1.0.0/witco-cli-darwin-amd64 \
  --profile witco-cli

aws s3 cp witco-cli-darwin-arm64 \
  s3://witco-cli-releases/v1.0.0/witco-cli-darwin-arm64 \
  --profile witco-cli

# Upload checksums
aws s3 cp witco-cli-darwin-amd64.sha256 \
  s3://witco-cli-releases/v1.0.0/witco-cli-darwin-amd64.sha256 \
  --profile witco-cli
```

## Updating the Formula

### 1. Get SHA256 Values
```bash
SHA256_AMD64=$(shasum -a 256 witco-cli-darwin-amd64 | cut -d' ' -f1)
SHA256_ARM64=$(shasum -a 256 witco-cli-darwin-arm64 | cut -d' ' -f1)

echo "AMD64: $SHA256_AMD64"
echo "ARM64: $SHA256_ARM64"
```

### 2. Update Formula
Edit `Formula/witco-cli.rb`:
- Update `version`
- Replace `PLACEHOLDER_SHA256_AMD64` with actual SHA256
- Replace `PLACEHOLDER_SHA256_ARM64` with actual SHA256

### 3. Test Formula Locally
```bash
# Add local tap
brew tap witco/witco .

# Test installation
brew install --verbose --debug witco/witco/witco-cli

# Run tests
brew test witco/witco/witco-cli

# Audit formula
brew audit --strict witco/witco/witco-cli
```

## Release Process

### 1. Tag Release
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### 2. Update Formula
```bash
# Create branch
git checkout -b release/v1.0.0

# Update formula with new version and SHA256
vim Formula/witco-cli.rb

# Commit changes
git add Formula/witco-cli.rb
git commit -m "feat: update witco-cli to v1.0.0"

# Push and create PR
git push -u origin release/v1.0.0
gh pr create --title "feat: update witco-cli to v1.0.0" \
             --body "Updates witco-cli formula to version 1.0.0"
```

### 3. Announce Release
```bash
# Create GitHub release
gh release create v1.0.0 \
  --title "witco-cli v1.0.0" \
  --notes "Release notes here"
```

## Testing Installation

### For New Users
```bash
# Install from tap
brew install witco/witco/witco-cli

# Should prompt for AWS SSO login if not authenticated
# Then download and install binary
```

### For Existing Users
```bash
# Update tap
brew update

# Upgrade formula
brew upgrade witco/witco/witco-cli
```

## Troubleshooting

### Common Issues

#### 1. AWS SSO Token Expired
```bash
# Solution: Re-authenticate
aws sso login --profile witco-cli
```

#### 2. Gatekeeper Blocking Binary
```bash
# Solution: Ensure binary is properly signed and notarized
spctl -a -vvv -t install witco-cli
```

#### 3. Formula Audit Failures
```bash
# Run audit with auto-fix
brew audit --fix witco/witco/witco-cli
```

#### 4. S3 Access Denied
```bash
# Verify IAM permissions
aws s3 ls s3://witco-cli-releases/ --profile witco-cli
```

## Automation Scripts

### Release Script
Create `scripts/release.sh`:
```bash
#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: ./release.sh <version>"
  exit 1
fi

echo "Building binaries..."
make build-all

echo "Signing binaries..."
make sign-all

echo "Notarizing binaries..."
make notarize-all

echo "Uploading to S3..."
make upload VERSION=$VERSION

echo "Updating formula..."
make update-formula VERSION=$VERSION

echo "Creating git tag..."
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin "v$VERSION"

echo "Release $VERSION complete!"
```

## Monitoring

### Installation Metrics
```bash
# View S3 access logs
aws s3 sync s3://witco-cli-releases-logs/ ./logs/ --profile witco-cli

# Analyze download patterns
grep "GET" logs/*.log | wc -l
```

### Error Tracking
Monitor GitHub Issues for:
- Installation failures
- Authentication issues
- Platform-specific problems

## Security Considerations

### Binary Signing
- Never distribute unsigned binaries
- Rotate signing certificates regularly
- Store certificates in secure keychain

### S3 Access
- Use IAM roles with minimal permissions
- Enable S3 access logging
- Regular security audits

### Formula Security
- No hardcoded credentials
- Validate all checksums
- Use HTTPS for all external resources

## Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **Slack**: #witco-cli-support
- **Email**: cli-support@witco.com

## Appendix

### Entitlements File
`entitlements.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### Bucket Policy Template
`bucket-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSSOAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::witco-cli-releases",
        "arn:aws:s3:::witco-cli-releases/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-witcoorgid"
        }
      }
    }
  ]
}
```