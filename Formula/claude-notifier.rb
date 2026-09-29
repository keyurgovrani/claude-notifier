class ClaudeNotifier < Formula
  desc "macOS notifications for Claude Code with the Claude icon"
  homepage "https://github.com/keyurgovrani/homebrew-claude-notifier"
  url "https://github.com/keyurgovrani/homebrew-claude-notifier/releases/download/v1.1.0/claude-notifier.zip"
  sha256 "959b2e435582da8501afe265b9fbde3bbab92304a843676af69c022f217035f7"

  depends_on "jq"
  depends_on :macos
  depends_on "terminal-notifier"

  def install
    libexec.install Dir["*"]
    (bin/"claude-notifier").write <<~SH
      #!/bin/bash
      case "$1" in
        install) exec bash "#{libexec}/install.sh" ;;
        uninstall) exec bash "#{libexec}/uninstall.sh" ;;
        *) echo "usage: claude-notifier install|uninstall" >&2; exit 1 ;;
      esac
    SH
  end

  # Brew cannot write to ~/.claude or ~/Applications, so setup is a separate step.
  def caveats
    "Run `claude-notifier install` to build the app and add the hooks to Claude Code."
  end

  test do
    assert_match "usage", shell_output("#{bin}/claude-notifier 2>&1", 1)
  end
end
