class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "1613e96aaf39c68815f7035047143f1d68e2dfeeb93108287537f241184df0d9"
  license "MIT"
  version "1.0.0"

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
