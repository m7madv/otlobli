import Flutter
import AVFoundation
import EventKit
import EventKitUI
import UIKit

final class VoiceBriefShareBridge {
  static let shared = VoiceBriefShareBridge()

  private let appGroup = "group.app.voicebrief.mobile"
  private let payloadKey = "VoiceBriefPendingShare"
  private var channel: FlutterMethodChannel?
  private var dartReady = false

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "voicebrief/share", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takePendingShare" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.dartReady = true
      result(self?.takePayload())
    }
    self.channel = channel
  }

  func notifyIfReady() {
    guard dartReady, let payload = takePayload() else { return }
    channel?.invokeMethod("shareReceived", arguments: payload)
  }

  private func takePayload() -> [String: Any]? {
    guard let defaults = UserDefaults(suiteName: appGroup),
          let payload = defaults.dictionary(forKey: payloadKey)
    else { return nil }
    defaults.removeObject(forKey: payloadKey)
    return payload
  }
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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefShareBridge") {
      VoiceBriefShareBridge.shared.configure(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefCalendarBridge") {
      VoiceBriefCalendarBridge.shared.configure(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceBriefAudioEditorBridge") {
      VoiceBriefAudioEditorBridge.shared.configure(messenger: registrar.messenger())
    }
  }
}
