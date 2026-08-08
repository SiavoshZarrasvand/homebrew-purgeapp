# purgeapp/Formula/purgeapp.rb
class Purgeapp < Formula
  desc "Plugin-based discovery & uninstall system for macOS"
  homepage "https://github.com/SiavoshZarrasvand/homebrew-purgeapp"
  url "https://github.com/SiavoshZarrasvand/homebrew-purgeapp/archive/refs/tags/v4.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"
  version "4.0.0"

  depends_on :macos

  def install
    chmod 0755, "purgeapp"
    libexec.install "purgeapp", "lib", "plugins"
    bin.write_exec_script libexec/"purgeapp"
  end

  test do
    output = shell_output("#{bin}/purgeapp --version")
    assert_match version.to_s, output
  end
end
