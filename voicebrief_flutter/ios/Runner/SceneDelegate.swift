import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    importFirstDocument(from: connectionOptions.urlContexts)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    VoiceBriefShareBridge.shared.notifyIfReady()
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    importFirstDocument(from: URLContexts)
    guard URLContexts.contains(where: { $0.url.scheme == "voicebrief" }) else { return }
    VoiceBriefShareBridge.shared.notifyIfReady()
  }

  private func importFirstDocument(from contexts: Set<UIOpenURLContext>) {
    guard let document = contexts.first(where: { $0.url.isFileURL })?.url else { return }
    VoiceBriefShareBridge.shared.importDocument(at: document)
  }
}
