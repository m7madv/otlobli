import Capacitor
import UIKit

@objc(OtlobliSettingsPlugin)
final class OtlobliSettingsPlugin: CAPPlugin, CAPBridgedPlugin {
    let identifier = "OtlobliSettingsPlugin"
    let jsName = "OtlobliSettings"
    let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "openAppSettings", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearBadge", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPushContext", returnType: CAPPluginReturnPromise)
    ]

    @objc func openAppSettings(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let url = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(url) else {
                call.reject("Application settings are unavailable")
                return
            }
            UIApplication.shared.open(url, options: [:]) { opened in
                if opened { call.resolve() }
                else { call.reject("Application settings could not be opened") }
            }
        }
    }

    @objc func clearBadge(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            call.resolve()
        }
    }

    @objc func getPushContext(_ call: CAPPluginCall) {
        #if DEBUG
        let environment = "development"
        #else
        let environment = "production"
        #endif
        call.resolve([
            "environment": environment,
            "osVersion": UIDevice.current.systemVersion
        ])
    }
}

@objc(OtlobliBridgeViewController)
final class OtlobliBridgeViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(OtlobliSheinBrowserPlugin())
        bridge?.registerPluginInstance(OtlobliSettingsPlugin())
    }
}
