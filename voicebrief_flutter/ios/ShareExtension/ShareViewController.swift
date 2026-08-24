import UIKit
import AVFoundation
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let appGroup = "group.app.voicebrief.mobile"
  private let payloadKey = "VoiceBriefPendingShare"
  private let maxAudioBytes: Int64 = 25 * 1024 * 1024
  private var finished = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    importFirstAudioAttachment()
  }

  private func importFirstAudioAttachment() {
    guard !finished,
          let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let provider = item.attachments?.first(where: { audioTypeIdentifier(for: $0) != nil }),
          let typeIdentifier = audioTypeIdentifier(for: provider)
    else {
      finish(error: "VoiceBrief could not find an audio attachment.")
      return
    }
    finished = true
    provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] source, error in
      guard let self, error == nil, let source else {
        self?.finish(error: "VoiceBrief could not read this audio file.")
        return
      }
      do {
        let values = try source.resourceValues(forKeys: [.fileSizeKey])
        let size = Int64(values.fileSize ?? 0)
        guard size > 0, size <= self.maxAudioBytes else {
          self.finish(error: "Audio must be smaller than 25 MB.")
          return
        }
        guard let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: self.appGroup
        ) else { throw CocoaError(.fileNoSuchFile) }
        let incoming = container.appendingPathComponent("Incoming", isDirectory: true)
        try FileManager.default.createDirectory(at: incoming, withIntermediateDirectories: true)
        let originalName = self.normalizedAudioName(
          provider.suggestedName ?? source.lastPathComponent,
          typeIdentifier: typeIdentifier
        )
        let target = incoming.appendingPathComponent("\(UUID().uuidString)-\(originalName)")
        try FileManager.default.copyItem(at: source, to: target)
        let mime = UTType(filenameExtension: target.pathExtension)?.preferredMIMEType ?? "audio/*"
        let duration = CMTimeGetSeconds(AVURLAsset(url: target).duration)
        let payload: [String: Any] = [
          "path": target.path,
          "name": originalName,
          "mime": mime,
          "source": "iosShare",
          "sizeBytes": size,
          "durationSeconds": duration.isFinite && duration > 0 ? Int(ceil(duration)) : 0,
        ]
        guard let defaults = UserDefaults(suiteName: self.appGroup) else {
          throw CocoaError(.fileWriteUnknown)
        }
        if let previous = defaults.dictionary(forKey: self.payloadKey),
           let previousPath = previous["path"] {
          try? FileManager.default.removeItem(atPath: previousPath as? String ?? "")
        }
        defaults.set(payload, forKey: self.payloadKey)
        DispatchQueue.main.async { self.openHostApp() }
      } catch {
        self.finish(error: "VoiceBrief could not import this audio file.")
      }
    }
  }

  private func audioTypeIdentifier(for provider: NSItemProvider) -> String? {
    provider.registeredTypeIdentifiers.first { identifier in
      guard let type = UTType(identifier) else { return false }
      return type.conforms(to: .audio)
    }
  }

  private func normalizedAudioName(_ rawName: String, typeIdentifier: String) -> String {
    let sourceName = URL(fileURLWithPath: rawName).lastPathComponent.isEmpty
      ? "shared-audio"
      : URL(fileURLWithPath: rawName).lastPathComponent
    let sourceExtension = URL(fileURLWithPath: sourceName).pathExtension.lowercased()
    let type = UTType(typeIdentifier)
    let canonicalExtension: String
    if sourceExtension == "opus" {
      canonicalExtension = "ogg"
    } else if Self.supportedExtensions.contains(sourceExtension) {
      canonicalExtension = sourceExtension
    } else if type?.preferredMIMEType == "audio/ogg" || typeIdentifier.lowercased().contains("opus") {
      canonicalExtension = "ogg"
    } else {
      canonicalExtension = type?.preferredFilenameExtension ?? "m4a"
    }
    let stem = sourceExtension.isEmpty
      ? sourceName
      : URL(fileURLWithPath: sourceName).deletingPathExtension().lastPathComponent
    return "\(stem.isEmpty ? "shared-audio" : stem).\(canonicalExtension)"
  }

  private func openHostApp() {
    guard let url = URL(string: "voicebrief://shared-audio") else {
      finish(error: nil)
      return
    }
    extensionContext?.open(url) { [weak self] _ in self?.finish(error: nil) }
  }

  private func finish(error: String?) {
    DispatchQueue.main.async {
      if let error {
        let alert = UIAlertController(title: "Import failed", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
          self?.extensionContext?.cancelRequest(withError: CocoaError(.fileReadUnknown))
        })
        self.present(alert, animated: true)
      } else {
        self.extensionContext?.completeRequest(returningItems: nil)
      }
    }
  }


  private static let supportedExtensions: Set<String> = [
    "flac", "mp3", "mp4", "mpeg", "mpga", "m4a", "ogg", "wav", "webm",
  ]
}
