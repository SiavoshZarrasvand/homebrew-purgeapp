# purgeapp/Formula/purgeapp.rb
class Purgeapp < Formula
  desc "Completely remove a macOS app and all its leftover files"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v3.0.10.tar.gz"
  sha256 "d7ee9d30334ba90a04ceb0ea107dedd70be91189d26b06f984aac360105db7c6"
  license "MIT"
  version "3.0.10"

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
