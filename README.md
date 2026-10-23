# ProjectBridge

An independent macOS app for local FL Studio `.flp` ↔ Ableton Live `.als` conversion. Inspired by the workflow, not copied code or branding, of Jukeblocks Converter.

On a Mac with Xcode Command Line Tools, run `bash build-mac.sh` from Terminal in this folder. This generates `dist/ProjectBridge.app` built for **the Mac you're using**: arm64 on Apple Silicon, x86_64 on Intel. Drag to Applications. The app is unsigned and unnotarized.

The project supports both Intel and Apple Silicon builds, but the basic Command Line Tools on an Apple Silicon Mac may *not* include the Intel Swift libraries required to cross-compile a universal binary. Build on each architecture (or use a full Xcode installation with the appropriate cross-architecture libraries). For Zack's M3 Pro Mac, the build is arm64 only and avoids the x86_64 linker errors.

Click **Install Engine** to download the open-source GPL-3.0 [DawVert](https://github.com/DawVert/DawVert) backend and its dependencies. A working Homebrew Python 3 with `venv` and internet are needed for initial setup. Conversion afterward is local.

Supports projects targeting FL Studio and Ableton Live 11, subject to DawVert's version and feature limitations. Not all plugins, instruments, racks, automation, samples, or newer DAW file revisions can convert accurately. Back up your project and inspect output in the target DAW. MP3/WAV rendering is not supported. This is not the proprietary Jukeblocks engine.

### Automated GitHub builds

The `.github/workflows/build-macos.yml` workflow builds the app on separate GitHub-hosted Apple Silicon and Intel Macs. Push this project to the `main` branch of a GitHub repository with Actions enabled or select **Run workflow** under **Actions → Build macOS apps**. Each successful run provides two downloadable ZIP artifacts, `ProjectBridge-macOS-arm64` and `ProjectBridge-macOS-x86_64`, containing `.app` bundles. The apps are unsigned and unnotarized; the Python/DawVert engine is installed locally when first opened.

Run Python tests with `python3 -m unittest discover -s tests -v`.

ProjectBridge glue is MIT-licensed (see LICENSE). DawVert is distributed separately under GPL-3.0.
