.PHONY: help test-formula clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

test-formula: clean ## Test formula
	@echo "Testing formula syntax..."
	@ruby -c Formula/geekbot-cli.rb
	@echo "✅ Syntax valid"
	@echo "Adding local tap..."
	@-brew untap local/witco 2>/dev/null || true
	@brew tap-new local/witco --no-git
	@echo "Copying formula to local tap..."
	@cp Formula/geekbot-cli.rb /opt/homebrew/Library/Taps/local/homebrew-witco/Formula/
	@echo "Copying lib directory to local tap..."
	@cp -r lib /opt/homebrew/Library/Taps/local/homebrew-witco/
	@echo "Installing formula..."
	@brew install --verbose local/witco/geekbot-cli
	@echo "✅ Installation complete"

clean: ## Remove local installations
	@echo "Uninstalling geekbot-cli from all taps..."
	@-brew uninstall geekbot-cli 2>/dev/null || echo "Formula not installed"
	@echo "Removing binary..."
	@-rm -f /opt/homebrew/bin/geekbot-cli 2>/dev/null || echo "Binary not found"
	@echo "Removing local tap..."
	@-brew untap local/witco --force 2>/dev/null || echo "Local tap not found"
	@echo "Clearing Homebrew cache..."
	@-rm -rf /opt/homebrew/Caskroom/geekbot-cli 2>/dev/null || echo "Caskroom not found"
	@echo "Removing AWS config directory..."
	@-rm -rf ~/.homebrew-geekbot 2>/dev/null || echo "AWS config directory not found"
	@echo "✅ Cleanup complete"