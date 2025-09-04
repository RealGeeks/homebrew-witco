# Quick Reference

## User Commands

### First Time Installation
```bash
brew tap witco/witco https://github.com/witco/homebrew-witco.git
brew install witco/witco/witco-cli
```

### Update to Latest Version
```bash
brew update
brew upgrade witco/witco/witco-cli
```

### Troubleshooting
```bash
# Re-authenticate with AWS SSO
aws sso login --profile witco-cli

# Reinstall formula
brew reinstall witco/witco/witco-cli

# Check formula info
brew info witco/witco/witco-cli
```

## Developer Commands

### Local Testing
```bash
# Test formula locally
brew install --verbose --debug ./Formula/witco-cli.rb

# Audit formula
brew audit --strict --online Formula/witco-cli.rb

# Check style
brew style Formula/witco-cli.rb
```

### Release New Version
```bash
# 1. Build and sign binary
make build-and-sign VERSION=1.0.1

# 2. Upload to S3
aws s3 cp witco-cli-darwin-amd64 s3://witco-cli-releases/v1.0.1/ --profile witco-cli
aws s3 cp witco-cli-darwin-arm64 s3://witco-cli-releases/v1.0.1/ --profile witco-cli

# 3. Get SHA256
shasum -a 256 witco-cli-darwin-amd64
shasum -a 256 witco-cli-darwin-arm64

# 4. Update formula
vim Formula/witco-cli.rb  # Update version and SHA256 values

# 5. Commit and push
git add Formula/witco-cli.rb
git commit -m "feat: update witco-cli to v1.0.1"
git push
```

### Binary Signing
```bash
# Ad-hoc sign (simplest, sufficient for Homebrew)
codesign --force --sign - witco-cli

# Or with Developer ID (optional)
codesign --force --sign "Developer ID Application: Witco Inc (TEAMID)" witco-cli

# Verify signature
codesign --verify --verbose witco-cli

# Note: Notarization NOT required for Homebrew distribution
```

## File Locations

| Component | Location |
|-----------|----------|
| Formula | `Formula/witco-cli.rb` |
| S3 Bucket | `s3://witco-cli-releases/` |
| AWS Profile | `~/.aws/config` → `[profile witco-cli]` |
| Installed Binary | `/opt/homebrew/bin/witco-cli` (ARM) |
| | `/usr/local/bin/witco-cli` (Intel) |

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `AWS_PROFILE` | AWS profile for S3 access | `witco-cli` |
| `HOMEBREW_NO_AUTO_UPDATE` | Skip brew update | `1` |
| `HOMEBREW_VERBOSE` | Verbose output | `1` |

## Common SHA256 Commands

```bash
# Calculate SHA256
shasum -a 256 filename

# Verify SHA256
echo "expected_sha256  filename" | shasum -a 256 -c

# Get SHA256 for formula
curl -sL https://url/to/file | shasum -a 256
```

## AWS SSO Configuration

```bash
# Configure new SSO profile
aws configure sso
# Use these values:
# SSO start URL: https://witco.awsapps.com/start
# SSO Region: us-east-1
# SSO account: <your-account-id>
# SSO role: DeveloperAccess
# CLI profile name: witco-cli
# CLI default region: us-east-1

# Login
aws sso login --profile witco-cli

# Verify access
aws s3 ls s3://witco-cli-releases/ --profile witco-cli
```

## Debug Commands

```bash
# Check formula syntax
brew formula Formula/witco-cli.rb

# Test download without install
brew fetch witco/witco/witco-cli

# Check installed files
brew list witco/witco/witco-cli

# Show formula dependencies
brew deps witco/witco/witco-cli

# Remove and clean
brew uninstall witco/witco/witco-cli
brew cleanup
```

## Git Commands

```bash
# Create release branch
git checkout -b release/v1.0.1

# Tag release
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1

# Update main branch
git checkout main
git pull
git merge release/v1.0.1
git push
```

## Useful Aliases

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
alias witco-update='brew update && brew upgrade witco/witco/witco-cli'
alias witco-auth='aws sso login --profile witco-cli'
alias witco-test='brew reinstall --verbose --debug witco/witco/witco-cli'
```