.PHONY: help test-cask test-formula clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

test-cask: clean ## Test cask syntax and install locally
	@echo "Testing cask syntax..."
	@ruby -c Casks/geekbot-cli.rb
	@echo "✅ Syntax valid"
	@echo "Adding local tap..."
	@-brew untap local/witco 2>/dev/null || true
	@brew tap-new local/witco --no-git
	@echo "Copying cask to local tap..."
	@mkdir -p /opt/homebrew/Library/Taps/local/homebrew-witco/Casks/
	@cp Casks/geekbot-cli.rb /opt/homebrew/Library/Taps/local/homebrew-witco/Casks/
	@echo "Installing cask..."
	@brew install --verbose --cask local/witco/geekbot-cli
	@echo "✅ Installation complete"
	@echo "Testing installed binary..."
	@geekbot-cli
	@echo "✅ All tests passed"

test-formula: clean ## Test formula (for reference)
	@echo "Testing formula syntax..."
	@ruby -c Formula/geekbot-cli.rb
	@echo "✅ Syntax valid"
	@echo "Adding local tap..."
	@-brew untap local/witco 2>/dev/null || true
	@brew tap-new local/witco --no-git
	@echo "Copying formula to local tap..."
	@cp Formula/geekbot-cli.rb /opt/homebrew/Library/Taps/local/homebrew-witco/Formula/
	@echo "Installing formula..."
	@brew install --verbose local/witco/geekbot-cli
	@echo "✅ Installation complete"

clean: ## Remove local installations
	@echo "Uninstalling geekbot-cli..."
	@-brew uninstall geekbot-cli 2>/dev/null || echo "Not installed"
	@-brew uninstall --cask geekbot-cli 2>/dev/null || echo "Cask not installed"
	@echo "Removing binary..."
	@-rm -f /opt/homebrew/bin/geekbot-cli 2>/dev/null || echo "Binary not found"
	@echo "Removing local tap..."
	@-brew untap local/witco 2>/dev/null || echo "Local tap not found"
	@echo "✅ Cleanup complete"