# purgeapp/Formula/purgeapp.rb
class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v3.0.13.tar.gz"
  sha256 "4d2f18b99a843a5b5c400c3cab9015b30611077da077f1d535c2f7825f1b262d"
  license "MIT"
  version "3.0.13"

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
