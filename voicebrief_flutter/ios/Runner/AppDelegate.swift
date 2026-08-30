import Flutter
import AVFoundation
import EventKit
import EventKitUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif

final class VoiceBriefShareBridge {
  static let shared = VoiceBriefShareBridge()

  private enum DocumentImportFailure: Error {
    case unsupportedAudio
    case unreadableAudio
    case oversizedAudio
    case appGroupUnavailable
    case writeFailed
  }

  private let appGroup = "group.app.voicebrief.mobile"
  private let legacyPayloadKey = "VoiceBriefPendingShare"
  private let shareSessionKey = "VoiceBriefShareSession"
  private let manifestName = "pending-share.json"
  private let maxAudioBytes: Int64 = 25 * 1024 * 1024
  private let importQueue = DispatchQueue(
    label: "app.voicebrief.mobile.document-import",
    qos: .userInitiated
  )
  private var channel: FlutterMethodChannel?
  private var dartReady = false
  private var openProcessedResultRequested = false

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "voicebrief/share", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "share_bridge_unavailable", message: nil, details: nil))
        return
      }
      switch call.method {
      case "takePendingShare":
        self.dartReady = true
        result(self.takePayloadForDart())
      case "syncShareSession":
        self.syncShareSession(call.arguments)
        result(nil)
      case "getShareSession":
        result(UserDefaults(suiteName: self.appGroup)?.dictionary(forKey: self.shareSessionKey))
      case "requestShareReadyNotifications":
        UNUserNotificationCenter.current().requestAuthorization(
          options: [.alert, .sound, .badge]
        ) { granted, error in
          DispatchQueue.main.async {
            result(granted && error == nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  func notifyIfReady() {
    guard dartReady, let payload = takePayloadForDart() else { return }
    deliver(payload)
  }

  func requestOpenProcessedResult() {
    openProcessedResultRequested = true
    guard dartReady else { return }
    if let payload = takePayloadForDart() {
      deliver(payload)
    } else {
      openProcessedResultRequested = false
      channel?.invokeMethod("openSharedResult", arguments: nil)
    }
  }

  private func deliver(_ payload: [String: Any]) {
    if payload["error"] != nil {
      channel?.invokeMethod("shareError", arguments: nil)
    } else if payload["kind"] as? String == "processed",
              let result = payload["result"] as? [String: Any] {
      channel?.invokeMethod(
        "shareProcessed",
        arguments: [
          "result": result,
          "openResult": payload["openResult"] as? Bool ?? false,
        ]
      )
    } else {
      channel?.invokeMethod("shareReceived", arguments: payload)
    }
  }

  private func takePayloadForDart() -> [String: Any]? {
    guard var payload = takePayload() else { return nil }
    if payload["kind"] as? String == "processed", openProcessedResultRequested {
      payload["openResult"] = true
      openProcessedResultRequested = false
    }
    return payload
  }

  func importDocument(at source: URL) {
    let accessingSecurityScopedResource = source.startAccessingSecurityScopedResource()
    importQueue.async {
      defer {
        if accessingSecurityScopedResource {
          source.stopAccessingSecurityScopedResource()
        }
      }
      do {
        try self.persistDocument(source)
      } catch {
        self.persistImportError()
      }
      DispatchQueue.main.async {
        self.notifyIfReady()
      }
    }
  }

  private func takePayload() -> [String: Any]? {
    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    ) {
      let manifest = container
        .appendingPathComponent("Incoming", isDirectory: true)
        .appendingPathComponent(manifestName)
      if let data = try? Data(contentsOf: manifest),
         let object = try? JSONSerialization.jsonObject(with: data),
         let payload = object as? [String: Any] {
        try? FileManager.default.removeItem(at: manifest)
        return payload
      }
      if FileManager.default.fileExists(atPath: manifest.path) {
        try? FileManager.default.removeItem(at: manifest)
      }
    }
    guard let defaults = UserDefaults(suiteName: appGroup),
          let payload = defaults.dictionary(forKey: legacyPayloadKey)
    else { return nil }
    defaults.removeObject(forKey: legacyPayloadKey)
    return payload
  }

  private func syncShareSession(_ arguments: Any?) {
    guard let defaults = UserDefaults(suiteName: appGroup) else { return }
    guard let values = arguments as? [String: Any],
          let supabaseURL = values["supabaseUrl"] as? String,
          let anonKey = values["anonKey"] as? String,
          let accessToken = values["accessToken"] as? String,
          let refreshToken = values["refreshToken"] as? String,
          let userId = values["userId"] as? String,
          let expiresAt = values["expiresAt"] as? NSNumber,
          supabaseURL.hasPrefix("https://"),
          !anonKey.isEmpty,
          !accessToken.isEmpty,
          !refreshToken.isEmpty,
          !userId.isEmpty
    else {
      defaults.removeObject(forKey: shareSessionKey)
      return
    }
    defaults.set(
      [
        "supabaseUrl": supabaseURL,
        "anonKey": anonKey,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "userId": userId,
        "expiresAt": expiresAt,
      ],
      forKey: shareSessionKey
    )
  }

  private func persistDocument(_ source: URL) throws {
    let sourceExtension = source.pathExtension.lowercased()
    let sourceType = UTType(filenameExtension: sourceExtension)
    guard sourceType?.conforms(to: .audio) == true
      || Self.supportedAudioExtensions.contains(sourceExtension)
    else {
      throw DocumentImportFailure.unsupportedAudio
    }

    let values = try source.resourceValues(forKeys: [.fileSizeKey])
    let size: Int64
    if let fileSize = values.fileSize, fileSize > 0 {
      size = Int64(fileSize)
    } else {
      let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
      size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }
    guard size > 0 else { throw DocumentImportFailure.unreadableAudio }
    guard size <= maxAudioBytes else { throw DocumentImportFailure.oversizedAudio }
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    ) else {
      throw DocumentImportFailure.appGroupUnavailable
    }

    let incoming = container.appendingPathComponent("Incoming", isDirectory: true)
    try FileManager.default.createDirectory(
      at: incoming,
      withIntermediateDirectories: true
    )
    let manifest = incoming.appendingPathComponent(manifestName)
    removePreviousPayload(manifest: manifest)

    let originalName = source.lastPathComponent.isEmpty
      ? "shared-audio.\(sourceExtension.isEmpty ? "m4a" : sourceExtension)"
      : source.lastPathComponent
    let target = incoming.appendingPathComponent("\(UUID().uuidString)-\(originalName)")
    do {
      try FileManager.default.copyItem(at: source, to: target)
      let mime = sourceType?.preferredMIMEType
        ?? UTType(filenameExtension: target.pathExtension)?.preferredMIMEType
        ?? "audio/*"
      let duration = CMTimeGetSeconds(AVURLAsset(url: target).duration)
      let payload: [String: Any] = [
        "path": target.path,
        "name": originalName,
        "mime": mime,
        "source": "iosShare",
        "sizeBytes": size,
        "durationSeconds": duration.isFinite && duration > 0 ? Int(ceil(duration)) : 0,
      ]
      let data = try JSONSerialization.data(withJSONObject: payload)
      try data.write(to: manifest, options: .atomic)
      UserDefaults(suiteName: appGroup)?.removeObject(forKey: legacyPayloadKey)
    } catch {
      try? FileManager.default.removeItem(at: target)
      throw DocumentImportFailure.writeFailed
    }
  }

  private func persistImportError() {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    ) else { return }
    let incoming = container.appendingPathComponent("Incoming", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: incoming,
      withIntermediateDirectories: true
    )
    let manifest = incoming.appendingPathComponent(manifestName)
    removePreviousPayload(manifest: manifest)
    let payload = ["error": "share_handoff"]
    guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
    try? data.write(to: manifest, options: .atomic)
  }

  private func removePreviousPayload(manifest: URL) {
    if let data = try? Data(contentsOf: manifest),
       let object = try? JSONSerialization.jsonObject(with: data),
       let value = object as? [String: Any],
       let previousPath = value["path"] as? String {
      try? FileManager.default.removeItem(atPath: previousPath)
    }
    try? FileManager.default.removeItem(at: manifest)
    if let previous = UserDefaults(suiteName: appGroup)?.dictionary(forKey: legacyPayloadKey),
       let previousPath = previous["path"] as? String {
      try? FileManager.default.removeItem(atPath: previousPath)
    }
  }

  private static let supportedAudioExtensions: Set<String> = [
    "flac", "mp3", "mp4", "mpeg", "mpga", "m4a", "ogg", "opus", "wav", "webm",
  ]
}

