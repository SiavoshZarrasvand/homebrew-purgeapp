class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "28a1a53d4eeae8e74cc5ff0fe22772e269d1d16ad19b333ff4734e8303bffac7"
  license "MIT"
  version "1.0.1"

  depends_on :macos

  def install
    chmod 0755, "purgeapp"
    bin.install "purgeapp"
  end

  test do
    output = shell_output("#{bin}/purgeapp --version")
    assert_match "1.0.0", output
  end
end
