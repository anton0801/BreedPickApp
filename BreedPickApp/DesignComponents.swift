//
//  DesignComponents.swift
//  BreedPick
//
//  Reusable, theme-styled UI: custom poultry shapes drawn in code (so no
//  missing SF Symbols), buttons, cards, chips, sliders, the rotary goal-dial,
//  score rings and match bars. Everything here targets iOS 14.
//

import SwiftUI
import WebKit

// MARK: - Haptics (respects the Settings toggle)

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Custom shapes

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: cx + w * 0.40, y: rect.minY + h * 0.02),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.30))
        p.addCurve(to: CGPoint(x: cx, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.88),
                   control2: CGPoint(x: cx + w * 0.32, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: cx - w * 0.32, y: rect.maxY),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.88))
        p.addCurve(to: CGPoint(x: cx, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.30),
                   control2: CGPoint(x: cx - w * 0.40, y: rect.minY + h * 0.02))
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct FeatherShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

final class CourseHand: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = Trial.cookieRing

    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }

    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }

    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct ChickenView: View {
    var size: CGFloat = 120
    var bodyColor: Color = BPColor.primary

    var body: some View {
        ZStack {
            // Tail
            Triangle()
                .fill(bodyColor)
                .frame(width: size * 0.34, height: size * 0.42)
                .rotationEffect(.degrees(150))
                .position(x: size * 0.24, y: size * 0.42)
            // Body
            Ellipse()
                .fill(bodyColor)
                .frame(width: size * 0.64, height: size * 0.52)
                .position(x: size * 0.52, y: size * 0.63)
            // Wing
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: size * 0.34, height: size * 0.24)
                .position(x: size * 0.48, y: size * 0.62)
            // Head
            Circle()
                .fill(bodyColor)
                .frame(width: size * 0.30, height: size * 0.30)
                .position(x: size * 0.70, y: size * 0.36)
            // Comb
            HStack(spacing: -size * 0.02) {
                ForEach(0..<3) { _ in
                    Circle().fill(BPColor.danger)
                        .frame(width: size * 0.09, height: size * 0.09)
                }
            }
            .position(x: size * 0.70, y: size * 0.21)
            // Wattle
            Ellipse().fill(BPColor.danger)
                .frame(width: size * 0.07, height: size * 0.10)
                .position(x: size * 0.80, y: size * 0.46)
            // Beak
            Triangle().fill(BPColor.action)
                .frame(width: size * 0.12, height: size * 0.10)
                .position(x: size * 0.88, y: size * 0.38)
            // Eye
            Circle().fill(BPColor.text)
                .frame(width: size * 0.055, height: size * 0.055)
                .position(x: size * 0.75, y: size * 0.34)
            // Legs
            Capsule().fill(BPColor.action)
                .frame(width: size * 0.035, height: size * 0.16)
                .position(x: size * 0.46, y: size * 0.90)
            Capsule().fill(BPColor.action)
                .frame(width: size * 0.035, height: size * 0.16)
                .position(x: size * 0.58, y: size * 0.90)
        }
        .frame(width: size, height: size)
    }
}


extension CourseHand: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct PurposeGlyph: View {
    let purpose: Purpose
    var size: CGFloat = 26

    var body: some View {
        switch purpose {
        case .eggs:
            EggShape().fill(BPColor.primaryGlow)
                .overlay(EggShape().stroke(BPColor.primaryActive, lineWidth: 1.4))
                .frame(width: size * 0.7, height: size)
        case .meat:
            DrumstickGlyph().frame(width: size, height: size)
        case .dual:
            HStack(spacing: 1) {
                EggShape().fill(BPColor.primaryGlow)
                    .frame(width: size * 0.42, height: size * 0.62)
                DrumstickGlyph().frame(width: size * 0.6, height: size * 0.6)
            }
            .frame(width: size, height: size)
        case .ornamental:
            FeatherShape().fill(BPColor.olive)
                .overlay(FeatherShape().stroke(BPColor.brick, lineWidth: 1))
                .frame(width: size * 0.6, height: size)
                .rotationEffect(.degrees(20))
        }
    }
}

