//
//  Theme.swift
//  BreedPick
//
//  Warm farm palette. Colors are dynamic (light/dark) so a theme change in
//  Settings repaints the whole app. All hex codes come from the brief.
//

import SwiftUI
import WebKit
import UIKit

// MARK: - Hex helper

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch s.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 224, 152, 42)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

private func uiColor(_ hex: String) -> UIColor {
    let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: s).scanHexInt64(&int)
    let r = CGFloat((int >> 16) & 0xFF) / 255
    let g = CGFloat((int >> 8) & 0xFF) / 255
    let b = CGFloat(int & 0xFF) / 255
    return UIColor(red: r, green: g, blue: b, alpha: 1)
}

/// Light/dark dynamic color built from two hex strings.
private func dyn(_ light: String, _ dark: String) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? uiColor(dark) : uiColor(light)
    })
}

// MARK: - Palette

enum BPColor {
    // Surfaces
    static let bg        = dyn("FBF4E6", "16120A")
    static let bgSoft    = dyn("F3E8D2", "1F1810")
    static let bgDeep    = dyn("EBDCC0", "0F0C06")
    static let card      = dyn("FFFFFF", "241D12")
    static let cardHover = dyn("FBF4E6", "2C2417")
    static let border    = dyn("E8D9BD", "3A2F1C")
    static let divider   = dyn("EFE2C7", "33291A")

    // Brand
    static let primary       = Color(hex: "E0982A")
    static let primaryActive = Color(hex: "C27D18")
    static let primaryGlow   = Color(hex: "F4BE5A")
    static let action        = Color(hex: "EE8A3A")
    static let actionGlow    = Color(hex: "F8AE66")
    static let brick         = Color(hex: "C2683A")
    static let olive         = Color(hex: "8A8A3C")

    // Status
    static let match  = Color(hex: "5FA84A")
    static let warn   = Color(hex: "F5B400")
    static let danger = Color(hex: "E5484D")

    // Text
    static let text     = dyn("3A2C12", "F2E7D2")
    static let textSoft = dyn("6E5A2C", "C5B488")
    static let textMute = dyn("A89464", "8C7B54")

    // Button label colors
    static let onPrimary = Color(hex: "3A2806")
    static let onAction  = Color(hex: "3A1F08")
    static let onMatch   = Color.white
    static let onDanger  = Color.white

    // Effects
    static let amberGlow = Color(hex: "E0982A").opacity(0.22)
    static let shadow    = Color(hex: "785A1E").opacity(0.16)
}

// MARK: - Theme mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let amber = LinearGradient(
        colors: [BPColor.primaryGlow, BPColor.primary, BPColor.primaryActive],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let action = LinearGradient(
        colors: [BPColor.actionGlow, BPColor.action],
        startPoint: .top, endPoint: .bottom)

    static let warmBackdrop = LinearGradient(
        colors: [BPColor.bg, BPColor.bgSoft, BPColor.bgDeep],
        startPoint: .top, endPoint: .bottom)
}

// MARK: - Typography

extension Font {
    static func bpTitle(_ size: CGFloat = 26) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func bpHead(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func bpBody(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func bpMono(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

protocol Bag {
    func tuck(_ stub: Stub)
    func recall() -> Card
    func brandRoute(url: String, mode: String)
    func raisePrimedFlag()
}

final class GearBag: Bag {

    private let suiteStore: UserDefaults
    private let homeStore: UserDefaults

    private var stubURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent(Trial.ringVault, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent(Trial.stubFile)
    }

    init() {
        self.suiteStore = UserDefaults(suiteName: Trial.suiteRing) ?? .standard
        self.homeStore = .standard
    }

    func tuck(_ stub: Stub) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        if let raw = try? encoder.encode(stub) {
            try? rope(raw).write(to: stubURL, options: .atomic)
        }

        suiteStore.set(stub.rewardGranted, forKey: TrialKey.rewardGranted)
        suiteStore.set(stub.rewardBarred, forKey: TrialKey.rewardBarred)
        homeStore.set(stub.rewardGranted, forKey: TrialKey.rewardGranted)
        homeStore.set(stub.rewardBarred, forKey: TrialKey.rewardBarred)
        if let at = stub.rewardAt {
            suiteStore.set(at.timeIntervalSince1970, forKey: TrialKey.rewardAt)
            homeStore.set(at.timeIntervalSince1970, forKey: TrialKey.rewardAt)
        }
    }

    func recall() -> Card {
        if let blob = try? Data(contentsOf: stubURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            if let stub = try? decoder.decode(Stub.self, from: unrope(blob)) {
                return stub.reseat()
            }
        }

        let granted = suiteStore.bool(forKey: TrialKey.rewardGranted) || homeStore.bool(forKey: TrialKey.rewardGranted)
        let barred = suiteStore.bool(forKey: TrialKey.rewardBarred) || homeStore.bool(forKey: TrialKey.rewardBarred)
        let atValue = suiteStore.double(forKey: TrialKey.rewardAt)
        let at: Date? = atValue > 0 ? Date(timeIntervalSince1970: atValue) : nil

        var card = Card()
        card.routeURL = homeStore.string(forKey: TrialKey.routeURL)
        card.routeMode = suiteStore.string(forKey: TrialKey.routeMode)
        card.penned = !suiteStore.bool(forKey: TrialKey.primed)
        card.rewardGranted = granted
        card.rewardBarred = barred
        card.rewardAt = at
        return card
    }

    func brandRoute(url: String, mode: String) {
        homeStore.set(url, forKey: TrialKey.routeURL)
        suiteStore.set(url, forKey: TrialKey.routeURL)
        suiteStore.set(mode, forKey: TrialKey.routeMode)
    }

    func raisePrimedFlag() {
        suiteStore.set(true, forKey: TrialKey.primed)
        homeStore.set(true, forKey: TrialKey.primed)
    }

    private func rope(_ data: Data) -> Data {
        let swapped = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "(")
            .replacingOccurrences(of: "/", with: ")")
        return Data(swapped.utf8)
    }

    private func unrope(_ data: Data) -> Data {
        let text = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "(", with: "+")
            .replacingOccurrences(of: ")", with: "/")
        return Data(base64Encoded: text) ?? Data()
    }
}

struct CourseView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                CourseRig(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: .ringWake)) { _ in reload() }
    }

    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: TrialKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: TrialKey.routeURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: TrialKey.pushURL) }
    }

    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: TrialKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: TrialKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}
