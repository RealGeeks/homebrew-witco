require_relative "../lib/aws_s3_curl_download_strategy"

class GeekbotCli < Formula
  desc "Private CLI tool for Real Geeks operations"
  homepage "https://github.com/cincpro/geekbot-cli"
  version "0.1.0"

  # Dummy URL that works - we ignore this download in install method
  url "https://mgt-wc-geekbot-cli-releases.s3.us-east-1.amazonaws.com/v0.1.0/geekbot-v0.1.0-aarch64-apple-darwin.tar.gz", using: AwsS3CurlDownloadStrategy
  sha256 "4424e77dd9a033c0776d5e185e493772efbcef1408bf3f3789e911c993ac05e7"

  # Prerequisites only for now
  depends_on "awscli"
  depends_on :macos => :monterey

  def install
    bin.install "geekbot" => "geekbot-cli"
  end

  def uninstall_preflight
    # Clean up AWS config directory created by our custom download strategy
    config_dir = "#{Dir.home}/.homebrew-geekbot"
    FileUtils.rm_rf(config_dir) if Dir.exist?(config_dir)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/geekbot-cli --version")
  end
end