final class VoiceBriefCalendarBridge: NSObject, EKEventEditViewDelegate {
  static let shared = VoiceBriefCalendarBridge()

  private let store = EKEventStore()
  private var pendingResult: FlutterResult?

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "voicebrief/calendar", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "openEvent",
            let values = call.arguments as? [String: Any],
            let startMillis = values["startMillis"] as? NSNumber,
            let endMillis = values["endMillis"] as? NSNumber,
            endMillis.int64Value > startMillis.int64Value
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.presentEditor(
        title: values["title"] as? String ?? "VoiceBrief event",
        notes: values["description"] as? String ?? "",
        start: Date(timeIntervalSince1970: startMillis.doubleValue / 1000),
        end: Date(timeIntervalSince1970: endMillis.doubleValue / 1000),
        result: result
      )
    }
  }

  private func presentEditor(
    title: String,
    notes: String,
    start: Date,
    end: Date,
    result: @escaping FlutterResult
  ) {
    guard pendingResult == nil,
          let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
          let presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    else {
      result(FlutterError(code: "calendar_unavailable", message: "Calendar editor is unavailable", details: nil))
      return
    }
    let editor = EKEventEditViewController()
    let event = EKEvent(eventStore: store)
    event.title = title
    event.notes = notes
    event.startDate = start
    event.endDate = end
    editor.eventStore = store
    editor.event = event
    editor.editViewDelegate = self
    pendingResult = result
    presenter.present(editor, animated: true)
  }

  func eventEditViewController(
    _ controller: EKEventEditViewController,
    didCompleteWith action: EKEventEditViewAction
  ) {
    controller.dismiss(animated: true)
    pendingResult?(action == .saved)
    pendingResult = nil
  }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
