import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    VoiceBriefShareBridge.shared.notifyIfReady()
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard URLContexts.contains(where: { $0.url.scheme == "voicebrief" }) else { return }
    VoiceBriefShareBridge.shared.notifyIfReady()
  }
}
