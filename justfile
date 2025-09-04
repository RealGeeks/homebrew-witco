# Test formula syntax and install locally
test: clean
    @echo "Testing formula syntax..."
    ruby -c Formula/geekbot-cli.rb
    @echo "✅ Syntax valid"
    @echo "Creating local tap..."
    -brew untap local/witco 2>/dev/null || true
    brew tap-new local/witco --no-git
    @echo "Copying formula to local tap..."
    cp Formula/geekbot-cli.rb /opt/homebrew/Library/Taps/local/homebrew-witco/Formula/
    @echo "Installing from local tap..."
    brew install --verbose local/witco/geekbot-cli
    @echo "✅ Installation complete"
    @echo "Testing installed binary..."
    geekbot-cli
    @echo "✅ All tests passed"

# Remove local installation and tap
clean:
    @echo "Uninstalling geekbot-cli..."
    -brew uninstall geekbot-cli 2>/dev/null || echo "Not installed"  
    @echo "Removing local tap..."
    -brew untap local/witco 2>/dev/null || echo "Local tap not found"
    @echo "✅ Cleanup complete"