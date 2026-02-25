import Foundation
import SickMotionShared

private func usage() {
    let text = """
    Usage:
      sickmotionctl toggle
      sickmotionctl enable
      sickmotionctl disable

    Notes:
      - Start the menu bar app first: `swift run sickmotion-menubar`
      - This command sends a distributed notification to the running app.
    """
    print(text)
}

let arg = CommandLine.arguments.dropFirst().first ?? "toggle"
guard let action = SickMotionAction(rawValue: arg) else {
    usage()
    exit(1)
}

DistributedNotificationCenter.default().postNotificationName(
    SickMotionIPC.notificationName,
    object: nil,
    userInfo: [SickMotionIPC.actionKey: action.rawValue],
    options: [.deliverImmediately]
)

print("Sent action: \(action.rawValue)")
