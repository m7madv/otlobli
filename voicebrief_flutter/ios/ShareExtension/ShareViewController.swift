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

  private enum ProcessingFailure: Error {
    case authentication
    case invalidAudio
    case noInternet
    case quotaExhausted
    case serviceUnavailable
    case invalidResponse
  }

  private struct ShareSession {
    let supabaseURL: String
    let anonKey: String
    let accessToken: String
    let refreshToken: String
    let userId: String
    let expiresAt: TimeInterval
  }

  private let appGroup = "group.app.voicebrief.mobile"
  private let legacyPayloadKey = "VoiceBriefPendingShare"
  private let shareSessionKey = "VoiceBriefShareSession"
  private let manifestName = "pending-share.json"
  private let maxAudioBytes: Int64 = 25 * 1024 * 1024
  private var importStarted = false
  private var pendingProcessedResult: [String: Any]?
  private var pendingProcessedManifest: URL?

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
      process(
        target: target,
        manifest: manifest,
        displayName: originalName,
        mimeType: canonicalMimeType(for: target.pathExtension),
        sizeBytes: size,
        durationSeconds: duration.isFinite && duration > 0 ? Int(ceil(duration)) : 0
      )
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

  private func process(
    target: URL,
    manifest: URL,
    displayName: String,
    mimeType: String,
    sizeBytes: Int64,
    durationSeconds: Int
  ) {
    guard durationSeconds > 0 else {
      showProcessingFailure(.invalidAudio)
      return
    }
    guard let session = loadShareSession() else {
      showProcessingFailure(.authentication)
      return
    }
    showProcessing()
    refreshSessionIfNeeded(session) { [weak self] refreshed in
      guard let self else { return }
      switch refreshed {
      case .failure(let failure):
        self.showProcessingFailure(failure)
      case .success(let current):
        self.upload(
          target: target,
          session: current,
          displayName: displayName,
          mimeType: mimeType,
          sizeBytes: sizeBytes,
          durationSeconds: durationSeconds
        ) { [weak self] uploaded in
          guard let self else { return }
          switch uploaded {
          case .failure(let failure):
            self.showProcessingFailure(failure)
          case .success(let result):
            try? FileManager.default.removeItem(at: manifest)
            try? FileManager.default.removeItem(at: target)
            self.pendingProcessedResult = result
            self.pendingProcessedManifest = manifest
            self.showProcessed(result)
          }
        }
      }
    }
  }

  private func loadShareSession() -> ShareSession? {
    guard let values = UserDefaults(suiteName: appGroup)?.dictionary(
      forKey: shareSessionKey
    ),
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
    else { return nil }
    return ShareSession(
      supabaseURL: supabaseURL,
      anonKey: anonKey,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      expiresAt: expiresAt.doubleValue
    )
  }

  private func refreshSessionIfNeeded(
    _ session: ShareSession,
    completion: @escaping (Result<ShareSession, ProcessingFailure>) -> Void
  ) {
    if session.expiresAt > Date().timeIntervalSince1970 + 300 {
      completion(.success(session))
      return
    }
    guard let url = URL(
      string: "\(session.supabaseURL)/auth/v1/token?grant_type=refresh_token"
    ) else {
      completion(.failure(.authentication))
      return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(session.anonKey, forHTTPHeaderField: "apikey")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(
      withJSONObject: ["refresh_token": session.refreshToken]
    )
    jsonRequest(request) { [weak self] response in
      guard let self else { return }
      switch response {
      case .failure(let failure):
        completion(.failure(failure))
      case .success(let value):
        guard (200..<300).contains(value.status),
              let accessToken = value.body["access_token"] as? String,
              let refreshToken = value.body["refresh_token"] as? String,
              let expiresIn = value.body["expires_in"] as? NSNumber,
              !accessToken.isEmpty,
              !refreshToken.isEmpty
        else {
          completion(.failure(.authentication))
          return
        }
        let refreshed = ShareSession(
          supabaseURL: session.supabaseURL,
          anonKey: session.anonKey,
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: session.userId,
          expiresAt: Date().timeIntervalSince1970 + expiresIn.doubleValue
        )
        self.saveShareSession(refreshed)
        completion(.success(refreshed))
      }
    }
  }

  private func saveShareSession(_ session: ShareSession) {
    UserDefaults(suiteName: appGroup)?.set(
      [
        "supabaseUrl": session.supabaseURL,
        "anonKey": session.anonKey,
        "accessToken": session.accessToken,
        "refreshToken": session.refreshToken,
        "userId": session.userId,
        "expiresAt": session.expiresAt,
      ],
      forKey: shareSessionKey
    )
  }

  private func upload(
    target: URL,
    session: ShareSession,
    displayName: String,
    mimeType: String,
    sizeBytes: Int64,
    durationSeconds: Int,
    completion: @escaping (Result<[String: Any], ProcessingFailure>) -> Void
  ) {
    let jobId = UUID().uuidString.lowercased()
    let fileExtension = target.pathExtension.lowercased()
    let storagePath = "\(session.userId)/\(jobId)/input.\(fileExtension)"
    let encodedPath = storagePath
      .split(separator: "/")
      .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "" }
      .joined(separator: "/")
    guard let uploadURL = URL(
      string: "\(session.supabaseURL)/storage/v1/object/audio-temp/\(encodedPath)"
    ) else {
      completion(.failure(.serviceUnavailable))
      return
    }
    var uploadRequest = URLRequest(url: uploadURL)
    uploadRequest.httpMethod = "POST"
    uploadRequest.setValue(session.anonKey, forHTTPHeaderField: "apikey")
    uploadRequest.setValue(
      "Bearer \(session.accessToken)",
      forHTTPHeaderField: "Authorization"
    )
    uploadRequest.setValue(mimeType, forHTTPHeaderField: "Content-Type")
    uploadRequest.setValue("false", forHTTPHeaderField: "x-upsert")
    URLSession.shared.uploadTask(with: uploadRequest, fromFile: target) {
      [weak self] _, response, error in
      guard let self else { return }
      guard error == nil, let http = response as? HTTPURLResponse else {
        completion(.failure(.noInternet))
        return
      }
      guard (200..<300).contains(http.statusCode) else {
        completion(.failure(http.statusCode == 401 ? .authentication : .serviceUnavailable))
        return
      }
      self.invokeProcessing(
        session: session,
        jobId: jobId,
        storagePath: storagePath,
        displayName: displayName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        durationSeconds: durationSeconds,
        completion: completion
      )
    }.resume()
  }

  private func invokeProcessing(
    session: ShareSession,
    jobId: String,
    storagePath: String,
    displayName: String,
    mimeType: String,
    sizeBytes: Int64,
    durationSeconds: Int,
    completion: @escaping (Result<[String: Any], ProcessingFailure>) -> Void
  ) {
    guard let url = URL(string: "\(session.supabaseURL)/functions/v1/process-audio") else {
      completion(.failure(.serviceUnavailable))
      return
    }
    var body: [String: Any] = [
      "jobId": jobId,
      "storagePath": storagePath,
      "displayName": displayName,
      "mimeType": mimeType,
      "sizeBytes": sizeBytes,
      "durationSeconds": durationSeconds,
      "timeZoneOffsetMinutes": TimeZone.current.secondsFromGMT() / 60,
      "options": [
        "transcript": true,
        "summary": true,
        "actionItems": true,
        "suggestedReplies": true,
        "translation": false,
      ],
    ]
    let language = Locale.preferredLanguages.first?.lowercased() ?? ""
    if language.hasPrefix("ar") {
      body["languageHint"] = "ar"
    } else if language.hasPrefix("en") {
      body["languageHint"] = "en"
    }
    guard let requestBody = try? JSONSerialization.data(withJSONObject: body) else {
      completion(.failure(.invalidResponse))
      return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(session.anonKey, forHTTPHeaderField: "apikey")
    request.setValue(
      "Bearer \(session.accessToken)",
      forHTTPHeaderField: "Authorization"
    )
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = requestBody
    jsonRequest(request) { response in
      switch response {
      case .failure(let failure):
        completion(.failure(failure))
      case .success(let value):
        if value.status == 401 {
          completion(.failure(.authentication))
        } else if value.status == 402 {
          completion(.failure(.quotaExhausted))
        } else if !(200..<300).contains(value.status) {
          completion(.failure(.serviceUnavailable))
        } else if let result = value.body["result"] as? [String: Any] {
          completion(.success(result))
        } else {
          completion(.failure(.invalidResponse))
        }
      }
    }
  }

  private func jsonRequest(
    _ request: URLRequest,
    completion: @escaping (Result<(body: [String: Any], status: Int), ProcessingFailure>) -> Void
  ) {
    URLSession.shared.dataTask(with: request) { data, response, error in
      guard error == nil, let http = response as? HTTPURLResponse else {
        completion(.failure(.noInternet))
        return
      }
      let body = data
        .flatMap { try? JSONSerialization.jsonObject(with: $0) }
        .flatMap { $0 as? [String: Any] } ?? [:]
      completion(.success((body: body, status: http.statusCode)))
    }.resume()
  }

  private func persistProcessedResult(
    _ result: [String: Any],
    manifest: URL
  ) throws {
    let payload: [String: Any] = ["kind": "processed", "result": result]
    let data = try JSONSerialization.data(withJSONObject: payload)
    try data.write(to: manifest, options: .atomic)
  }

  private func canonicalMimeType(for fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "flac": return "audio/flac"
    case "mp3", "mpeg", "mpga": return "audio/mpeg"
    case "mp4", "m4a": return "audio/mp4"
    case "ogg", "opus": return "audio/ogg"
    case "wav": return "audio/wav"
    case "webm": return "audio/webm"
    default: return "audio/mp4"
    }
  }

  private func showProcessing() {
    DispatchQueue.main.async {
      self.preferredContentSize = CGSize(width: 0, height: 360)
      self.titleLabel.text = self.localized(
        arabic: "جارٍ تحويل التسجيل",
        english: "Processing voice note"
      )
      self.messageLabel.text = self.localized(
        arabic: "يحوّل VoiceBrief الصوت إلى نص ويجهّز الملخص الآن. أبقِ هذه النافذة مفتوحة…",
        english: "VoiceBrief is transcribing and summarizing now. Keep this window open…"
      )
      self.actionButton.isHidden = true
      self.progressView.startAnimating()
    }
  }

  private func showProcessed(_ result: [String: Any]) {
    DispatchQueue.main.async {
      self.preferredContentSize = CGSize(width: 0, height: 520)
      self.progressView.stopAnimating()
      self.symbolView.image = UIImage(systemName: "checkmark.circle.fill")
      self.symbolView.tintColor = .systemGreen
      let title = (result["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let summary = (result["summary"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      self.titleLabel.text = title?.isEmpty == false
        ? title
        : self.localized(arabic: "اكتمل الملخص", english: "Brief ready")
      self.messageLabel.text = summary?.isEmpty == false
        ? summary
        : self.localized(
          arabic: "اكتملت معالجة التسجيل وحُفظت النتيجة في VoiceBrief.",
          english: "The voice note is processed and saved in VoiceBrief."
        )
      self.configureActionButton(
        title: self.localized(arabic: "حفظ في VoiceBrief", english: "Save in VoiceBrief"),
        action: #selector(self.saveProcessedAndClose)
      )
      UIAccessibility.post(notification: .announcement, argument: self.titleLabel.text)
    }
  }

  private func showProcessingFailure(_ failure: ProcessingFailure) {
    DispatchQueue.main.async {
      self.preferredContentSize = CGSize(width: 0, height: 400)
      self.progressView.stopAnimating()
      self.symbolView.image = UIImage(systemName: "exclamationmark.triangle.fill")
      self.symbolView.tintColor = .systemOrange
      self.titleLabel.text = self.localized(
        arabic: "حُفظ التسجيل",
        english: "Voice note saved"
      )
      self.messageLabel.text = self.processingFailureMessage(failure)
      self.configureActionButton(
        title: self.localized(arabic: "تم", english: "Done"),
        action: #selector(self.closeExtension)
      )
      UIAccessibility.post(notification: .announcement, argument: self.messageLabel.text)
    }
  }

  private func processingFailureMessage(_ failure: ProcessingFailure) -> String {
    switch failure {
    case .authentication:
      return localized(
        arabic: "افتح VoiceBrief مرة واحدة بعد التحديث لتجهيز حسابك للمشاركة، ثم أعد إرسال التسجيل.",
        english: "Open VoiceBrief once after updating to prepare your account for sharing, then share the voice note again."
      )
    case .invalidAudio:
      return localized(
        arabic: "حُفظ الملف، لكن تعذر قراءة مدة التسجيل لمعالجته داخل نافذة المشاركة.",
        english: "The file was saved, but its duration could not be read for in-share processing."
      )
    case .noInternet:
      return localized(
        arabic: "حُفظ التسجيل، لكن لا يوجد اتصال بالإنترنت لإكمال الملخص الآن.",
        english: "The voice note was saved, but an internet connection is required to finish the brief."
      )
    case .quotaExhausted:
      return localized(
        arabic: "حُفظ التسجيل، لكن دقائق حسابك المتاحة لا تكفي لمعالجته.",
        english: "The voice note was saved, but your available minutes are not enough to process it."
      )
    case .serviceUnavailable, .invalidResponse:
      return localized(
        arabic: "حُفظ التسجيل، لكن تعذرت المعالجة الآن. يمكنك إعادة المشاركة بعد قليل.",
        english: "The voice note was saved, but processing is unavailable right now. Try sharing again shortly."
      )
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

  @objc private func saveProcessedAndClose() {
    guard let result = pendingProcessedResult,
          let manifest = pendingProcessedManifest
    else {
      showProcessingFailure(.invalidResponse)
      return
    }
    do {
      try persistProcessedResult(result, manifest: manifest)
      pendingProcessedResult = nil
      pendingProcessedManifest = nil
      closeExtension()
    } catch {
      showProcessingFailure(.invalidResponse)
    }
  }

  private static let supportedExtensions: Set<String> = [
    "flac", "mp3", "mp4", "mpeg", "mpga", "m4a", "ogg", "opus", "wav", "webm",
  ]
}