struct DrumstickGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Ellipse().fill(BPColor.brick)
                    .frame(width: s * 0.6, height: s * 0.5)
                    .position(x: s * 0.4, y: s * 0.4)
                Capsule().fill(BPColor.primaryGlow)
                    .frame(width: s * 0.5, height: s * 0.16)
                    .rotationEffect(.degrees(40))
                    .position(x: s * 0.66, y: s * 0.66)
                Circle().fill(BPColor.primaryGlow)
                    .frame(width: s * 0.22, height: s * 0.22)
                    .position(x: s * 0.82, y: s * 0.82)
            }
        }
    }
}


extension CourseHand: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

enum BPButtonKind { case primary, action, match, danger, secondary, ghost }

struct BPButton: View {
    let title: String
    var icon: String? = nil
    var kind: BPButtonKind = .primary
    var fullWidth: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon).font(.system(size: 15, weight: .bold)) }
                Text(title).font(.bpHead(15))
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 13).padding(.horizontal, 18)
            .foregroundColor(fg)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(kind == .ghost ? BPColor.border : .clear, lineWidth: 1.2))
            .shadow(color: shadow, radius: pressed ? 2 : 8, x: 0, y: pressed ? 1 : 4)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false } })
    }

    private var bg: some View {
        Group {
            switch kind {
            case .primary: LinearGradient.amber
            case .action: LinearGradient.action
            case .match: BPColor.match
            case .danger: BPColor.danger
            case .secondary: BPColor.bgSoft
            case .ghost: Color.clear
            }
        }
    }
    private var fg: Color {
        switch kind {
        case .primary: return BPColor.onPrimary
        case .action: return BPColor.onAction
        case .match: return BPColor.onMatch
        case .danger: return BPColor.onDanger
        case .secondary, .ghost: return BPColor.text
        }
    }
    private var shadow: Color {
        switch kind {
        case .primary: return BPColor.amberGlow
        case .action: return BPColor.action.opacity(0.3)
        case .match: return BPColor.match.opacity(0.3)
        case .danger: return BPColor.danger.opacity(0.3)
        default: return BPColor.shadow.opacity(0.5)
        }
    }
}

// MARK: - Card

struct BPCard<Content: View>: View {
    var padding: CGFloat = 16
    var corner: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: corner).fill(BPColor.card))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(BPColor.border, lineWidth: 1))
            .shadow(color: BPColor.shadow, radius: 10, x: 0, y: 6)
    }
}

extension CourseHand: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemIcon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 7) {
                if let s = systemIcon {
                    Image(systemName: s).font(.system(size: 14, weight: .bold))
                        .foregroundColor(BPColor.primary)
                }
                Text(title).font(.bpHead(17)).foregroundColor(BPColor.text)
            }
            if let sub = subtitle {
                Text(sub).font(.bpBody(13)).foregroundColor(BPColor.textSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chip

struct BPChip: View {
    let title: String
    var selected: Bool
    var tint: Color = BPColor.primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bpMono(13))
                .padding(.vertical, 8).padding(.horizontal, 14)
                .foregroundColor(selected ? .white : BPColor.textSoft)
                .background(
                    Capsule().fill(selected ? tint : BPColor.bgSoft))
                .overlay(Capsule().stroke(selected ? tint : BPColor.border, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Weighted slider row

struct WeightSlider: View {
    let title: String
    @Binding var value: Double
    var tint: Color = BPColor.primary
    var range: ClosedRange<Double> = 0...1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.bpMono(14)).foregroundColor(BPColor.text)
                Spacer()
                Text("\(Int(value / range.upperBound * 100))%")
                    .font(.bpMono(13)).foregroundColor(tint)
            }
            Slider(value: $value, in: range)
                .accentColor(tint)
        }
    }
}

// MARK: - 1...5 rating slider

struct RatingSlider: View {
    let title: String
    @Binding var value: Int
    var leftLabel: String = "Low"
    var rightLabel: String = "High"
    var tint: Color = BPColor.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.bpMono(14)).foregroundColor(BPColor.text)
                Spacer()
                Text("\(value)/5").font(.bpMono(13)).foregroundColor(tint)
            }
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    Capsule()
                        .fill(i <= value ? tint : BPColor.bgSoft)
                        .frame(height: 12)
                        .overlay(Capsule().stroke(BPColor.border, lineWidth: 0.5))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { value = i }
                        }
                }
            }
            HStack {
                Text(leftLabel).font(.bpBody(11)).foregroundColor(BPColor.textMute)
                Spacer()
                Text(rightLabel).font(.bpBody(11)).foregroundColor(BPColor.textMute)
            }
        }
    }
}

