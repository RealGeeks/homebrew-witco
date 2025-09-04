class WitcoCli < Formula
  desc "Private CLI tool for Witco operations"
  homepage "https://github.com/realgeeks/witco-cli"
  version "1.0.0"
  
  on_macos do
    if Hardware::CPU.arm?
      url "PLACEHOLDER", using: WitcoCliDownloadStrategy
      sha256 "PLACEHOLDER_SHA256_ARM64"
    else
      url "PLACEHOLDER", using: WitcoCliDownloadStrategy  
      sha256 "PLACEHOLDER_SHA256_AMD64"
    end
  end
  
  depends_on "awscli"
  depends_on :macos => :monterey
  
  def install
    binary_name = "witco-cli"
    
    if !aws_credentials_valid?
      ohai "AWS SSO authentication required for Witco organization"
      ohai "Opening browser for authentication..."
      
      system "aws", "sso", "login", "--profile", "witco-cli"
      
      unless aws_credentials_valid?
        odie "AWS SSO authentication failed. Please ensure you have access to the Witco organization."
      end
    end
    
    ohai "Downloading #{binary_name} from private S3 bucket..."
    
    arch = Hardware::CPU.arm? ? "darwin-arm64" : "darwin-amd64"
    s3_path = "s3://witco-cli-releases/v#{version}/#{binary_name}-#{arch}"
    
    begin
      system "aws", "s3", "cp", s3_path, ".", 
             "--profile", "witco-cli",
             "--no-progress"
    rescue => e
      odie "Failed to download binary: #{e.message}"
    end
    
    downloaded_file = "#{binary_name}-#{arch}"
    
    unless File.exist?(downloaded_file)
      odie "Downloaded file not found: #{downloaded_file}"
    end
    
    # Remove quarantine attribute that AWS S3 download adds
    system "xattr", "-d", "com.apple.quarantine", downloaded_file rescue nil
    
    if Hardware::CPU.arm?
      expected_sha = "PLACEHOLDER_SHA256_ARM64"
    else
      expected_sha = "PLACEHOLDER_SHA256_AMD64"
    end
    
    actual_sha = Digest::SHA256.file(downloaded_file).hexdigest
    
    if actual_sha != expected_sha && expected_sha != "PLACEHOLDER_SHA256_ARM64" && expected_sha != "PLACEHOLDER_SHA256_AMD64"
      odie "SHA256 mismatch! Expected: #{expected_sha}, Got: #{actual_sha}"
    end
    
    bin.install downloaded_file => binary_name
    
    ohai "Successfully installed #{binary_name} v#{version}"
  end
  
  def aws_credentials_valid?
    profile = "witco-cli"
    
    ENV["AWS_PROFILE"] = profile
    
    system "aws", "sts", "get-caller-identity",
           "--profile", profile,
           "--query", "Account",
           "--output", "text",
           out: File::NULL,
           err: File::NULL
  end
  
  def post_install
    ohai "Run '#{name} --help' to get started"
  end
  
  test do
    assert_match version.to_s, shell_output("#{bin}/witco-cli --version")
  end
end

class WitcoCliDownloadStrategy < CurlDownloadStrategy
  def fetch(timeout: nil)
    odie <<~EOS
      This formula requires manual download through AWS SSO.
      The installation process will handle the download automatically.
    EOS
  end
end