.PHONY: help test audit install release clean

FORMULA = Formula/witco-cli.rb
VERSION ?= 1.0.0
BINARY_NAME = witco-cli
S3_BUCKET = witco-cli-releases
AWS_PROFILE = witco-cli

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## Test formula syntax and style
	@echo "Testing formula syntax..."
	@ruby -c $(FORMULA)
	@echo "Checking formula style..."
	@brew style $(FORMULA)
	@echo "Auditing formula..."
	@brew audit --strict $(FORMULA) || true

audit: test ## Full audit of formula
	@brew audit --strict --online $(FORMULA)

install: ## Install formula locally for testing
	@echo "Installing formula locally..."
	@brew install --verbose --debug $(FORMULA)

reinstall: ## Reinstall formula (useful for testing)
	@echo "Reinstalling formula..."
	@brew uninstall witco/witco/$(BINARY_NAME) 2>/dev/null || true
	@brew install --verbose --debug $(FORMULA)

tap-local: ## Add this repository as a local tap
	@echo "Adding local tap..."
	@brew tap witco/witco $$(pwd)

untap-local: ## Remove local tap
	@echo "Removing local tap..."
	@brew untap witco/witco

sign-adhoc: ## Ad-hoc sign binaries (no Developer ID needed)
	@echo "Ad-hoc signing binaries..."
	@codesign --force --sign - $(BINARY_NAME)-darwin-amd64
	@codesign --force --sign - $(BINARY_NAME)-darwin-arm64
	@echo "Verifying signatures..."
	@codesign --verify --verbose $(BINARY_NAME)-darwin-amd64
	@codesign --verify --verbose $(BINARY_NAME)-darwin-arm64

checksum: ## Calculate SHA256 for binaries
	@echo "SHA256 checksums:"
	@echo "AMD64: $$(shasum -a 256 $(BINARY_NAME)-darwin-amd64 | cut -d' ' -f1)"
	@echo "ARM64: $$(shasum -a 256 $(BINARY_NAME)-darwin-arm64 | cut -d' ' -f1)"

upload: ## Upload binaries to S3 (requires VERSION)
	@echo "Uploading version $(VERSION) to S3..."
	@aws s3 cp $(BINARY_NAME)-darwin-amd64 \
		s3://$(S3_BUCKET)/v$(VERSION)/$(BINARY_NAME)-darwin-amd64 \
		--profile $(AWS_PROFILE)
	@aws s3 cp $(BINARY_NAME)-darwin-arm64 \
		s3://$(S3_BUCKET)/v$(VERSION)/$(BINARY_NAME)-darwin-arm64 \
		--profile $(AWS_PROFILE)
	@echo "Upload complete"

download-test: ## Test downloading from S3
	@echo "Testing S3 download..."
	@aws s3 cp s3://$(S3_BUCKET)/v$(VERSION)/$(BINARY_NAME)-darwin-amd64 \
		./test-download \
		--profile $(AWS_PROFILE)
	@rm -f ./test-download
	@echo "Download successful"

update-formula: ## Update formula with new version and checksums
	@echo "Update $(FORMULA) with:"
	@echo "  version: $(VERSION)"
	@echo "  AMD64 SHA: $$(shasum -a 256 $(BINARY_NAME)-darwin-amd64 | cut -d' ' -f1)"
	@echo "  ARM64 SHA: $$(shasum -a 256 $(BINARY_NAME)-darwin-arm64 | cut -d' ' -f1)"

release: sign-adhoc checksum ## Prepare release (sign and checksum)
	@echo "Release preparation complete"
	@echo "Next steps:"
	@echo "  1. make upload VERSION=$(VERSION)"
	@echo "  2. Update formula with checksums from above"
	@echo "  3. Commit and push formula changes"
	@echo "  4. Tag release: git tag v$(VERSION)"

clean: ## Clean up test files
	@rm -f test-download
	@rm -f *.sha256
	@echo "Cleanup complete"

aws-login: ## Login to AWS SSO
	@aws sso login --profile $(AWS_PROFILE)

aws-check: ## Check AWS credentials
	@aws sts get-caller-identity --profile $(AWS_PROFILE)

formula-info: ## Show formula information
	@brew info witco/witco/$(BINARY_NAME)

formula-deps: ## Show formula dependencies
	@brew deps witco/witco/$(BINARY_NAME)

ci-test: test audit ## Run CI tests
	@echo "CI tests passed"