private struct VoiceBriefAlarmMetadata: AlarmMetadata {}
#endif

final class VoiceBriefReminderBridge {
  static let shared = VoiceBriefReminderBridge()

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "voicebrief/reminders", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "schedule",
            let values = call.arguments as? [String: Any],
            let fireMillis = values["fireMillis"] as? NSNumber
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      let fireDate = Date(timeIntervalSince1970: fireMillis.doubleValue / 1000)
      guard fireDate.timeIntervalSinceNow > 1 else {
        result(FlutterError(code: "invalid_reminder", message: "Reminder must be in the future", details: nil))
        return
      }

#if canImport(AlarmKit)
      if #available(iOS 26.0, *) {
        self.scheduleAlarm(fireDate: fireDate, result: result)
        return
      }
#endif

      self.scheduleNotificationFallback(fireDate: fireDate, values: values, result: result)
    }
  }

#if canImport(AlarmKit)
  @available(iOS 26.0, *)
  private func scheduleAlarm(fireDate: Date, result: @escaping FlutterResult) {
    Task { @MainActor in
      do {
        let manager = AlarmManager.shared
        let authorizationState: AlarmManager.AuthorizationState
        if manager.authorizationState == .notDetermined {
          authorizationState = try await manager.requestAuthorization()
        } else {
          authorizationState = manager.authorizationState
        }

        guard authorizationState == .authorized else {
          result(false)
          return
        }

        let alert = AlarmPresentation.Alert(
          title: "VoiceBrief",
          stopButton: .stopButton,
          secondaryButton: nil,
          secondaryButtonBehavior: nil
        )
        let attributes = AlarmAttributes(
          presentation: AlarmPresentation(alert: alert),
          metadata: VoiceBriefAlarmMetadata(),
          tintColor: Color.blue
        )
        let configuration = AlarmManager.AlarmConfiguration<VoiceBriefAlarmMetadata>(
          countdownDuration: nil,
          schedule: .fixed(fireDate),
          attributes: attributes,
          stopIntent: nil,
          secondaryIntent: nil
        )
        _ = try await manager.schedule(id: UUID(), configuration: configuration)
        result(true)
      } catch {
        result(
          FlutterError(
            code: "alarm_schedule_failed",
            message: "The system alarm could not be scheduled",
            details: nil
          )
        )
      }
    }
  }
