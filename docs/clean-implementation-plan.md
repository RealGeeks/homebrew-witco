# Geekbot CLI Homebrew Distribution Plan

## Goal

Public Homebrew tap that installs `geekbot-cli` binaries from a private S3 bucket using AWS SSO authentication.

## Architecture

```
User runs: brew install realgeeks/witco/geekbot-cli
    ↓
Formula checks AWS credentials
    ↓
If expired/missing: triggers AWS SSO login
    ↓
Downloads binary from private S3 bucket
    ↓
Installs as /opt/homebrew/bin/geekbot-cli
```

## Components

### 1. Public Homebrew Tap

- **Repository**: `github.com/realgeeks/homebrew-witco`
- **Formula**: `Formula/geekbot-cli.rb`
- **Visibility**: Public (contains no secrets)

### 2. Private S3 Bucket

- **Bucket**: `mgt-wc-geekbot-cli-releases`
- **Structure**: `s3://mgt-wc-geekbot-cli-releases/v{version}/geekbot-v{version}-{arch}.tar.gz`
- **Access**: AWS SSO authenticated users only

### 3. Release Coordination

**Current geekbot-cli release process:**

- GitHub Actions builds binaries
- Creates GitHub release with assets
- **Missing**: Upload to S3 bucket

**Proposed geekbot-cli release process:**

- GitHub Actions builds binaries
- Creates GitHub release with assets
- **New**: Upload binaries to S3
- **New**: Trigger tap update (webhook or manual)

## Version Management Approach

**Selected**: Hardcoded versions in formula (standard Homebrew practice)

```ruby
# Formula specifies exact version and checksums
version "0.1.0"
sha256 "abc123..." # ARM64
sha256 "def456..." # AMD64
```

**Why**: Homebrew conventions favor explicit versions and checksums for security and reproducibility.

**Impact**: Tap requires updating with each geekbot-cli release, but this will be automated.

## Implementation Steps

### Phase 1: Setup S3 Bucket

1. ~~Create `mgt-wc-geekbot-cli-releases` bucket~~ (Already exists)
2. Configure IAM policy for SSO users
3. Set up lifecycle policies

### Phase 2: Update geekbot-cli Release Process

1. Modify `.github/workflows/release.yml`
2. Add S3 upload step after GitHub release
3. Upload binaries as:
   - `s3://mgt-wc-geekbot-cli-releases/v{version}/geekbot-v{version}-aarch64-apple-darwin.tar.gz`
   - `s3://mgt-wc-geekbot-cli-releases/v{version}/geekbot-v{version}-x86_64-apple-darwin.tar.gz`

### Phase 3: Create Homebrew Formula

1. Create `Formula/geekbot-cli.rb`
2. Handle AWS SSO authentication
3. Download from S3, verify checksums
4. Install binary

### Phase 4: Automate Tap Updates

1. Create GitHub Action in geekbot-cli repo
2. After S3 upload, trigger tap update
3. Use GitHub API to update formula file
4. Automatic PR to homebrew-witco repo

## Formula Structure

```ruby
class GeekbotCli < Formula
  desc "Private CLI tool for Real Geeks operations"
  homepage "https://github.com/cincpro/geekbot-cli"
  version "0.1.0"

  depends_on "awscli"
  depends_on :macos => :monterey

  def install
    # Check AWS credentials
    ensure_aws_authenticated

    # Download from S3
    download_from_s3

    # Extract and install
    extract_and_install
  end

  private

  def ensure_aws_authenticated
    # AWS SSO login if needed
  end

  def download_from_s3
    # Determine architecture
    arch = Hardware::CPU.arm? ? "aarch64-apple-darwin" : "x86_64-apple-darwin"
    tarball = "geekbot-v#{version}-#{arch}.tar.gz"
    s3_path = "s3://mgt-wc-geekbot-cli-releases/v#{version}/#{tarball}"
    
    # aws s3 cp with geekbot-cli profile
  end

  def extract_and_install
    # Extract tar.gz, verify SHA256, install binary
  end
end
```

## Release Workflow

### Manual Process (MVP)

1. Release geekbot-cli (triggers S3 upload)
2. Manually update tap formula
3. Users get new version on `brew update && brew upgrade`

### Automated Process (Future)

1. Release geekbot-cli (triggers S3 upload)
2. GitHub Action updates tap formula automatically
3. Creates PR to homebrew-witco
4. Auto-merge if tests pass

## Security Considerations

### What's Public

- Formula code (no secrets)
- S3 bucket name
- Binary names and versions

### What's Private

- S3 bucket contents (binaries)
- AWS account details
- User credentials (handled by AWS SSO)

### Authentication Flow

1. User runs `brew install realgeeks/witco/geekbot-cli`
2. Formula checks: `aws sts get-caller-identity --profile geekbot-cli`
3. If fails: runs `aws sso login --profile geekbot-cli`
4. Downloads: `aws s3 cp s3://bucket/path --profile geekbot-cli`

## User Experience

### First Time Install

```bash
# User adds tap
brew tap realgeeks/witco

# User installs CLI
brew install realgeeks/witco/geekbot-cli
# → Prompts for AWS SSO login
# → Opens browser for authentication
# → Downloads and installs binary

# CLI is ready
geekbot-cli --help
```

### Updates

```bash
# Standard Homebrew update flow
brew update
brew upgrade realgeeks/witco/geekbot-cli
# → Uses existing AWS credentials
# → Downloads new version from S3
```

## Open Questions

1. **AWS Profile Name**: Use `geekbot-cli` or something else?
2. **S3 Bucket Region**: Which AWS region?
3. **Binary Names**: Keep as `geekbot` or rename to `geekbot-cli`?
4. **Automation Timeline**: Start manual or build automation immediately?
5. **Error Handling**: How detailed should error messages be?

## Next Steps

1. **Confirm approach** with team
2. **Set up S3 bucket** and IAM policies
3. **Create minimal formula** for testing
4. **Update geekbot-cli** release process
5. **Test end-to-end** with real release

## Success Criteria

- [ ] Users can install with: `brew install realgeeks/witco/geekbot-cli`
- [ ] AWS SSO authentication works seamlessly
- [ ] Binaries download from private S3
- [ ] Updates work with standard `brew upgrade`
- [ ] No secrets exposed in public formula
- [ ] Installation time < 2 minutes
- [ ] Clear error messages for auth failures

## Appendix: Rejected Approaches

### Dynamic Versions

```ruby
# Formula fetches latest version info dynamically
def latest_version
  # Query GitHub API or S3 for latest
end
```

**Pros**: No tap updates needed
**Cons**: Complex, potential reliability issues, against Homebrew conventions

### Hybrid Approach

```ruby
# Formula has default version but can be overridden
version "0.1.0" # fallback
def install
  # Try to get latest from GitHub API
  # Fall back to hardcoded version
end
```

**Pros**: Flexible, some automation
**Cons**: Added complexity, unpredictable behavior, debugging difficulty
