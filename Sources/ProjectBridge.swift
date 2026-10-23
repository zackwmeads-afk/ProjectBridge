import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
final class ConverterModel: ObservableObject {
    @Published var inputURL: URL?
    @Published var outputPath = ""
    @Published var log = "Welcome to ProjectBridge. Select an FLP or ALS project to begin."
    @Published var isBusy = false
    @Published var isInstalling = false
    @Published var succeeded = false

    var baseURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProjectBridge", isDirectory: true)
            .appendingPathComponent("engine", isDirectory: true)
    }
    var engineReady: Bool {
        FileManager.default.fileExists(atPath: baseURL.appendingPathComponent("DawVert/dawvert_cmd.py").path)
        && FileManager.default.fileExists(atPath: baseURL.appendingPathComponent("venv/bin/python3").path)
    }

    func chooseInput() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.allowsOtherFileTypes = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { setInput(url) }
    }

    func setInput(_ url: URL) {
        guard ["flp", "als"].contains(url.pathExtension.lowercased()) else {
            log = "Choose an FL Studio .flp or Ableton Live .als project."
            return
        }
        inputURL = url
        let target = url.pathExtension.lowercased() == "flp" ? "als" : "flp"
        outputPath = url.deletingPathExtension().path + "-converted." + target
        log = "Ready: \(url.lastPathComponent)\nOutput: \(URL(fileURLWithPath: outputPath).lastPathComponent)"
        succeeded = false
    }

    func chooseOutput() {
        guard let input = inputURL else { return }
        let panel = NSSavePanel()
        let target = input.pathExtension.lowercased() == "flp" ? "als" : "flp"
        panel.nameFieldStringValue = input.deletingPathExtension().lastPathComponent + "-converted." + target
        panel.allowedContentTypes = [.data]
        panel.allowsOtherFileTypes = true
        if panel.runModal() == .OK, let url = panel.url { outputPath = url.path }
    }

    private func execute(_ binary: String, _ args: [String], title: String, install: Bool = false) {
        guard !isBusy else { return }
        isBusy = true
        isInstalling = install
        succeeded = false
        log = title + "\n"
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary)
            process.arguments = args
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            let output: String
            let status: Int32
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                output = String(data: data, encoding: .utf8) ?? "(non-UTF8 output)"
                status = process.terminationStatus
            } catch {
                output = "Could not launch process: \(error.localizedDescription)"
                status = -1
            }
            DispatchQueue.main.async {
                self.log += output + "\n" + (status == 0 ? "✓ Finished." : "✕ Failed (status \(status)).")
                self.isBusy = false
                self.isInstalling = false
                self.succeeded = status == 0 && !install
                self.objectWillChange.send()
            }
        }
    }

    func install() {
        guard let script = Bundle.main.path(forResource: "install_engine", ofType: "sh") else {
            log = "Missing bundled installation script."
            return
        }
        execute("/bin/bash", [script, baseURL.path], title: "Installing open-source DawVert and Python dependencies. Internet is required...", install: true)
    }

    func convert() {
        guard let source = inputURL else { return }
        guard engineReady else { log = "Install the conversion engine first."; return }
        guard let runner = Bundle.main.path(forResource: "engine_runner", ofType: "py") else {
            log = "Missing bundled engine runner."
            return
        }
        execute("/usr/bin/python3", [runner,
          "--engine", baseURL.appendingPathComponent("DawVert").path,
          "--python", baseURL.appendingPathComponent("venv/bin/python3").path,
          "--input", source.path, "--output", outputPath],
          title: "Converting \(source.lastPathComponent)...")
    }

    func revealOutput() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: outputPath)])
    }
}

struct ContentView: View {
    @StateObject private var model = ConverterModel()
    private let accent = Color(red: 0.30, green: 0.88, blue: 0.78)

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.10, blue: 0.15).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.system(size: 42)).foregroundColor(accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PROJECTBRIDGE").font(.system(size: 30, weight: .heavy, design: .rounded)).tracking(1.5)
                            Text("FL STUDIO  ⇄  ABLETON LIVE").font(.caption).tracking(2).foregroundColor(.gray)
                        }
                    }
                    Text("Your project. A different DAW.")
                        .font(.title3).foregroundColor(.white.opacity(0.72))

                    VStack(alignment: .leading, spacing: 14) {
                        label("01", "SOURCE PROJECT")
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .font(.system(size: 34)).foregroundColor(accent)
                            Text(model.inputURL?.lastPathComponent ?? "Drop an .flp or .als project here")
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(2)
                            Text("FL Studio project  •  Ableton Live Set")
                                .font(.caption).foregroundColor(.gray)
                            Button("Browse Files") { model.chooseInput() }
                                .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity).padding(24)
                        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(accent.opacity(0.34), style: StrokeStyle(lineWidth: 1.5, dash: [8, 5])))
                        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
                            guard let provider = providers.first else { return false }
                            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                                if let url = url { DispatchQueue.main.async { model.setInput(url) } }
                            }
                            return true
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        label("02", "DESTINATION")
                        HStack(spacing: 10) {
                            TextField("Choose an input first", text: $model.outputPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Save As…") { model.chooseOutput() }.disabled(model.inputURL == nil)
                        }
                        Text(model.inputURL?.pathExtension.lowercased() == "flp" ? "Output format: Ableton Live (.als)" : "Output format: FL Studio (.flp)")
                            .font(.caption).foregroundColor(accent)
                    }
                    .padding(18).background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 12) {
                        label("03", "CONVERSION ENGINE")
                        HStack(spacing: 12) {
                            Image(systemName: model.engineReady ? "checkmark.circle.fill" : "arrow.down.circle")
                                .foregroundColor(model.engineReady ? accent : .orange)
                            Text(model.engineReady ? "DawVert installed locally" : "One-time setup required")
                            Spacer()
                            Button(model.isInstalling ? "Installing..." : model.engineReady ? "Reinstall" : "Install Engine") {
                                model.install()
                            }.disabled(model.isBusy)
                        }
                    }
                    .padding(18).background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))

                    Button(action: model.convert) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(model.isBusy ? "Working…" : "Convert Project")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.black)
                    .background((model.inputURL == nil || model.isBusy || !model.engineReady) ? Color.gray : accent, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(model.inputURL == nil || model.isBusy || !model.engineReady)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ACTIVITY LOG").font(.caption.bold()).tracking(1.6)
                            Spacer()
                            if model.succeeded {
                                Button("Reveal File") { model.revealOutput() }.foregroundColor(accent)
                            }
                        }
                        Text(model.log)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .foregroundColor(.white.opacity(0.78))
                    }
                    .padding(16).background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 12))
                    Text("LOCAL CONVERSION  •  NO UPLOADS  •  NOT AFFILIATED WITH JUKEBLOCKS")
                        .font(.system(size: 10, weight: .medium)).tracking(1.1).foregroundColor(.gray)
                }
                .padding(30)
                .foregroundColor(.white)
            }
        }
        .frame(minWidth: 620, minHeight: 760)
    }

    private func label(_ number: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text(number).foregroundColor(accent)
            Text(title).foregroundColor(.white.opacity(0.85))
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
    }
}

@main
struct ProjectBridgeApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .windowStyle(.hiddenTitleBar)
    }
}
