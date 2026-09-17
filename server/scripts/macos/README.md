# macOS server (Apple Silicon / ARM64)

Extract the complete archive into a permanent, writable user folder, for example
`~/Applications/CrowleysCloudServer`. Keep the executable, bundled `.dylib`
libraries, `public/`, `config/` and `services/` together. Homebrew is not required
for the packaged server. This archive does not support Intel Macs.

Run from Terminal:

```sh
cd ~/Applications/CrowleysCloudServer
./run.sh
```

On a fresh installation the server writes random secrets to
`config/config.local.json`, preserving any local settings. Open
`http://localhost:8080` after startup (use your overridden port if configured).
The launcher does not open a browser automatically. To change settings, put
only those fields in `config/config.local.json`, then restart.

The executable and bundled libraries are ad-hoc signed, not Developer ID signed
or notarized. macOS may require explicit approval for a downloaded application;
see [Apple's instructions](https://support.apple.com/en-gb/102445).

Video thumbnails require an optional separate FFmpeg installation; configure
`ffmpeg_binary` with its absolute path for background launches, or set
`video_thumbs_enabled` to `false`.

## Start at login

First verify foreground startup, then stop it with Ctrl+C. From the same package:

```sh
bash services/install-agent.sh
```

This installs a user LaunchAgent pointing to the complete package in its current
location; it does not move files into `/usr/local`. Logs are in
`logs/launchd.stdout.log` and `logs/launchd.stderr.log`. To stop the agent:

```sh
launchctl bootout "gui/$(id -u)/com.crowleyscloud.server"
```

To remove it permanently, also remove
`~/Library/LaunchAgents/com.crowleyscloud.server.plist`.

## Update and backup

Stop the server, back up `config/config.local.json` together with `data/` and
`storage/`, and extract the new release into the same folder. The release does
not contain a local config or runtime data. Keep the generated secrets unchanged.
Run `bash services/install-agent.sh` again to restart the login agent.
If moving to another directory, move the local config and data too and reinstall
the agent. A missing secret with existing data is an error, not a new installation.
