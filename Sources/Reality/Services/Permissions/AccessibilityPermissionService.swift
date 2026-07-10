import ApplicationServices

@MainActor
final class AccessibilityPermissionService {
  var currentPermission: AccessibilityPermission {
    AXIsProcessTrusted() ? .granted : .denied
  }
}
