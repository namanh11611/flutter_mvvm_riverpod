import AppIntents
import Foundation

@available(iOS 16.0, *)
struct OpenSosConfirmationIntent: AppIntent {
  static var title: LocalizedStringResource = "Emergency SOS"
  static var description = IntentDescription(
    "Open GoBuddy's slide-to-confirm emergency screen."
  )
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult & OpensIntent {
    let url = URL(string: "gobuddy://app/safety/sos/confirm")!
    return .result(opensIntent: OpenURLIntent(url))
  }
}

@available(iOS 16.0, *)
struct GoBuddyAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenSosConfirmationIntent(),
      phrases: [
        "Emergency SOS with \(.applicationName)",
        "Open SOS with \(.applicationName)",
      ],
      shortTitle: "Emergency SOS",
      systemImageName: "sos.circle.fill"
    )
  }
}
