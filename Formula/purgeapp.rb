class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v2.0.4.tar.gz"
  sha256 "b0ed3cd656f577ebe5331d0326cf14173fa6e413fba0328938e1fcac42287cf4"
  license "MIT"
  version "2.0.4"

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
