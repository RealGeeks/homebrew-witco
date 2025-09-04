# Homebrew Witco Documentation

## Quick Start

This tap distributes private Witco CLI tools via Homebrew with AWS SSO authentication.

### For Users

Install the CLI tool:
```bash
brew install witco/witco/witco-cli
```

You'll be prompted to authenticate with AWS SSO on first install.

### For Developers

1. **Build and sign binary**:
```bash
# Build
go build -o witco-cli

# Sign (ad-hoc is sufficient)
codesign --force --sign - witco-cli
```

2. **Upload to S3**:
```bash
# Get checksum
shasum -a 256 witco-cli

# Upload
aws s3 cp witco-cli s3://witco-cli-releases/v1.0.0/witco-cli-darwin-amd64 --profile witco-cli
```

3. **Update formula** with new version and SHA256

4. **Test locally**:
```bash
brew install --verbose ./Formula/witco-cli.rb
```

## Documentation

- [📋 Distribution Plan](homebrew-distribution-plan.md) - Complete implementation plan
- [🔧 Implementation Guide](implementation-guide.md) - Step-by-step setup instructions  
- [⚡ Quick Reference](quick-reference.md) - Common commands and tasks
- [🔒 Security Notes](security-notes.md) - Security approach and considerations

## Key Points

✅ **No notarization required** - Homebrew handles Gatekeeper  
✅ **Ad-hoc signing sufficient** - Just use `codesign --sign -`  
✅ **AWS SSO authentication** - Secure, temporary credentials  
✅ **One-command install** - Users just run `brew install`

## Architecture

```
User runs `brew install`
    ↓
Formula checks AWS credentials
    ↓
If needed, triggers AWS SSO login
    ↓
Downloads binary from private S3
    ↓
Removes quarantine attribute
    ↓
Installs to /opt/homebrew/bin/
```

## Support

- GitHub Issues for bugs
- Slack #witco-cli-support for help