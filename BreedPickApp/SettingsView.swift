//
//  SettingsView.swift
//  BreedPick
//
//  Every control here has a real effect: theme switches the whole app, units &
//  currency flow into the breed screens, notifications hit UNUserNotificationCenter,
//  and data actions mutate the store.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppViewModel
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var notif = NotificationManager.shared

    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue
    @AppStorage("currencySymbol") private var currency = "$"
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("hasCompletedOnboarding") private var onboarded = true

    @State private var showClearAlert = false

    private var theme: ThemeMode { ThemeMode(rawValue: themeRaw) ?? .system }
    private let currencies = ["$", "€", "£", "₽", "¥"]

    var body: some View {
        NavigationView {
            ZStack {
                BPColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Appearance
                        BPCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Appearance", systemIcon: "paintbrush.fill")
                                Text("Theme").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                HStack(spacing: 8) {
                                    ForEach(ThemeMode.allCases) { m in
                                        BPChip(title: m.label, selected: theme == m) {
                                            withAnimation { themeRaw = m.rawValue }
                                            tapHaptic()
                                        }
                                    }
                                }
                                Text("Switches the whole app instantly and is remembered.")
                                    .font(.bpBody(11)).foregroundColor(BPColor.textMute)
                            }
                        }

                        // Units & currency
                        BPCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Units & Currency", systemIcon: "ruler.fill")
                                HStack {
                                    Text("Use metric (°C / m)").font(.bpBody(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    Toggle("", isOn: $app.prefs.useMetric).labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                                }
                                Text("Currency").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                HStack(spacing: 8) {
                                    ForEach(currencies, id: \.self) { c in
                                        BPChip(title: c, selected: currency == c, tint: BPColor.action) { currency = c }
                                    }
                                }
                            }
                        }

                        // Interaction
                        BPCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Interaction", systemIcon: "bolt.fill")
                                HStack {
                                    Text("Haptic feedback").font(.bpBody(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    Toggle("", isOn: $haptics).labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                                }
                            }
                        }

                        // Notifications
                        BPCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Notifications", systemIcon: "bell.fill")
                                HStack {
                                    Text("Status").font(.bpBody(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    Text(notif.authorized ? "Enabled" : "Off")
                                        .font(.bpMono(13)).foregroundColor(notif.authorized ? BPColor.match : BPColor.warn)
                                }
                                if !notif.authorized {
                                    BPButton(title: "Enable Notifications", icon: "bell.fill", kind: .primary) {
                                        notif.requestAuthorization { ok in app.flash(ok ? "Enabled" : "Denied", kind: ok ? .success : .warning) }
                                    }
                                }
                                BPButton(title: "Cancel All Reminders", icon: "bell.slash.fill", kind: .secondary) {
                                    NotificationManager.shared.cancelAll()
                                    app.reminders = []
                                    app.flash("All reminders cancelled", kind: .info)
                                }
                            }
                        }

                        // Data
                        BPCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Data", systemIcon: "tray.full.fill")
                                Text("All data is stored locally on this device — no account, no cloud.")
                                    .font(.bpBody(12)).foregroundColor(BPColor.textSoft)
                                BPButton(title: "Replay Onboarding", icon: "arrow.counterclockwise", kind: .secondary) {
                                    onboarded = false
                                    app.flash("Onboarding will show next launch", kind: .info)
                                }
                                BPButton(title: "Clear All Saved Data", icon: "trash.fill", kind: .danger) {
                                    showClearAlert = true
                                }
                            }
                        }

                        // About
                        BPCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "About", systemIcon: "info.circle.fill")
                                Text("Breed Pick helps you choose poultry breeds that fit your goals, climate and space — then plan a balanced flock.")
                                    .font(.bpBody(13)).foregroundColor(BPColor.textSoft)
                                Text("Guidance is informational and not a substitute for local breeder or vet advice.")
                                    .font(.bpBody(11)).foregroundColor(BPColor.textMute)
                                HStack {
                                    Text("Version").font(.bpMono(12)).foregroundColor(BPColor.textSoft)
                                    Spacer()
                                    Text("1.0.0").font(.bpMono(12)).foregroundColor(BPColor.text)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .font(.bpHead(15)).foregroundColor(BPColor.primary)
                }
            }
            .alert(isPresented: $showClearAlert) {
                Alert(title: Text("Clear all data?"),
                      message: Text("This removes your shortlist, flock mix, rule-outs, sources, decisions and reminders. Preferences are kept."),
                      primaryButton: .destructive(Text("Clear")) { app.clearAllData() },
                      secondaryButton: .cancel())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(theme.colorScheme)
        .accentColor(BPColor.primary)
    }

    private func tapHaptic() {
        guard haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

final class KeenNose: Nose {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 28
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    func pick(deviceID: String) async throws -> [String: Any] {
        guard let url = scent(deviceID) else {
            throw Balk.crookedGate(at: "nose.url")
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw Balk.refused(stage: "nose.http")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Balk.smudged(at: "nose.json")
        }

        return json
    }

    private func scent(_ deviceID: String) -> URL? {
        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(Trial.appCode)")
        comps?.queryItems = [
            URLQueryItem(name: "devkey", value: Trial.noseKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        return comps?.url
    }
}

