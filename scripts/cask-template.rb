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

  uninstall quit: "net.noraesae.Kawa"

  zap trash: [
    "~/Library/Application Support/Kawa",
    "~/Library/Preferences/net.noraesae.Kawa.plist",
  ]

  caveats do
    <<~EOS
      Kawa.app is ad-hoc signed and NOT notarized. Gatekeeper will block the
      first launch of a quarantined copy. Install without quarantine:

        brew install --cask --no-quarantine windemiatrix/tap/kawa

      Or clear the attribute after install:

        xattr -cr /Applications/Kawa.app
    EOS
  end
end
