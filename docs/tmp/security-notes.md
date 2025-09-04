# Security Notes

## macOS Gatekeeper and Homebrew

### The Problem
When users download binaries directly from the internet, macOS Gatekeeper quarantines them with the `com.apple.quarantine` extended attribute. This causes the "cannot be opened because the developer cannot be verified" error that requires admin privileges and manual approval in System Settings > Privacy & Security.

### The Homebrew Solution
Homebrew formulas bypass this issue in two ways:

1. **Standard Homebrew downloads**: When using Homebrew's built-in download strategies (`url` directive), Homebrew automatically removes quarantine attributes.

2. **Custom downloads**: When downloading via custom commands (like our `aws s3 cp`), we manually remove the quarantine attribute:
```ruby
system "xattr", "-d", "com.apple.quarantine", downloaded_file
```

### What We DON'T Need
- **Notarization**: Not required for Homebrew-distributed binaries
- **Developer ID Certificate**: Optional (ad-hoc signing with `-` is sufficient)
- **Entitlements**: Not required for CLI tools distributed via Homebrew

### What We DO Need
- **Remove quarantine attributes**: Done in the formula
- **Basic code signing**: Ad-hoc signing (`codesign --sign -`) is sufficient
- **SHA256 verification**: For security and integrity

## Minimum Viable Security

### Build Process
```bash
# Build the binary
go build -o witco-cli

# Ad-hoc sign it (prevents "damaged app" errors)
codesign --force --sign - witco-cli

# Generate checksum
shasum -a 256 witco-cli > witco-cli.sha256

# Upload to S3
aws s3 cp witco-cli s3://bucket/path/
```

### Formula Security
The formula ensures security by:
1. Requiring AWS SSO authentication
2. Downloading from private S3 bucket
3. Verifying SHA256 checksum
4. Removing quarantine attribute

## Enhanced Security (Optional)

If you want additional security layers:

### Developer ID Signing
```bash
# With Developer ID (better user trust)
codesign --force --sign "Developer ID Application: Company (TEAMID)" \
         --timestamp witco-cli
```

Benefits:
- Shows company name if users inspect the binary
- Timestamp ensures signature remains valid
- Better for binaries distributed outside Homebrew

### S3 Bucket Security
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::ACCOUNT:root"},
    "Action": ["s3:GetObject"],
    "Resource": "arn:aws:s3:::bucket/*",
    "Condition": {
      "StringEquals": {
        "aws:PrincipalOrgID": "o-orgid"
      }
    }
  }]
}
```

### Access Logging
Enable S3 access logging to track who downloads binaries:
```bash
aws s3api put-bucket-logging \
  --bucket witco-cli-releases \
  --bucket-logging-status file://logging.json
```

## Authentication Flow Security

### AWS SSO Benefits
- No long-lived credentials
- Temporary tokens (12-hour default)
- Browser-based authentication
- MFA support if configured
- Audit trail via CloudTrail

### Formula Authentication Check
```ruby
def aws_credentials_valid?
  system "aws", "sts", "get-caller-identity",
         "--profile", "witco-cli",
         out: File::NULL,
         err: File::NULL
end
```

This ensures:
- User has valid AWS credentials
- Credentials haven't expired
- User has access to the AWS account

## Comparison with Other Distribution Methods

### Direct Download
❌ Requires notarization
❌ Gatekeeper warnings
❌ Manual quarantine approval
❌ No dependency management

### GitHub Releases  
❌ Requires PAT management
❌ Public or complex auth
✅ Built-in versioning
❌ Still needs notarization

### Homebrew + S3 + SSO (Our Approach)
✅ No notarization needed
✅ No Gatekeeper warnings
✅ Secure authentication
✅ Dependency management
✅ Version management
✅ One-command install

## Security Checklist

### Required
- [x] Binary is code signed (even ad-hoc)
- [x] SHA256 verification in formula
- [x] Quarantine attribute removed in formula
- [x] AWS SSO authentication required
- [x] S3 bucket has proper IAM policies

### Optional but Recommended
- [ ] Developer ID signing
- [ ] S3 access logging enabled
- [ ] CloudTrail audit logging
- [ ] Binary < 50MB for faster downloads
- [ ] Automated security scanning in CI/CD

## Common Security Questions

**Q: Why don't we need notarization?**
A: Homebrew removes quarantine attributes during installation, bypassing Gatekeeper checks.

**Q: Is ad-hoc signing sufficient?**
A: Yes, for Homebrew distribution. It prevents "damaged app" errors without requiring a Developer ID.

**Q: How secure is the AWS SSO approach?**
A: Very secure. It uses temporary credentials, supports MFA, and provides audit trails.

**Q: Can users bypass authentication?**
A: No, the formula checks for valid credentials before downloading.

**Q: What if someone compromises the S3 bucket?**
A: SHA256 verification in the formula would detect tampered binaries.

## Emergency Procedures

### Compromised Binary
1. Remove binary from S3 immediately
2. Update formula to block installation
3. Notify users via GitHub issue
4. Investigate and audit access logs
5. Release patched version

### Revoked Signing Certificate
- For ad-hoc signing: No impact
- For Developer ID: Re-sign and re-upload all binaries

### S3 Bucket Breach
1. Rotate IAM credentials
2. Review access logs
3. Verify all binary checksums
4. Re-upload if necessary
5. Update formula SHA256 values