#endif

  private func scheduleNotificationFallback(
    fireDate: Date,
    values: [String: Any],
    result: @escaping FlutterResult
  ) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      guard granted, error == nil else {
        DispatchQueue.main.async { result(false) }
        return
      }
      let content = UNMutableNotificationContent()
      content.title = values["title"] as? String ?? "VoiceBrief"
      content.body = values["body"] as? String ?? ""
      content.sound = .default
      content.threadIdentifier = "voicebrief-reminders"
      content.userInfo = ["voicebriefTarget": "reminder"]
      let identifier = values["identifier"] as? String ?? UUID().uuidString.lowercased()
      let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: max(fireDate.timeIntervalSinceNow, 1),
        repeats: false
      )
      center.add(
        UNNotificationRequest(
          identifier: "voicebrief-reminder-\(identifier)",
          content: content,
          trigger: trigger
        )
      ) { addError in
        DispatchQueue.main.async { result(addError == nil) }
      }
    }
  }
}

final class VoiceBriefAudioEditorBridge {
  static let shared = VoiceBriefAudioEditorBridge()

  private var activeExport: AVAssetExportSession?

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "voicebrief/audio_edit", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "trim",
            let values = call.arguments as? [String: Any],
            let inputPath = values["inputPath"] as? String,
            let outputPath = values["outputPath"] as? String,
            let startMs = values["startMs"] as? NSNumber,
            let endMs = values["endMs"] as? NSNumber,
            startMs.int64Value >= 0,
            endMs.int64Value - startMs.int64Value >= 1_000
      else {
        result(FlutterError(code: "invalid_audio_edit", message: "Invalid audio edit range", details: nil))
        return
      }
      self?.trim(
        inputPath: inputPath,
        outputPath: outputPath,
        startMs: startMs.int64Value,
        endMs: endMs.int64Value,
        result: result
      )
    }
  }

  private func trim(
    inputPath: String,
    outputPath: String,
    startMs: Int64,
    endMs: Int64,
    result: @escaping FlutterResult
  ) {
    guard activeExport == nil else {
      result(FlutterError(code: "audio_edit_busy", message: "An audio edit is already running", details: nil))
      return
    }
    let inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
    let outputURL = URL(fileURLWithPath: outputPath).standardizedFileURL
    let temporaryRoot = URL(fileURLWithPath: NSTemporaryDirectory()).standardizedFileURL.path
    guard FileManager.default.fileExists(atPath: inputURL.path),
          outputURL.path.hasPrefix(temporaryRoot)
    else {
      result(FlutterError(code: "invalid_audio_edit", message: "Audio edit paths are invalid", details: nil))
      return
    }
    try? FileManager.default.removeItem(at: outputURL)
    let asset = AVURLAsset(url: inputURL)
    guard let exporter = AVAssetExportSession(
      asset: asset,
      presetName: AVAssetExportPresetAppleM4A
    ) else {
      result(FlutterError(code: "audio_edit_failed", message: "This audio cannot be exported", details: nil))
      return
    }
    exporter.outputURL = outputURL
    exporter.outputFileType = .m4a
    exporter.timeRange = CMTimeRange(
      start: CMTime(value: startMs, timescale: 1_000),
      duration: CMTime(value: endMs - startMs, timescale: 1_000)
    )
    activeExport = exporter
    exporter.exportAsynchronously { [weak self, weak exporter] in
      DispatchQueue.main.async {
        self?.activeExport = nil
        guard let exporter, exporter.status == .completed,
              FileManager.default.fileExists(atPath: outputURL.path)
        else {
          try? FileManager.default.removeItem(at: outputURL)
          result(FlutterError(code: "audio_edit_failed", message: "Audio trim failed", details: nil))
          return
        }
        result(true)
      }
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let target = notification.request.content.userInfo["voicebriefTarget"] as? String
    if target == "sharedResult" || target == "reminder" {
      completionHandler([.banner, .sound])
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.content.userInfo["voicebriefTarget"] as? String == "sharedResult" {
      VoiceBriefShareBridge.shared.requestOpenProcessedResult()
      UIApplication.shared.applicationIconBadgeNumber = 0
      completionHandler()
      return
    }
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.isFileURL {
      VoiceBriefShareBridge.shared.importDocument(at: url)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefShareBridge") {
      VoiceBriefShareBridge.shared.configure(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefCalendarBridge") {
      VoiceBriefCalendarBridge.shared.configure(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefReminderBridge") {
      VoiceBriefReminderBridge.shared.configure(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefAudioEditorBridge") {
      VoiceBriefAudioEditorBridge.shared.configure(messenger: registrar.messenger())
    }
  }
}
