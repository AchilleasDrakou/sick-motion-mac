import AppKit
import Foundation
import QuartzCore
import SickMotionShared

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private enum DotAxis {
    case horizontal
    case vertical
}

private struct DotMeta {
    let baseCenter: CGPoint
    let axis: DotAxis
    let direction: CGFloat
}

final class MotionDotsView: NSView {
    private var dotLayers: [CALayer] = []
    private var dotMeta: [DotMeta] = []
    private var timer: Timer?
    private var phase: CGFloat = .zero
    private let amplitude: CGFloat = 8
    private let margin: CGFloat = 26

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.clear.cgColor
        rebuildDots()
        startAnimation()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        timer?.invalidate()
    }

    override func layout() {
        super.layout()
        rebuildDots()
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func rebuildDots() {
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll(keepingCapacity: true)
        dotMeta.removeAll(keepingCapacity: true)

        let width = bounds.width
        let height = bounds.height
        guard width > 100, height > 100, let rootLayer = layer else { return }

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(5, Int(width / 120)),
            pointProvider: { index, count in
                let x = CGFloat(index + 1) * width / CGFloat(count + 1)
                return CGPoint(x: x, y: height - margin)
            },
            axis: .horizontal,
            direction: 1
        )

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(5, Int(width / 120)),
            pointProvider: { index, count in
                let x = CGFloat(index + 1) * width / CGFloat(count + 1)
                return CGPoint(x: x, y: margin)
            },
            axis: .horizontal,
            direction: -1
        )

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(4, Int(height / 140)),
            pointProvider: { index, count in
                let y = CGFloat(index + 1) * height / CGFloat(count + 1)
                return CGPoint(x: margin, y: y)
            },
            axis: .vertical,
            direction: 1
        )

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(4, Int(height / 140)),
            pointProvider: { index, count in
                let y = CGFloat(index + 1) * height / CGFloat(count + 1)
                return CGPoint(x: width - margin, y: y)
            },
            axis: .vertical,
            direction: -1
        )
    }

    private func addEdgeDots(
        rootLayer: CALayer,
        count: Int,
        pointProvider: (Int, Int) -> CGPoint,
        axis: DotAxis,
        direction: CGFloat
    ) {
        for index in 0..<count {
            let baseCenter = pointProvider(index, count)
            let dot = CALayer()
            dot.backgroundColor = NSColor.systemTeal.withAlphaComponent(0.8).cgColor
            dot.cornerRadius = 4.5
            dot.bounds = CGRect(x: 0, y: 0, width: 9, height: 9)
            dot.position = baseCenter
            rootLayer.addSublayer(dot)

            dotLayers.append(dot)
            dotMeta.append(DotMeta(baseCenter: baseCenter, axis: axis, direction: direction))
        }
    }

    private func tick() {
        phase += 1.0 / 30.0
        let horizontalDelta = sin(phase * 1.2) * amplitude
        let verticalDelta = cos(phase * 1.35) * amplitude
        let pulse = 0.65 + (sin(phase * 2.2) + 1) * 0.15

        for index in dotLayers.indices {
            let meta = dotMeta[index]
            let dot = dotLayers[index]

            switch meta.axis {
            case .horizontal:
                dot.position = CGPoint(
                    x: meta.baseCenter.x + horizontalDelta * meta.direction,
                    y: meta.baseCenter.y
                )
            case .vertical:
                dot.position = CGPoint(
                    x: meta.baseCenter.x,
                    y: meta.baseCenter.y + verticalDelta * meta.direction
                )
            }
            dot.opacity = Float(pulse)
        }
    }
}

final class OverlayManager {
    private(set) var isEnabled = false
    private var windows: [NSWindow] = []
    var onStateChange: ((Bool) -> Void)?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenConfigurationChanged() {
        guard isEnabled else { return }
        showOnAllScreens()
    }

    func toggle() {
        setEnabled(!isEnabled)
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled

        if enabled {
            showOnAllScreens()
        } else {
            hideAll()
        }
        onStateChange?(enabled)
    }

    private func showOnAllScreens() {
        hideAll()

        windows = NSScreen.screens.map { screen in
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.hasShadow = false
            window.isReleasedWhenClosed = false
            window.contentView = MotionDotsView(frame: screen.frame)
            window.orderFrontRegardless()
            return window
        }
    }

    private func hideAll() {
        windows.forEach { $0.close() }
        windows.removeAll()
    }
}

final class CommandListener: NSObject {
    private let overlayManager: OverlayManager

    init(overlayManager: OverlayManager) {
        self.overlayManager = overlayManager
    }

    func start() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleCommand(notification:)),
            name: SickMotionIPC.notificationName,
            object: nil
        )
    }

    @objc private func handleCommand(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let rawAction = userInfo[SickMotionIPC.actionKey] as? String,
            let action = SickMotionAction(rawValue: rawAction)
        else {
            return
        }

        switch action {
        case .toggle:
            overlayManager.toggle()
        case .enable:
            overlayManager.setEnabled(true)
        case .disable:
            overlayManager.setEnabled(false)
        }
    }
}

final class MenuBarController: NSObject {
    private let overlayManager: OverlayManager
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let toggleItem = NSMenuItem(title: "", action: #selector(toggleMotionDots), keyEquivalent: "t")

    init(overlayManager: OverlayManager) {
        self.overlayManager = overlayManager
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "car.fill", accessibilityDescription: "Sick Motion")
            button.imagePosition = .imageOnly
        }

        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Sick Motion", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        refreshState()
    }

    func refreshState() {
        toggleItem.title = overlayManager.isEnabled ? "Disable Motion Dots" : "Enable Motion Dots"
    }

    @objc private func toggleMotionDots() {
        overlayManager.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlayManager = OverlayManager()
    private var listener: CommandListener?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController(overlayManager: overlayManager)
        listener = CommandListener(overlayManager: overlayManager)
        listener?.start()

        overlayManager.onStateChange = { [weak self] _ in
            self?.menuBarController?.refreshState()
        }
    }
}

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.run()
