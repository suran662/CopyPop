import AppKit

private let pollInterval: TimeInterval = 0.22
private let toastVisibleSeconds: TimeInterval = 0.65
private let previewLimit = 54

private func collapsedWhitespace(_ text: String) -> String {
    text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
}

private func truncated(_ text: String, limit: Int = previewLimit) -> String {
    if text.count <= limit {
        return text
    }
    return String(text.prefix(limit)) + "..."
}

private func textNotice(_ text: String) -> String? {
    let cleaned = collapsedWhitespace(text)
    if cleaned.isEmpty {
        return nil
    }
    return "已复制：" + truncated(cleaned)
}

private final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = NSPasteboard.general.changeCount

    func poll() -> String? {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else {
            return nil
        }
        lastChangeCount = current
        return notice()
    }

    private func notice() -> String {
        let files = fileURLs()
        if !files.isEmpty {
            if files.count == 1 {
                let name = files[0].lastPathComponent.isEmpty ? "文件" : files[0].lastPathComponent
                return "已复制文件：" + truncated(name)
            }
            return "已复制 \(files.count) 个文件"
        }

        if hasImage() {
            return "已复制图片"
        }

        if let text = pasteboard.string(forType: .string), let message = textNotice(text) {
            return message
        }

        return "已复制内容"
    }

    private func fileURLs() -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: options) ?? []
        return objects.compactMap { object in
            if let url = object as? URL, url.isFileURL {
                return url
            }
            if let url = object as? NSURL, url.isFileURL {
                return url as URL
            }
            return nil
        }
    }

    private func hasImage() -> Bool {
        if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil) {
            return true
        }
        return pasteboard.availableType(from: [.png, .tiff]) != nil
    }
}

private final class ToastView: NSView {
    private let check = NSTextField(labelWithString: "✓")
    private let label = NSTextField(labelWithString: "已复制")

    var message: String {
        get { label.stringValue }
        set { label.stringValue = newValue }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.cornerRadius = 26
        layer?.masksToBounds = true

        check.alignment = .center
        check.font = .boldSystemFont(ofSize: 15)
        check.isBezeled = false
        check.isEditable = false
        check.isSelectable = false
        check.drawsBackground = false
        check.wantsLayer = true
        check.layer?.cornerRadius = 11

        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false

        addSubview(check)
        addSubview(label)
        applyColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        let checkSize: CGFloat = 22
        check.frame = NSRect(x: 12, y: (bounds.height - checkSize) / 2, width: checkSize, height: checkSize)
        label.frame = NSRect(x: 43, y: (bounds.height - 22) / 2 - 1, width: bounds.width - 58, height: 24)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyColors()
    }

    private func applyColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor(calibratedWhite: 0.11, alpha: 0.92).cgColor
            : NSColor(calibratedWhite: 0.98, alpha: 0.95).cgColor
        label.textColor = isDark
            ? NSColor(calibratedWhite: 1.0, alpha: 0.96)
            : NSColor(calibratedWhite: 0.08, alpha: 0.96)
        check.textColor = NSColor(calibratedRed: 0.03, green: 0.18, blue: 0.09, alpha: 1.0)
        check.layer?.backgroundColor = NSColor(calibratedRed: 0.38, green: 0.85, blue: 0.55, alpha: 1.0).cgColor
    }
}

private final class ToastController {
    private let size = NSSize(width: 420, height: 52)
    private let window: NSPanel
    private let toastView: ToastView
    private var hideWorkItem: DispatchWorkItem?

    init() {
        toastView = ToastView(frame: NSRect(origin: .zero, size: size))
        window = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.contentView = toastView
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.ignoresMouseEvents = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    }

    func show(_ message: String) {
        hideWorkItem?.cancel()
        toastView.message = message
        window.setFrame(frameNearMouse(), display: false)
        window.alphaValue = 1
        window.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            self?.window.orderOut(nil)
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + toastVisibleSeconds, execute: workItem)
    }

    private func frameNearMouse() -> NSRect {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.visibleFrame, false) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let offset: CGFloat = 16
        let margin: CGFloat = 10

        var x = mouse.x + offset
        var y = mouse.y - size.height - offset
        if x + size.width > bounds.maxX - margin {
            x = mouse.x - size.width - offset
        }
        if y < bounds.minY + margin {
            y = mouse.y + offset
        }

        x = min(max(x, bounds.minX + margin), bounds.maxX - size.width - margin)
        y = min(max(y, bounds.minY + margin), bounds.maxY - size.height - margin)
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor()
    private let toast = ToastController()
    private var statusItem: NSStatusItem?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            guard let self, let message = self.monitor.poll() else {
                return
            }
            self.toast.show(message)
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyPop")
            } else {
                button.title = "CopyPop"
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "退出 CopyPop", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
