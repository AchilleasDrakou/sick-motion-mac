import Foundation

public enum SickMotionAction: String {
    case toggle
    case enable
    case disable
}

public enum SickMotionIPC {
    public static let notificationName = Notification.Name("com.sickmotion.command")
    public static let actionKey = "action"
}
