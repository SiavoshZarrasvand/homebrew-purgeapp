# purgeapp/Formula/purgeapp.rb
class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v3.0.12.tar.gz"
  sha256 "a21c1a843010817aaa4e63cfc69cbe32e83df1019b8a849082910deb40b1b809"
  license "MIT"
  version "3.0.12"

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
