cask "kawa" do
  version "0.0.0"
  # version and sha256 are machine-managed by release.yml in Windemiatrix/kawa.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/Windemiatrix/kawa/releases/download/v#{version}/Kawa.zip"
  name "Kawa"
  desc "Menu-bar input source switcher with per-source shortcuts (personal fork)"
  homepage "https://github.com/Windemiatrix/kawa"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :catalina"

  app "Kawa.app"

  # Kawa.app is ad-hoc signed, not notarized; Homebrew 5.0 removed the
  # --no-quarantine flag, so strip the quarantine attribute here instead.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Kawa.app"]
  end

  uninstall quit: "net.noraesae.Kawa"

  zap trash: [
    "~/Library/Application Support/Kawa",
    "~/Library/Preferences/net.noraesae.Kawa.plist",
  ]

  caveats do
    <<~EOS
      Kawa.app is ad-hoc signed and NOT notarized. The cask clears the
      Gatekeeper quarantine attribute on install, so the app launches normally.
      If macOS still blocks it (for example after a manual move), clear the
      attribute yourself:

        xattr -dr com.apple.quarantine /Applications/Kawa.app
    EOS
  end
end
