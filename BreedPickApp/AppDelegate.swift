import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

protocol Igniter: AnyObject {
    func fireCore()
    func fireTrack()
    func fireSignal()
    func fireWatch()
}

extension Igniter {
    func ignite() {
        fireCore()
        fireTrack()
        fireSignal()
        fireWatch()
    }
}

enum Trial {
    static let appCode = "6784587851"
    static let judgeEndpoint = "https://breedpick.com/config.php"
    static let suiteRing = "group.breedpick.ring"
    static let stubFile = "bp_card_stub.json"
    static let cookieRing = "breedpick_ring"
    static let noseKey = "7HyhrSEVwE97kQjgTY4xdG"
    static let ringVault = "BreedPickRing"
}

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    private let braid = Braid()
    private let yip = Yip()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        ignite()

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            yip.yip(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    @objc private func onActivation() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: TrialKey.attStatus)
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func application(
           _ application: UIApplication,
           didFailToRegisterForRemoteNotificationsWithError error: Error
       ) {
           print("APNs registration FAILED: \(error.localizedDescription)")
       }
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("push token didReceiveRegistrationToken ")
        messaging.token { token, err in
            guard err == nil, let t = token else {
                print("push token didReceiveRegistrationToken received error \(err?.localizedDescription ?? "")")
                return
            }
            print("push token didReceiveRegistrationToken \(token) received")
            UserDefaults.standard.set(t, forKey: TrialKey.fcm)
            UserDefaults.standard.set(t, forKey: TrialKey.push)
            UserDefaults(suiteName: Trial.suiteRing)?.set(t, forKey: TrialKey.sharedFcm)
        }
    }

    fileprivate func relayCues(_ data: [AnyHashable: Any]) { braid.takeCues(data) }
    fileprivate func relayMarks(_ data: [AnyHashable: Any]) { braid.takeMarks(data) }
    fileprivate func relayPush(_ data: [AnyHashable: Any]) { yip.yip(data) }
}

extension AppDelegate: Igniter {
    func fireCore() {
        FirebaseApp.configure()
    }

    func fireTrack() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Trial.noseKey
        sdk.appleAppID = Trial.appCode
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }

    func fireSignal() {
        Messaging.messaging().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }

    func fireWatch() {
        UNUserNotificationCenter.current().delegate = self
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        relayPush(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        relayPush(response.notification.request.content.userInfo)
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        relayPush(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        relayCues(data)
    }

    func onConversionDataFail(_ error: Error) {
    }

    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        relayMarks(link.clickEvent)
    }
}
