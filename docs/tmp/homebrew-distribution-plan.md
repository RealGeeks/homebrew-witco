# Homebrew Distribution Plan for Private CLI Tool

## Executive Summary
This document outlines the implementation plan for distributing a private CLI binary through Homebrew, addressing AWS SSO authentication, macOS signing requirements, and providing a seamless installation experience.

## Goals & Objectives
- **Primary Goal**: Enable one-command installation of private CLI tool via Homebrew
- **Security**: Maintain private access control through AWS SSO
- **Compatibility**: Ensure macOS Gatekeeper compliance through proper signing
- **User Experience**: Minimize manual configuration steps

## Architecture Overview

### Components
1. **Homebrew Tap Repository** (Public)
   - Hosts the formula definition
   - Manages dependency declarations
   - Handles installation logic

2. **AWS S3 Bucket** (Private)
   - Stores signed binary releases
   - Configured for SSO-based access
   - Versioned binary storage

3. **AWS SSO Integration**
   - Organization-wide authentication
   - Temporary credential management
   - Browser-based authentication flow

## Implementation Phases

### Phase 1: Repository Setup
**Timeline**: Days 1-2

#### Tasks
1. Create GitHub repository: `homebrew-<company-name>`
2. Initialize repository structure:
   ```
   homebrew-<company-name>/
   ├── Formula/
   │   └── <tool-name>.rb
   ├── .github/
   │   └── workflows/
   │       └── tests.yml
   ├── README.md
   └── LICENSE
   ```
3. Configure repository visibility (public)
4. Set up CI/CD for formula testing

#### Deliverables
- Initialized tap repository
- CI/CD pipeline configuration
- Documentation templates

### Phase 2: AWS Infrastructure
**Timeline**: Days 3-4

#### Tasks
1. **S3 Bucket Configuration**
   - Create bucket: `<company-name>-cli-releases`
   - Configure bucket policy for SSO access
   - Enable versioning
   - Set up lifecycle policies

