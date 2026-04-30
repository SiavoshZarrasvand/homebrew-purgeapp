class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "6a0b6d117d302919f74ad80fa38f32be61cf8d08f58c7c3c7f98cdb241466d9f"
  license "MIT"
  version "2.0.1"

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