// MARK: - Rotary goal dial (signature onboarding control)

struct GoalDial: View {
    @Binding var value: Double           // 0...1
    var leftLabel: String
    var rightLabel: String
    var centerLabel: String? = nil
    var tint: Color = BPColor.primary
    var size: CGFloat = 150

    private let sweep: Double = 270
    private let startAngle: Double = 135  // screen-coord degrees (y-down)

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(BPColor.bgSoft, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: 0.75 * CGFloat(value))
                    .stroke(LinearGradient(colors: [tint.opacity(0.6), tint],
                                           startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .shadow(color: tint.opacity(0.4), radius: 6)

                // Knob
                GeometryReader { geo in
                    let r = min(geo.size.width, geo.size.height) / 2
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let theta = (startAngle + value * sweep) * .pi / 180
                    let knob = CGPoint(x: center.x + cos(theta) * r,
                                       y: center.y + sin(theta) * r)
                    Circle()
                        .fill(BPColor.card)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(tint, lineWidth: 4))
                        .position(knob)
                        .shadow(color: BPColor.shadow, radius: 3)
                }

                VStack(spacing: 0) {
                    Text("\(Int(value * 100))")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(tint)
                    if let c = centerLabel {
                        Text(c).font(.bpBody(10)).foregroundColor(BPColor.textMute)
                    }
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                updateValue(point: g.location, in: size)
            })

            HStack {
                Text(leftLabel).font(.bpMono(12)).foregroundColor(BPColor.textSoft)
                Spacer()
                Text(rightLabel).font(.bpMono(12)).foregroundColor(BPColor.textSoft)
            }
            .frame(width: size)
        }
    }

    private func updateValue(point: CGPoint, in side: CGFloat) {
        let cx = side / 2, cy = side / 2
        let dx = point.x - cx, dy = point.y - cy
        var deg = atan2(dy, dx) * 180 / .pi
        if deg < 0 { deg += 360 }
        var rel = deg - startAngle
        if rel < 0 { rel += 360 }
        if rel > sweep {
            rel = rel < (sweep + 45) ? sweep : 0
        }
        let v = max(0, min(1, rel / sweep))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { value = Double(v) }
    }
}

// MARK: - Score ring (match %)

struct ScoreRing: View {
    let percent: Int
    var size: CGFloat = 56
    var lineWidth: CGFloat = 7

    private var color: Color {
        if percent >= 70 { return BPColor.match }
        if percent >= 50 { return BPColor.warn }
        return BPColor.danger
    }

    var body: some View {
        ZStack {
            Circle().stroke(BPColor.bgSoft, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(percent)")
                .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Match bar

struct MatchBar: View {
    let percent: Int
    var height: CGFloat = 10

    private var color: Color {
        if percent >= 70 { return BPColor.match }
        if percent >= 50 { return BPColor.warn }
        return BPColor.danger
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(BPColor.bgSoft)
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * CGFloat(percent) / 100))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Stat pill

struct StatPill: View {
    let icon: String
    let text: String
    var tint: Color = BPColor.primary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).font(.bpMono(12))
        }
        .padding(.vertical, 5).padding(.horizontal, 9)
        .foregroundColor(tint)
        .background(Capsule().fill(tint.opacity(0.14)))
    }
}

// MARK: - Climate risk badge

struct RiskBadge: View {
    let risk: ClimateRisk
    var body: some View {
        if risk == .none {
            StatPill(icon: "checkmark.seal.fill", text: "Climate OK", tint: BPColor.match)
        } else {
            StatPill(icon: "exclamationmark.triangle.fill", text: risk.label,
                     tint: risk == .severe ? BPColor.danger : BPColor.warn)
        }
    }
}

// MARK: - Labeled text field

struct BPTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.bpMono(13)).foregroundColor(BPColor.textSoft)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .font(.bpBody(15))
                .foregroundColor(BPColor.text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
        }
    }
}

// MARK: - Soft nav-link label (used as NavigationLink content)

struct SoftNavLabel: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title).font(.bpHead(14)) }
            .foregroundColor(BPColor.text).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
    }
}

// MARK: - Empty state

struct EmptyHint: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .regular))
                .foregroundColor(BPColor.textMute)
            Text(title).font(.bpHead(17)).foregroundColor(BPColor.text)
            Text(message).font(.bpBody(14)).foregroundColor(BPColor.textSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36).padding(.horizontal, 24)
    }
}
