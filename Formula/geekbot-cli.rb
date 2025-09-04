require_relative "../lib/aws_s3_curl_download_strategy"

class GeekbotCli < Formula
  desc "Private CLI tool for Real Geeks operations"
  homepage "https://github.com/cincpro/geekbot-cli"
  version "0.1.0"

  # Dummy URL that works - we ignore this download in install method
  url "https://mgt-wc-geekbot-cli-releases.s3.us-east-1.amazonaws.com/v0.1.0/geekbot-v0.1.0-aarch64-apple-darwin.tar.gz", using: AwsS3CurlDownloadStrategy
  sha256 "34873e5e4856c87de505d2086f0ad5f91777297604ed0d45e9233315798a727e"

  # Prerequisites only for now
  depends_on "awscli"
  depends_on :macos => :monterey

  def install
    bin.install "geekbot" => "geekbot-cli"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/geekbot-cli --version")
  end
end
