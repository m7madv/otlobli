import UIKit
import AVFoundation
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private enum ImportFailure: Error {
    case noAudio
    case unreadableAudio
    case oversizedAudio
    case appGroupUnavailable
    case writeFailed
  }

  private let appGroup = "group.app.voicebrief.mobile"
  private let legacyPayloadKey = "VoiceBriefPendingShare"
  private let manifestName = "pending-share.json"
  private let maxAudioBytes: Int64 = 25 * 1024 * 1024
  private var importStarted = false
  private var openAttemptInProgress = false

  private let symbolView: UIImageView = {
    let view = UIImageView(image: UIImage(systemName: "waveform.circle.fill"))
    view.tintColor = .systemBlue
    view.contentMode = .scaleAspectFit
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .title2)
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private let messageLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private let progressView: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView(style: .medium)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var actionButton: UIButton = {
    let button = UIButton(type: .system)
    button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.backgroundColor = .systemBlue
    button.tintColor = .white
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = 12
    button.contentEdgeInsets = UIEdgeInsets(top: 13, left: 24, bottom: 13, right: 24)
    button.isHidden = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private var isArabic: Bool {
    Locale.preferredLanguages.first?.lowercased().hasPrefix("ar") == true
  }

  override func loadView() {
    let root = UIView()
    root.backgroundColor = .systemBackground
    view = root

    let stack = UIStackView(arrangedSubviews: [
      symbolView,
      titleLabel,
      messageLabel,
      progressView,
      actionButton,
    ])
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 14
    stack.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: root.safeAreaLayoutGuide.trailingAnchor, constant: -24),
      stack.centerXAnchor.constraint(equalTo: root.safeAreaLayoutGuide.centerXAnchor),
      stack.topAnchor.constraint(greaterThanOrEqualTo: root.safeAreaLayoutGuide.topAnchor, constant: 28),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: root.safeAreaLayoutGuide.bottomAnchor, constant: -24),
      stack.centerYAnchor.constraint(equalTo: root.safeAreaLayoutGuide.centerYAnchor),
      symbolView.widthAnchor.constraint(equalToConstant: 54),
      symbolView.heightAnchor.constraint(equalToConstant: 54),
      actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
      actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    preferredContentSize = CGSize(width: 0, height: 300)
    titleLabel.text = localized(
      arabic: "إضافة إلى VoiceBrief",
      english: "Add to VoiceBrief"
    )
    messageLabel.text = localized(
      arabic: "جارٍ نسخ الرسالة الصوتية بأمان…",
      english: "Securely copying the voice note…"
    )
    progressView.startAnimating()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !importStarted else { return }
    importStarted = true
    importFirstAudioAttachment()
  }

  private func importFirstAudioAttachment() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments,
          let selection = attachments.compactMap({ provider -> (NSItemProvider, String)? in
            guard let identifier = bestTypeIdentifier(for: provider) else { return nil }
            return (provider, identifier)
          }).first
    else {
      showFailure(.noAudio)
      return
    }

    let provider = selection.0
    let typeIdentifier = selection.1
    if UTType(typeIdentifier)?.conforms(to: .fileURL) == true {
      provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
        guard let self, error == nil else {
          self?.showFailure(.unreadableAudio)
          return
        }
        let source: URL?
        if let url = item as? URL {
          source = url
        } else if let url = item as? NSURL {
          source = url as URL
        } else {
          source = nil
        }
        guard let source else {
          self.showFailure(.unreadableAudio)
          return
        }
        self.persist(source: source, provider: provider, typeIdentifier: typeIdentifier)
      }
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] source, error in
      guard let self, error == nil, let source else {
        self?.showFailure(.unreadableAudio)
        return
      }
      self.persist(source: source, provider: provider, typeIdentifier: typeIdentifier)
    }
  }

  private func persist(
    source: URL,
    provider: NSItemProvider,
    typeIdentifier: String
  ) {
    do {
      let size = try fileSize(source)
      guard size > 0 else { throw ImportFailure.unreadableAudio }
      guard size <= maxAudioBytes else { throw ImportFailure.oversizedAudio }
      guard let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroup
      ) else {
        throw ImportFailure.appGroupUnavailable
      }
      let incoming = container.appendingPathComponent("Incoming", isDirectory: true)
      try FileManager.default.createDirectory(
        at: incoming,
        withIntermediateDirectories: true
      )
      let manifest = incoming.appendingPathComponent(manifestName)
      removePreviousPayload(manifest: manifest)

      let originalName = normalizedAudioName(
        provider.suggestedName ?? source.lastPathComponent,
        typeIdentifier: typeIdentifier
      )
      let target = incoming.appendingPathComponent("\(UUID().uuidString)-\(originalName)")
      try FileManager.default.copyItem(at: source, to: target)
      let mime = UTType(filenameExtension: target.pathExtension)?.preferredMIMEType
        ?? UTType(typeIdentifier)?.preferredMIMEType
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
      do {
        let data = try JSONSerialization.data(withJSONObject: payload)
        try data.write(to: manifest, options: .atomic)
        UserDefaults(suiteName: appGroup)?.removeObject(forKey: legacyPayloadKey)
      } catch {
        try? FileManager.default.removeItem(at: target)
        throw ImportFailure.writeFailed
      }
      showSuccessAndOpenApp()
    } catch let failure as ImportFailure {
      showFailure(failure)
    } catch {
      showFailure(.writeFailed)
    }
  }

  private func fileSize(_ source: URL) throws -> Int64 {
    let values = try source.resourceValues(forKeys: [.fileSizeKey])
    if let size = values.fileSize, size > 0 { return Int64(size) }
    let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
    return (attributes[.size] as? NSNumber)?.int64Value ?? 0
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

  private func bestTypeIdentifier(for provider: NSItemProvider) -> String? {
    let identifiers = provider.registeredTypeIdentifiers
    if let audio = identifiers.first(where: {
      UTType($0)?.conforms(to: .audio) == true
    }) {
      return audio
    }
    if let audioLike = identifiers.first(where: {
      let value = $0.lowercased()
      return value.contains("audio") || value.contains("opus") || value.contains("ogg")
    }) {
      return audioLike
    }
    let suggestedExtension = URL(fileURLWithPath: provider.suggestedName ?? "")
      .pathExtension.lowercased()
    guard Self.supportedExtensions.contains(suggestedExtension) else { return nil }
    return identifiers.first(where: {
      guard let type = UTType($0) else { return false }
      return type.conforms(to: .fileURL)
        || type.conforms(to: .data)
        || type.conforms(to: .item)
    }) ?? identifiers.first
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

  private func showSuccessAndOpenApp() {
    DispatchQueue.main.async {
      self.progressView.stopAnimating()
      self.symbolView.image = UIImage(systemName: "checkmark.circle.fill")
      self.symbolView.tintColor = .systemGreen
      self.titleLabel.text = self.localized(
        arabic: "تم استيراد التسجيل",
        english: "Voice note imported"
      )
      self.messageLabel.text = self.localized(
        arabic: "جارٍ فتح VoiceBrief والتسجيل جاهز للتحويل…",
        english: "Opening VoiceBrief with your voice note ready to process…"
      )
      self.actionButton.isHidden = true
      UIAccessibility.post(notification: .announcement, argument: self.titleLabel.text)
      self.openContainingApp()
    }
  }

  @objc private func openContainingApp() {
    guard !openAttemptInProgress else { return }
    guard let url = URL(string: "voicebrief://shared-audio"),
          let context = extensionContext
    else {
      showOpenFallback()
      return
    }
    openAttemptInProgress = true
    context.open(url) { [weak self] opened in
      DispatchQueue.main.async {
        guard let self else { return }
        self.openAttemptInProgress = false
        if opened {
          context.completeRequest(returningItems: nil)
        } else {
          self.showOpenFallback()
        }
      }
    }
  }

  private func showOpenFallback() {
    DispatchQueue.main.async {
      self.messageLabel.text = self.localized(
        arabic: "حُفظ التسجيل، لكن iOS منع فتح التطبيق تلقائيًا. اضغط «فتح VoiceBrief» للمحاولة مرة أخرى.",
        english: "Your voice note is saved, but iOS prevented the app from opening automatically. Tap Open VoiceBrief to try again."
      )
      self.configureActionButton(
        title: self.localized(arabic: "فتح VoiceBrief", english: "Open VoiceBrief"),
        action: #selector(self.openContainingApp)
      )
      UIAccessibility.post(notification: .announcement, argument: self.messageLabel.text)
    }
  }

  private func showFailure(_ failure: ImportFailure) {
    DispatchQueue.main.async {
      self.progressView.stopAnimating()
      self.symbolView.image = UIImage(systemName: "exclamationmark.triangle.fill")
      self.symbolView.tintColor = .systemOrange
      self.titleLabel.text = self.localized(
        arabic: "تعذر استيراد التسجيل",
        english: "Import failed"
      )
      self.messageLabel.text = self.failureMessage(failure)
      self.configureActionButton(
        title: self.localized(arabic: "إغلاق", english: "Close"),
        action: #selector(self.closeExtension)
      )
      UIAccessibility.post(notification: .announcement, argument: self.messageLabel.text)
    }
  }

  private func configureActionButton(title: String, action: Selector) {
    actionButton.removeTarget(nil, action: nil, for: .allEvents)
    actionButton.setTitle(title, for: .normal)
    actionButton.addTarget(self, action: action, for: .touchUpInside)
    actionButton.isHidden = false
  }

  private func failureMessage(_ failure: ImportFailure) -> String {
    switch failure {
    case .noAudio:
      return localized(
        arabic: "لم يرسل واتساب ملفًا صوتيًا يمكن قراءته. اختر الرسالة الصوتية وحدها ثم أعد المشاركة.",
        english: "WhatsApp did not provide a readable audio file. Select only the voice note and share again."
      )
    case .unreadableAudio:
      return localized(
        arabic: "تعذر قراءة هذا الملف الصوتي. حاول تنزيل الرسالة في واتساب ثم أعد المشاركة.",
        english: "This audio file could not be read. Download the voice note in WhatsApp, then share it again."
      )
    case .oversizedAudio:
      return localized(
        arabic: "يجب أن يكون حجم التسجيل أقل من 25 ميجابايت.",
        english: "The voice note must be smaller than 25 MB."
      )
    case .appGroupUnavailable:
      return localized(
        arabic: "نسخة التطبيق الحالية لا تملك صلاحية التخزين المشترك. يجب توقيع التطبيق وإضافة المشاركة مع App Groups.",
        english: "This build cannot access shared storage. The app and Share Extension must be signed with App Groups."
      )
    case .writeFailed:
      return localized(
        arabic: "تعذر حفظ التسجيل للتطبيق. أعد المحاولة بعد فتح VoiceBrief مرة واحدة.",
        english: "The voice note could not be saved for the app. Open VoiceBrief once, then try again."
      )
    }
  }

  private func localized(arabic: String, english: String) -> String {
    isArabic ? arabic : english
  }

  @objc private func closeExtension() {
    extensionContext?.completeRequest(returningItems: nil)
  }

  private static let supportedExtensions: Set<String> = [
    "flac", "mp3", "mp4", "mpeg", "mpga", "m4a", "ogg", "opus", "wav", "webm",
  ]
}
