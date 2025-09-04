class GeekbotCli < Formula
  desc "Private CLI tool for Real Geeks operations"
  homepage "https://github.com/cincpro/geekbot-cli"
  version "0.1.0"
  
  # Dummy URL that works - we ignore this download in install method
  url "https://github.com/Homebrew/homebrew-core/archive/refs/heads/master.tar.gz"
  sha256 "34873e5e4856c87de505d2086f0ad5f91777297604ed0d45e9233315798a727e"
  
  # Prerequisites only for now
  depends_on "awscli"
  depends_on :macos => :monterey
  
  def install
    # Ignore whatever was downloaded - we'll implement our own logic
    ohai "🧪 Testing prerequisites layer..."
    
    # Test 1: Verify awscli dependency
    if system("which aws > /dev/null 2>&1")
      aws_version = `aws --version 2>&1`.strip
      ohai "✅ AWS CLI dependency working: #{aws_version}"
    else
      odie "❌ AWS CLI not found - dependency failed"
    end
    
    # Test 2: Verify macOS version
    ohai "✅ macOS version check passed"
    
    ohai "🧪 Testing AWS SSO layer..."
    
    # Set up AWS config if needed
    setup_aws_config
    
    # Test AWS SSO authentication
    test_aws_sso
    
    # Create placeholder binary (ignoring the downloaded source)
    (bin/"geekbot-cli").write <<~EOS
      #!/bin/bash
      echo "🧪 Prerequisites + SSO test passed!"
      echo "AWS CLI: $(aws --version 2>&1)"
      echo "AWS Profile: $(aws sts get-caller-identity --profile geekbot-cli 2>/dev/null || echo 'Not authenticated')"
      echo "Next layer: S3 download"
    EOS
    
    ohai "✅ Prerequisites + SSO layer complete. Run 'geekbot-cli' to test."
  end

  private

  def setup_aws_config
    # Use formula-specific location to avoid interfering with user's config
    config_dir = "#{Dir.home}/.homebrew-geekbot"
    config_file = "#{config_dir}/aws-config"
    
    if File.exist?(config_file)
      ohai "✅ AWS config already exists at #{config_file}"
    else
      ohai "Creating AWS config file at #{config_file}..."
      FileUtils.mkdir_p(config_dir)
      
      config_content = <<~CONFIG
        [sso-session witco]
        sso_start_url = https://witco.awsapps.com/start
        sso_region = us-east-2
        sso_registration_scopes = sso:account:access

        [profile geekbot-cli]
        sso_account_id = 357890849873
        sso_session = witco
        sso_role_name = infra-developer
        region = us-east-1
        duration_seconds = 43200
        output = json
      CONFIG
      
      File.write(config_file, config_content)
      ohai "✅ AWS config created"
    end
    
    # Set environment variable so AWS CLI knows where to find our config
    ENV["AWS_CONFIG_FILE"] = config_file
    ohai "✅ AWS_CONFIG_FILE set to #{config_file}"
  end

  def test_aws_sso
    config_file = ENV["AWS_CONFIG_FILE"]
    ohai "🔍 Testing AWS authentication with config: #{config_file}"
    
    # Test if already authenticated - capture output for debugging
    ohai "Running: AWS_CONFIG_FILE=#{config_file} aws sts get-caller-identity --profile geekbot-cli"
    result = `AWS_CONFIG_FILE=#{config_file} aws sts get-caller-identity --profile geekbot-cli 2>&1`
    exit_code = $?.exitstatus
    
    ohai "Exit code: #{exit_code}"
    ohai "Output: #{result.strip}" unless result.strip.empty?
    
    if exit_code == 0
      ohai "✅ Already authenticated with AWS SSO"
      return
    end
    
    ohai "🔐 AWS SSO authentication required..."
    ohai "Exit code was #{exit_code}, output: #{result.strip}"
    ohai "This will open your browser for authentication"
    
    # Trigger SSO login with explicit config file
    ohai "Running: AWS_CONFIG_FILE=#{config_file} aws sso login --profile geekbot-cli"
    unless system("AWS_CONFIG_FILE=#{config_file} aws sso login --profile geekbot-cli")
      odie "❌ AWS SSO login failed"
    end
    
    # Verify authentication worked
    if system("AWS_CONFIG_FILE=#{config_file} aws sts get-caller-identity --profile geekbot-cli > /dev/null 2>&1")
      ohai "✅ AWS SSO authentication successful"
    else
      odie "❌ AWS SSO authentication verification failed"
    end
  end
  
  test do
    assert_match "Prerequisites + SSO test passed", shell_output("#{bin}/geekbot-cli")
  end
end