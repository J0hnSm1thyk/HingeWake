import AppKit
import HingeWakeAuthorization
import HingeWakeCore

private enum AppError: LocalizedError {
    case privilegedOperation(Int32, String)
    case stateVerificationFailed

    var errorDescription: String? {
        switch self {
        case .privilegedOperation(let code, let message):
            return message.isEmpty
                ? "Administrator authorization failed or was cancelled (\(code))."
                : message
        case .stateVerificationFailed:
            return "The observed power setting did not match the requested state. Check the current status before continuing."
        }
    }
}

private final class PrivilegedCommandRunner {
    func run(_ command: SleepCommand) throws {
        var errorBuffer = [CChar](repeating: 0, count: 512)
        let result = HWSetDisableSleep(
            command == .enable ? 1 : 0,
            &errorBuffer,
            errorBuffer.count
        )
        guard result == 0 else {
            let messageBytes = errorBuffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
            let message = String(decoding: messageBytes, as: UTF8.self)
            throw AppError.privilegedOperation(result, message)
        }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let runner = PrivilegedCommandRunner()
    private let statusMenuItem = NSMenuItem(title: "Checking status...", action: nil, keyEquivalent: "")
    private let enableMenuItem = NSMenuItem(title: "Disable Sleep...", action: #selector(enable), keyEquivalent: "e")
    private let disableMenuItem = NSMenuItem(title: "Restore Normal Sleep...", action: #selector(disable), keyEquivalent: "d")
    private var knownSetting: SleepSetting = .unknown

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        refreshStatus()
    }

    private func configureMenu() {
        statusItem.button?.image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "HingeWake")
        statusItem.button?.toolTip = "HingeWake - closed-lid sleep control"

        enableMenuItem.target = self
        disableMenuItem.target = self

        let refreshItem = NSMenuItem(title: "Refresh Status", action: #selector(refreshStatus), keyEquivalent: "r")
        refreshItem.target = self
        let quitItem = NSMenuItem(title: "Quit HingeWake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let menu = NSMenu()
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(enableMenuItem)
        menu.addItem(disableMenuItem)
        menu.addItem(.separator())
        menu.addItem(refreshItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc private func enable() {
        let alert = NSAlert()
        alert.messageText = "Disable system sleep?"
        alert.informativeText = "Your MacBook will remain awake even with the lid closed. This can cause heat buildup and battery drain. Always restore normal sleep before putting the MacBook in a bag. macOS administrator authorization will be requested next."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Continue to Authorization")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        apply(.enable)
    }

    @objc private func disable() {
        apply(.disable)
    }

    private func apply(_ command: SleepCommand) {
        do {
            try runner.run(command)
            refreshStatus()
            guard knownSetting == command.expectedSetting else {
                throw AppError.stateVerificationFailed
            }
            showResult(command == .enable ? "Sleep Disabled" : "Normal Sleep Restored")
        } catch {
            showError(error.localizedDescription)
            refreshStatus()
        }
    }

    @objc private func refreshStatus() {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = SleepSetting.queryArguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationReason == .exit, process.terminationStatus == 0 else {
                knownSetting = .unknown
                updateAppearance()
                return
            }
            let output = String(decoding: data, as: UTF8.self)
            knownSetting = SleepSetting.parse(pmsetOutput: output)
        } catch {
            knownSetting = .unknown
        }
        updateAppearance()
    }

    private func updateAppearance() {
        switch knownSetting {
        case .enabled:
            statusMenuItem.title = "Status: Sleep Disabled"
            statusItem.button?.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Sleep is disabled")
            enableMenuItem.isEnabled = false
            disableMenuItem.isEnabled = true
        case .disabled:
            statusMenuItem.title = "Status: Normal Sleep"
            statusItem.button?.image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Normal sleep is enabled")
            enableMenuItem.isEnabled = true
            disableMenuItem.isEnabled = false
        case .unknown:
            statusMenuItem.title = "Status: Unknown"
            statusItem.button?.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Sleep status is unknown")
            enableMenuItem.isEnabled = true
            disableMenuItem.isEnabled = true
        }
    }

    private func showResult(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = knownSetting == .enabled
            ? "Your MacBook will not sleep when the lid is closed. Restore normal sleep before carrying it."
            : "The normal macOS sleep behavior has been restored."
        alert.runModal()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to Change Sleep Setting"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
