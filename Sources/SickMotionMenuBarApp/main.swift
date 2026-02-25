import AppKit
import CoreLocation
import Foundation
import QuartzCore
import SickMotionShared

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct DotMeta {
    let baseCenter: CGPoint
}

private func clamped(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
    Swift.max(minValue, Swift.min(maxValue, value))
}

private func shortestAngleDelta(from: CLLocationDirection, to: CLLocationDirection) -> CLLocationDirection {
    var delta = to - from
    while delta > 180 { delta -= 360 }
    while delta < -180 { delta += 360 }
    return delta
}

private struct MotionSample {
    let timestamp: TimeInterval
    let speed: CLLocationSpeed
    let course: CLLocationDirection?
}

final class VehicleMotionEstimator: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastSample: MotionSample?
    private var cueVector: CGPoint = .zero
    private var decayTimer: Timer?
    private var lastSignalAt = Date.distantPast
    var onCueUpdate: ((CGPoint) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
    }

    func start() {
        locationManager.requestWhenInUseAuthorization()
        startLocationUpdatesIfAllowed()
        startDecayTimer()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        decayTimer?.invalidate()
        decayTimer = nil
        cueVector = .zero
        onCueUpdate?(.zero)
    }

    private func startLocationUpdatesIfAllowed() {
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorized else { return }
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startLocationUpdatesIfAllowed()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard location.timestamp.timeIntervalSinceNow > -10 else { return }

        let speed = location.speed
        guard speed >= 0 else { return }

        let course: CLLocationDirection? = location.course >= 0 ? location.course : nil
        let sample = MotionSample(
            timestamp: location.timestamp.timeIntervalSinceReferenceDate,
            speed: speed,
            course: course
        )

        guard let previous = lastSample else {
            lastSample = sample
            return
        }

        let dt = sample.timestamp - previous.timestamp
        guard dt > 0.08, dt < 3 else {
            lastSample = sample
            return
        }

        let acceleration = clamped(CGFloat((sample.speed - previous.speed) / dt), min: -3.5, max: 3.5)
        var turnRate: CGFloat = .zero
        if let previousCourse = previous.course, let currentCourse = sample.course {
            turnRate = clamped(CGFloat(shortestAngleDelta(from: previousCourse, to: currentCourse) / dt), min: -30, max: 30)
        }

        // Apple maps cue movement to vehicle motion changes. We apply the same directional model:
        // accelerate -> dots move down, brake -> up, left turn -> right, right turn -> left.
        let target = CGPoint(
            x: clamped(-turnRate * 0.45, min: -16, max: 16),
            y: clamped(-acceleration * 4.5, min: -16, max: 16)
        )

        cueVector = CGPoint(
            x: cueVector.x * 0.65 + target.x * 0.35,
            y: cueVector.y * 0.65 + target.y * 0.35
        )
        lastSignalAt = Date()
        onCueUpdate?(cueVector)
        lastSample = sample
    }

    private func startDecayTimer() {
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.decayTick()
        }
        if let decayTimer {
            RunLoop.main.add(decayTimer, forMode: .common)
        }
    }

    private func decayTick() {
        guard Date().timeIntervalSince(lastSignalAt) > 0.7 else { return }

        cueVector.x *= 0.88
        cueVector.y *= 0.88
        if abs(cueVector.x) < 0.15, abs(cueVector.y) < 0.15 {
            cueVector = .zero
        }
        onCueUpdate?(cueVector)
    }
}

