# purgeapp/Formula/purgeapp.rb
class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v3.0.11.tar.gz"
  sha256 "a26c391e83ad6b0a2fbde12768e8c2e4efe7b4082735d8982476279d9f088864"
  license "MIT"
  version "3.0.11"

  depends_on :macos

  def install
    chmod 0755, "purgeapp"
    bin.install "purgeapp"
  end

  test do
    output = shell_output("#{bin}/purgeapp --version")
    assert_match version.to_s, output
  end
end
