class AwsS3CurlDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
  end

  def fetch(timeout: nil)
    # Set up AWS authentication before download
    setup_aws_config
    test_aws_sso
    
    # Now proceed with actual S3 download
    super
  end

  private

  def setup_aws_config
    # Use formula-specific location to avoid interfering with user's config
    config_dir = "#{Dir.home}/.homebrew-geekbot"
    config_file = "#{config_dir}/aws-config"
    
    if File.exist?(config_file)
      puts "✅ AWS config already exists at #{config_file}"
    else
      puts "Creating AWS config file at #{config_file}..."
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
      puts "✅ AWS config created"
    end
    
    # Set environment variable so AWS CLI knows where to find our config
    ENV["AWS_CONFIG_FILE"] = config_file
    puts "✅ AWS_CONFIG_FILE set to #{config_file}"
  end

  def test_aws_sso
    config_file = ENV["AWS_CONFIG_FILE"]
    puts "🔍 Testing AWS authentication with config: #{config_file}"
    
    # Debug PATH and AWS CLI location
    puts "🐛 DEBUG: Current PATH: #{ENV['PATH']}"
    puts "🐛 DEBUG: which aws result: #{`which aws 2>&1`.strip}"
    puts "🐛 DEBUG: /opt/homebrew/bin/aws exists: #{File.exist?('/opt/homebrew/bin/aws')}"
    if File.exist?('/opt/homebrew/bin/aws')
      puts "🐛 DEBUG: Full path version: #{`/opt/homebrew/bin/aws --version 2>&1`.strip}"
    end
    puts "🐛 DEBUG: Current working directory: #{Dir.pwd}"
    puts "🐛 DEBUG: HOMEBREW_PREFIX: #{ENV['HOMEBREW_PREFIX']}"
    
    # Test if already authenticated - capture output for debugging
    aws_path = "#{ENV['HOMEBREW_PREFIX']}/bin/aws"
    puts "Running: AWS_CONFIG_FILE=#{config_file} #{aws_path} sts get-caller-identity --profile geekbot-cli"
    result = `AWS_CONFIG_FILE=#{config_file} #{aws_path} sts get-caller-identity --profile geekbot-cli 2>&1`
    exit_code = $?.exitstatus
    
    puts "Exit code: #{exit_code}"
    puts "Output: #{result.strip}" unless result.strip.empty?
    
    if exit_code == 0
      puts "✅ Already authenticated with AWS SSO"
      return
    end
    
    puts "🔐 AWS SSO authentication required..."
    puts "Exit code was #{exit_code}, output: #{result.strip}"
    puts "This will open your browser for authentication"
    
    # Trigger SSO login with explicit config file
    puts "Running: AWS_CONFIG_FILE=#{config_file} #{aws_path} sso login --profile geekbot-cli"
    unless system("AWS_CONFIG_FILE=#{config_file} #{aws_path} sso login --profile geekbot-cli")
      raise "❌ AWS SSO login failed"
    end
    
    # Verify authentication worked
    unless system("AWS_CONFIG_FILE=#{config_file} #{aws_path} sts get-caller-identity --profile geekbot-cli > /dev/null 2>&1")
      raise "❌ AWS SSO authentication verification failed"
    end
    
    puts "✅ AWS SSO authentication successful"
  end
end
