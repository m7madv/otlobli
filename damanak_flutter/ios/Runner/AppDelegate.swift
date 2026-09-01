import Flutter
import StoreKit
import UIKit

final class DamanakStoreKitEntitlementBridge {
  static let shared = DamanakStoreKitEntitlementBridge()

  private static let subscriptionProductIDs: Set<String> = [
    "com.damanak.subscription.starter.monthly",
    "com.damanak.subscription.starter.yearly",
    "com.damanak.subscription.growth.monthly",
    "com.damanak.subscription.growth.yearly",
    "com.damanak.subscription.scale.monthly",
    "com.damanak.subscription.scale.yearly",
  ]

  private var channel: FlutterMethodChannel?

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.damanak.damanak/storekit_entitlements",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "currentSubscriptionEntitlements" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.currentSubscriptionEntitlements(result: result)
    }
    self.channel = channel
  }

  private func currentSubscriptionEntitlements(result: @escaping FlutterResult) {
    Task { @MainActor in
      var entitlements: [[String: Any]] = []
      for await verification in Transaction.currentEntitlements {
        switch verification {
        case .verified(let transaction):
          guard Self.subscriptionProductIDs.contains(transaction.productID) else {
            continue
          }
          var entitlement: [String: Any] = [
            "productId": transaction.productID,
            "originalTransactionId": String(transaction.originalID),
          ]
          if let appAccountToken = transaction.appAccountToken {
            entitlement["appAccountToken"] = appAccountToken.uuidString.lowercased()
          } else {
            entitlement["appAccountToken"] = NSNull()
          }
          entitlements.append(entitlement)
        case .unverified(let transaction, let error):
          guard Self.subscriptionProductIDs.contains(transaction.productID) else {
            continue
          }
          result(
            FlutterError(
              code: "storekit_entitlement_unverified",
              message: "StoreKit could not verify a current Damanak subscription.",
              details: error.localizedDescription
            )
          )
          return
        }
      }
      result(entitlements)
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
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "DamanakStoreKitEntitlementBridge"
    ) {
      DamanakStoreKitEntitlementBridge.shared.configure(messenger: registrar.messenger())
    }
  }
}
