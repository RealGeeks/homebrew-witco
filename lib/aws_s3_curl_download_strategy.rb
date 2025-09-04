class AwsS3CurlDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
  end

  def fetch(timeout: nil)
    # Set up AWS authentication before download
    setup_aws_config
    test_aws_sso

    # Now proceed with actual S3 download using presigned URL
    super
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    # Generate presigned URL just before download
    presigned_url = generate_presigned_url
    
    # Use the presigned URL for the actual download
    super(url: presigned_url, resolved_url: presigned_url, timeout: timeout)
  end

  def generate_presigned_url
    # Convert HTTPS S3 URL to S3 URI for aws s3 presign command
    # From: https://mgt-wc-geekbot-cli-releases.s3.us-east-1.amazonaws.com/v0.1.0/geekbot-v0.1.0-aarch64-apple-darwin.tar.gz
    # To: s3://mgt-wc-geekbot-cli-releases/v0.1.0/geekbot-v0.1.0-aarch64-apple-darwin.tar.gz

    if @url =~ %r{^https://([^.]+)\.s3\.([^.]+)\.amazonaws\.com/(.+)$}
      bucket = $1
      region = $2
      key = $3
      s3_uri = "s3://#{bucket}/#{key}"

      
      aws_path = "#{ENV['HOMEBREW_PREFIX']}/bin/aws"

      # Generate presigned URL valid for 15 minutes (900 seconds) to allow for multiple uses
      presigned_url = `AWS_CONFIG_FILE=#{aws_config_file} #{aws_path} s3 presign "#{s3_uri}" --expires-in 900 --profile geekbot-cli 2>&1`.strip

      if $?.exitstatus == 0
        presigned_url
      else
        raise "Failed to generate presigned URL: #{presigned_url}"
      end
    else
      raise "Invalid S3 URL format: #{@url}"
    end
  end

  def aws_config_file
    "#{Dir.home}/.homebrew-geekbot/aws-config"
  end

  def setup_aws_config
    # Use formula-specific location to avoid interfering with user's config
    config_dir = "#{Dir.home}/.homebrew-geekbot"

    unless File.exist?(aws_config_file)
      FileUtils.mkdir_p(config_dir)

      config_content = <<~CONFIG
        [sso-session witco]
        sso_start_url = https://witco.awsapps.com/start
        sso_region = us-east-2
        sso_registration_scopes = sso:account:access

        [profile geekbot-cli]
        sso_account_id = 558529356944
        sso_session = witco
        sso_role_name = infra-developer
        region = us-east-1
        duration_seconds = 43200
        output = json
      CONFIG

      File.write(aws_config_file, config_content)
    end
  end

  def test_aws_sso
    # Test authentication by calling AWS CLI with explicit config
    aws_path = "#{ENV['HOMEBREW_PREFIX']}/bin/aws"
    result = `AWS_CONFIG_FILE=#{aws_config_file} #{aws_path} sts get-caller-identity --profile geekbot-cli 2>&1`
    exit_code = $?.exitstatus

    if exit_code == 0
      return
    end

    # Trigger SSO login with explicit config file
    unless system("AWS_CONFIG_FILE=#{aws_config_file} #{aws_path} sso login --profile geekbot-cli")
      raise "AWS SSO login failed"
    end

    # Verify authentication worked
    unless system("AWS_CONFIG_FILE=#{aws_config_file} #{aws_path} sts get-caller-identity --profile geekbot-cli >/dev/null 2>&1")
      raise "AWS SSO authentication verification failed"
    end
  end
end