2. **IAM Role Setup**
   - Create role for CLI tool access
   - Configure SSO permission sets
   - Define minimum required permissions:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "s3:GetObject",
             "s3:ListBucket"
           ],
           "Resource": [
             "arn:aws:s3:::<company-name>-cli-releases",
             "arn:aws:s3:::<company-name>-cli-releases/*"
           ]
         }
       ]
     }
     ```

3. **SSO Configuration**
   - Create SSO application
   - Configure user group assignments
   - Test authentication flow

#### Deliverables
- Configured S3 bucket
- IAM roles and policies
- SSO application setup

### Phase 3: Binary Preparation
**Timeline**: Days 5-6

#### Tasks
1. **Code Signing (Optional)**
   - Ad-hoc signing is sufficient for Homebrew distribution:
     ```bash
     # Simple ad-hoc signing (no Developer ID required)
     codesign --force --sign - <tool-name>
     ```
   - OR if you have a Developer ID (provides better user experience):
     ```bash
     codesign --force --sign "Developer ID Application: Company Name" \
              --timestamp <tool-name>
     ```
   - Note: Notarization is NOT required since Homebrew removes quarantine

2. **Binary Packaging**
   - Create versioned archives
   - Generate checksums
   - Create metadata file:
     ```json
     {
       "version": "1.0.0",
       "sha256": "...",
       "release_date": "2024-01-15",
       "min_macos_version": "12.0"
     }
     ```

3. **Upload to S3**
   - Upload signed binaries
   - Set appropriate metadata
   - Test download with SSO credentials

#### Deliverables
- Signed and notarized binaries
- S3 upload automation
- Version metadata system

### Phase 4: Formula Development
**Timeline**: Days 7-9

#### Tasks
1. **Create Homebrew Formula**
   ```ruby
   class ToolName < Formula
     desc "Private CLI tool for company operations"
     homepage "https://github.com/<company-name>/<tool-name>"
     version "1.0.0"
     
     depends_on "awscli"
     
     def install
       # Authentication logic
       if !aws_credentials_valid?
         ohai "AWS SSO authentication required"
         system "aws", "sso", "login", "--profile", "<company-profile>"
       end
       
       # Download binary
       s3_url = "s3://<company-name>-cli-releases/v#{version}/<tool-name>-darwin-amd64"
       system "aws", "s3", "cp", s3_url, ".", "--profile", "<company-profile>"
       
       # Verify checksum
       expected_sha = "..." # From metadata
       actual_sha = Digest::SHA256.file("<tool-name>-darwin-amd64").hexdigest
       odie "Checksum mismatch!" if actual_sha != expected_sha
       
       # Install binary
       bin.install "<tool-name>-darwin-amd64" => "<tool-name>"
     end
     
     def aws_credentials_valid?
       system "aws", "sts", "get-caller-identity", 
              "--profile", "<company-profile>", 
              "--query", "Account", 
              "--output", "text",
              err: File::NULL
     end
     
     test do
       assert_match version.to_s, shell_output("#{bin}/<tool-name> --version")
     end
   end
   ```

2. **Error Handling**
   - Credential expiration handling
   - Network failure recovery
   - Checksum validation
   - Graceful failure messages

3. **Multi-Architecture Support**
   - Detect system architecture
   - Download appropriate binary
   - Handle Apple Silicon and Intel

#### Deliverables
- Complete formula implementation
- Error handling logic
- Architecture detection

### Phase 5: Testing & Validation
**Timeline**: Days 10-11

#### Testing Matrix
| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| Fresh Install | No AWS CLI, no credentials | Installs AWS CLI, prompts for SSO |
| Existing AWS CLI | AWS CLI present, no credentials | Prompts for SSO login |
| Valid Credentials | Everything configured | Direct installation |
| Expired Credentials | Credentials expired | Re-authenticates automatically |
| Network Failure | S3 unreachable | Graceful error message |
| Wrong Architecture | ARM on Intel Mac | Downloads correct binary |
| Upgrade Path | Existing installation | Cleanly upgrades |

#### Validation Steps
1. Test on macOS 12, 13, 14
2. Test on Intel and Apple Silicon
3. Verify Gatekeeper acceptance
4. Test with various AWS SSO configurations
5. Performance benchmarking

#### Deliverables
- Test results documentation
- Performance metrics
- Issue tracking

### Phase 6: Documentation
**Timeline**: Days 12-13

#### Documentation Requirements
1. **README.md** for tap repository
   - Installation instructions
   - Prerequisites
   - Troubleshooting guide

2. **Formula Documentation**
   - Inline comments
   - Configuration options
   - Environment variables

3. **User Guide**
   - First-time setup
   - AWS SSO configuration
   - Common issues and solutions

4. **Developer Documentation**
   - Release process
   - Formula updates
   - Debugging guide

#### Deliverables
- Complete documentation set
- Video tutorials (optional)
- FAQ section

### Phase 7: Deployment & Rollout
**Timeline**: Days 14-15

#### Deployment Steps
1. **Soft Launch**
   - Deploy to test group
   - Gather feedback
   - Address issues

2. **Production Release**
   - Public tap announcement
   - Update internal documentation
   - Monitor installation metrics

3. **Post-Launch Support**
   - Monitor GitHub issues
   - Track installation success rate
   - Gather user feedback

#### Success Metrics
- Installation success rate > 95%
- Average installation time < 2 minutes
- User satisfaction score > 4.5/5

## Technical Specifications

### Binary Requirements
- **Signing**: Apple Developer ID required
- **Notarization**: Required for macOS 10.15+
- **Architecture**: Universal binary or separate Intel/ARM builds
- **Size**: Optimize for download speed (< 50MB preferred)

### AWS Configuration
- **SSO Profile Name**: `<company-name>-cli`
- **Session Duration**: 12 hours (configurable)
- **Region**: us-east-1 (or appropriate)
- **Bucket Encryption**: AES-256

### Homebrew Standards
- Follow Homebrew formula guidelines
- Include comprehensive tests
- Maintain formula quality scores
- Regular formula audits

## Risk Assessment & Mitigation

### Identified Risks
1. **AWS Credential Management**
   - Risk: Credentials expire during installation
   - Mitigation: Implement retry logic with re-authentication

2. **Network Reliability**
   - Risk: S3 download failures
   - Mitigation: Implement exponential backoff and retry

3. **Binary Signing Issues**
   - Risk: Gatekeeper rejection
   - Mitigation: Proper signing and notarization pipeline

4. **Version Conflicts**
   - Risk: AWS CLI version incompatibilities
   - Mitigation: Specify minimum version requirements

5. **User Experience**
   - Risk: Complex authentication flow
   - Mitigation: Clear instructions and error messages

## Maintenance Plan

### Regular Tasks
- **Weekly**: Monitor installation metrics
- **Monthly**: Update dependencies
- **Quarterly**: Security audit
- **Per Release**: Update formula version

### Version Management
- Semantic versioning for CLI tool
- Formula revision numbers for formula changes
- Maintain 3 latest versions in S3

### Support Structure
- GitHub Issues for bug reports
- Slack channel for internal support
- Documentation wiki for knowledge base

## Alternative Approaches Considered

### 1. Direct S3 Download Script
- **Pros**: Simple implementation
- **Cons**: No dependency management, signing issues
- **Decision**: Rejected due to Gatekeeper complications

### 2. Private GitHub Releases
- **Pros**: Built-in authentication
- **Cons**: Requires GitHub PAT management
- **Decision**: Rejected due to token distribution challenges

### 3. Custom Package Manager
- **Pros**: Full control over process
- **Cons**: High maintenance burden
- **Decision**: Rejected due to resource requirements

## Success Criteria Checklist

- [ ] One-command installation works reliably
- [ ] AWS SSO authentication is seamless
- [ ] Binary passes Gatekeeper checks
- [ ] Installation time under 2 minutes
- [ ] Clear error messages for all failure modes
- [ ] Documentation is comprehensive
- [ ] CI/CD pipeline is operational
- [ ] Metrics collection is functional
- [ ] Support channels are established
- [ ] Team is trained on maintenance

## Appendices

### A. Example Installation Flow
```bash
$ brew install <company-name>/<company-name>/<tool-name>
==> Installing <tool-name> from <company-name>/<company-name>
==> Installing dependencies for <company-name>/<company-name>/<tool-name>: awscli
==> Installing <company-name>/<company-name>/<tool-name> dependency: awscli
==> Downloading https://ghcr.io/v2/homebrew/core/awscli/...
==> Pouring awscli--2.15.0.arm64_sonoma.bottle.tar.gz
🍺  /opt/homebrew/Cellar/awscli/2.15.0: 13,123 files, 114.3MB
==> Installing <company-name>/<company-name>/<tool-name>
==> AWS SSO authentication required
==> Running: aws sso login --profile <company-name>-cli
Attempting to automatically open the SSO authorization page in your default browser.
[Authentication flow...]
==> Downloading <tool-name> from S3...
==> Verifying checksum...
==> Installing <tool-name> binary...
🍺  /opt/homebrew/Cellar/<tool-name>/1.0.0: 1 file, 45.2MB, built in 45 seconds
```

### B. Troubleshooting Guide
Common issues and solutions will be documented here.

### C. Release Checklist Template
Standard checklist for new releases will be maintained here.

## Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-01-15 | Team | Initial plan |

---
*This document is a living document and will be updated as the implementation progresses.*