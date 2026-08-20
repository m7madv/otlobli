import Capacitor

@objc(OtlobliBridgeViewController)
final class OtlobliBridgeViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(OtlobliSheinBrowserPlugin())
        bridge?.registerPluginInstance(SheinCleanBrowserPlugin())
    }
}
