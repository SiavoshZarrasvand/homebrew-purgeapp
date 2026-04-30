class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "5ff091d859aca978550ef111ed5a38b2ba8bd24b0cd5d0056b271cc2683cdc5e"
  license "MIT"
  version "1.0.2"

  depends_on :macos

  def install
    chmod 0755, "purgeapp"
    bin.install "purgeapp"
  end

  test do
    output = shell_output("#{bin}/purgeapp --version")
    assert_match "1.0.1", output
  end
end