final class MotionDotsView: NSView {
    private var dotLayers: [CALayer] = []
    private var dotMeta: [DotMeta] = []
    private var timer: Timer?
    private var targetCue: CGPoint = .zero
    private var renderedCue: CGPoint = .zero
    private var cueVelocity: CGPoint = .zero
    private let sidePadding: CGFloat = 28
    private let bottomPadding: CGFloat = 30
    private let topPadding: CGFloat = 56

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

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyDotStyle()
    }

    func setTargetCue(_ cue: CGPoint) {
        targetCue = cue
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
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
            count: max(6, Int(width / 96)),
            pointProvider: { index, count in
                let x = CGFloat(index + 1) * width / CGFloat(count + 1)
                return CGPoint(x: x, y: height - topPadding)
            }
        )

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(6, Int(width / 96)),
            pointProvider: { index, count in
                let x = CGFloat(index + 1) * width / CGFloat(count + 1)
                return CGPoint(x: x, y: bottomPadding)
            }
        )

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(5, Int(height / 120)),
            pointProvider: { index, count in
                let y = CGFloat(index + 1) * height / CGFloat(count + 1)
                return CGPoint(x: sidePadding, y: y)
            }
        )

        addEdgeDots(
            rootLayer: rootLayer,
            count: max(5, Int(height / 120)),
            pointProvider: { index, count in
                let y = CGFloat(index + 1) * height / CGFloat(count + 1)
                return CGPoint(x: width - sidePadding, y: y)
            }
        )

        applyDotStyle()
    }

    private func addEdgeDots(
        rootLayer: CALayer,
        count: Int,
        pointProvider: (Int, Int) -> CGPoint
    ) {
        for index in 0..<count {
            let baseCenter = pointProvider(index, count)
            let dot = CALayer()
            dot.cornerRadius = 4.5
            dot.bounds = CGRect(x: 0, y: 0, width: 9, height: 9)
            dot.position = baseCenter
            rootLayer.addSublayer(dot)

            dotLayers.append(dot)
            dotMeta.append(DotMeta(baseCenter: baseCenter))
        }
    }

    private func applyDotStyle() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let fillColor = isDark
            ? NSColor(white: 0.93, alpha: 0.88)
            : NSColor(white: 0.22, alpha: 0.72)
        let shadowColor = isDark
            ? NSColor.black.withAlphaComponent(0.35)
            : NSColor.black.withAlphaComponent(0.2)

        for dot in dotLayers {
            dot.backgroundColor = fillColor.cgColor
            dot.shadowColor = shadowColor.cgColor
            dot.shadowOpacity = 1
            dot.shadowRadius = 1.6
            dot.shadowOffset = .zero
        }
    }

    private func tick() {
        let dt: CGFloat = 1 / 60
        let stiffness: CGFloat = 16
        let damping: CGFloat = 0.8

        cueVelocity.x = (cueVelocity.x + (targetCue.x - renderedCue.x) * stiffness * dt) * damping
        cueVelocity.y = (cueVelocity.y + (targetCue.y - renderedCue.y) * stiffness * dt) * damping
        renderedCue.x = clamped(renderedCue.x + cueVelocity.x, min: -18, max: 18)
        renderedCue.y = clamped(renderedCue.y + cueVelocity.y, min: -18, max: 18)

        let intensity = hypot(renderedCue.x, renderedCue.y)
        let opacity = Float(clamped(0.5 + intensity / 36, min: 0.5, max: 0.88))

        for index in dotLayers.indices {
            let base = dotMeta[index].baseCenter
            let dot = dotLayers[index]
            dot.position = CGPoint(x: base.x + renderedCue.x, y: base.y + renderedCue.y)
            dot.opacity = opacity
        }
    }
}

final class OverlayManager {
    private(set) var isEnabled = false
    private var windows: [NSWindow] = []
    private var dotViews: [MotionDotsView] = []
    private let motionEstimator = VehicleMotionEstimator()
    var onStateChange: ((Bool) -> Void)?

    init() {
        motionEstimator.onCueUpdate = { [weak self] cue in
            self?.dotViews.forEach { $0.setTargetCue(cue) }
        }

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
            motionEstimator.start()
            showOnAllScreens()
        } else {
            motionEstimator.stop()
            hideAll()
        }
        onStateChange?(enabled)
    }

    private func showOnAllScreens() {
        hideAll()

        windows = NSScreen.screens.map { screen in
            let frame = screen.visibleFrame
            let window = OverlayWindow(
                contentRect: frame,
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
            let dotsView = MotionDotsView(frame: CGRect(origin: .zero, size: frame.size))
            window.contentView = dotsView
            dotViews.append(dotsView)
            window.orderFrontRegardless()
            return window
        }
    }

    private func hideAll() {
        windows.forEach { $0.close() }
        windows.removeAll()
        dotViews.removeAll()
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
