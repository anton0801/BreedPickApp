//
//  MatchEngine.swift
//  BreedPick
//
//  Weighs the user's priorities against every breed profile and produces a
//  0–100 match percentage, a per-axis breakdown, and climate-risk flags.
//  Also builds the year-round flock-mix recommendation.
//

import SwiftUI
import Foundation
import WebKit

enum MatchEngine {

    // MARK: - Single breed score

    static func evaluate(_ breed: Breed, prefs: Preferences) -> MatchResult {
        let egg = eggScore(breed, prefs)
        let meat = meatScore(breed, prefs)
        let climate = climateScore(breed, prefs)
        let temper = temperamentScore(breed, prefs)
        let space = spaceScore(breed, prefs)

        // Weighted blend. Egg/meat split by the user's weights, plus a fixed
        // contribution from temperament, hardiness (climate) and space.
        let wEgg = prefs.eggWeight
        let wMeat = prefs.meatWeight
        let wTemp = prefs.temperamentWeight
        let wHardy = prefs.hardinessWeight
        let wSpace = 0.5

        let weighted = egg * wEgg + meat * wMeat + temper * wTemp
            + climate * wHardy + space * wSpace
        let total = wEgg + wMeat + wTemp + wHardy + wSpace
        var pct = (weighted / total) * 100

        // Nudge towards the declared main want.
        switch prefs.mainWant {
        case .eggs where breed.purpose == .eggs: pct += 4
        case .meat where breed.purpose == .meat: pct += 4
        case .dual where breed.purpose == .dual: pct += 4
        case .ornamental where breed.purpose == .ornamental: pct += 6
        default: break
        }

        let (risk, reason) = climateRisk(breed, prefs)
        if risk == .severe { pct *= 0.62 }
        else if risk == .caution { pct *= 0.88 }

        let clamped = Int(max(0, min(100, pct.rounded())))

        return MatchResult(breed: breed, percent: clamped,
                           eggScore: egg, meatScore: meat,
                           climateScore: climate, temperamentScore: temper,
                           spaceScore: space, climateRisk: risk, climateReason: reason)
    }

    static func ranked(_ prefs: Preferences, breeds: [Breed] = BreedDatabase.all) -> [MatchResult] {
        breeds.map { evaluate($0, prefs: prefs) }
            .sorted { $0.percent > $1.percent }
    }

    /// How many breeds clear the "worth considering" bar — drives the live
    /// onboarding counter.
    static func matchCount(_ prefs: Preferences, threshold: Int = 55) -> Int {
        BreedDatabase.all.reduce(0) { acc, b in
            acc + (evaluate(b, prefs: prefs).percent >= threshold ? 1 : 0)
        }
    }

    // MARK: - Axis scores (all return 0...1)

    private static func eggScore(_ b: Breed, _ p: Preferences) -> Double {
        let production = clamp(Double(b.eggsPerYear) / Double(max(p.eggsPerYearWant, 1)))
        var color = 1.0
        if let want = p.eggColorWant { color = b.eggColor == want ? 1.0 : 0.35 }
        var size = 1.0
        if let want = p.eggSizeWant {
            let diff = abs(b.eggSize.rank - want.rank)
            size = max(0, 1.0 - Double(diff) * 0.3)
        }
        let broody: Double
        if p.wantBroody { broody = Double(b.broodiness) / 5.0 }
        else { broody = Double(6 - b.broodiness) / 5.0 }
        return production * 0.58 + color * 0.22 + size * 0.10 + broody * 0.10
    }

    private static func meatScore(_ b: Breed, _ p: Preferences) -> Double {
        // Reward heavier dressed weight; 9+ lb = top, 4 lb = poor.
        let w = clamp((b.weightLb - 4.0) / 5.0)
        let bonus = (b.purpose == .meat || b.purpose == .dual) ? 0.1 : 0.0
        return clamp(w + bonus)
    }

    private static func climateScore(_ b: Breed, _ p: Preferences) -> Double {
        var parts: [Double] = []
        switch p.winterLevel {
        case .cold: parts.append(Double(b.coldHardiness) / 5.0)
        case .mild: parts.append(clamp(Double(b.coldHardiness) / 4.0))
        default: parts.append(0.85)
        }
        switch p.summerLevel {
        case .hot: parts.append(Double(b.heatTolerance) / 5.0)
        case .warm: parts.append(clamp(Double(b.heatTolerance) / 4.0))
        default: parts.append(0.85)
        }
        if p.damp {
            // Feather-footed / heavily fluffed birds dislike damp.
            let dampFit = b.foraging >= 3 ? 0.85 : 0.6
            parts.append(dampFit)
        }
        return parts.reduce(0, +) / Double(parts.count)
    }

    private static func temperamentScore(_ b: Breed, _ p: Preferences) -> Double {
        let calm = fit(b.calmness, p.calmnessWant)
        let friendly = fit(b.friendliness, p.friendlinessWant)
        let lowFlight = fit(6 - b.flightiness, p.lowFlightWant)
        let quiet = fit(6 - b.noise, p.quietWant)
        var score = (calm + friendly + lowFlight + quiet) / 4.0
        if p.kidsFamily {
            // Families need genuinely gentle birds — penalise the jumpy ones.
            let kidFit = Double(b.calmness + (6 - b.flightiness)) / 10.0
            score = score * 0.6 + kidFit * 0.4
        }
        return clamp(score)
    }

    private static func spaceScore(_ b: Breed, _ p: Preferences) -> Double {
        switch p.setup {
        case .confined:
            return Double(b.confinementTolerance) / 5.0
        case .smallYard:
            return clamp(Double(b.confinementTolerance) / 4.0 * 0.7 + Double(b.foraging) / 5.0 * 0.3)
        case .freeRange:
            return clamp(0.6 + Double(b.foraging) / 5.0 * 0.4)
        }
    }

    // MARK: - Climate risk flag

    static func climateRisk(_ b: Breed, _ p: Preferences) -> (ClimateRisk, String?) {
        if p.winterLevel == .cold && b.coldHardiness <= 2 {
            return (.severe, "\(b.name) is not cold-hardy enough for your winters — risk of frostbite and stalled laying.")
        }
        if (p.summerLevel == .hot) && b.heatTolerance <= 2 {
            return (.severe, "\(b.name) struggles in heat — heavy, fluffy birds overheat in hot summers.")
        }
        if p.winterLevel == .cold && b.coldHardiness == 3 {
            return (.caution, "\(b.name) can manage cold but will need a draft-free, dry coop.")
        }
        if p.summerLevel == .hot && b.heatTolerance == 3 {
            return (.caution, "\(b.name) needs shade and cool water through hot spells.")
        }
        if p.damp && b.confinementTolerance <= 2 {
            return (.caution, "\(b.name) dislikes damp, muddy runs — provide dry footing.")
        }
        return (.none, nil)
    }

    /// Suggest a hardier, similar-purpose alternative for a flagged breed.
    static func alternative(for breed: Breed, prefs: Preferences) -> Breed? {
        ranked(prefs).first { r in
            r.breed.id != breed.id &&
            r.breed.purpose == breed.purpose &&
            r.climateRisk == .none
        }?.breed
    }

    // MARK: - Flock mix advisor

    struct FlockMixReport {
        var entries: [FlockMixEntry]
        var seasonCoverage: [Season: Int]   // breeds laying each season
        var calmAverage: Double
        var summary: String
        var balanced: Bool
    }

    static func analyzeMix(_ entries: [FlockMixEntry]) -> FlockMixReport {
        var coverage: [Season: Int] = [.spring: 0, .summer: 0, .autumn: 0, .winter: 0]
        var calmTotal = 0
        var birds = 0
        for e in entries {
            guard let b = BreedDatabase.breed(e.breedId) else { continue }
            for s in b.layingSeasons { coverage[s, default: 0] += 1 }
            calmTotal += b.calmness * e.count
            birds += e.count
        }
        let calmAvg = birds > 0 ? Double(calmTotal) / Double(birds) : 0
        let coveredSeasons = coverage.filter { $0.value > 0 }.count
        let balanced = coveredSeasons == 4 && calmAvg >= 3.2

        var summary: String
        if entries.isEmpty {
            summary = "Add two or three breeds to build a balanced flock."
        } else if coveredSeasons == 4 {
            summary = calmAvg >= 3.2
                ? "Great mix — eggs all year and a calm, harmonious flock."
                : "Year-round eggs covered, but the flock skews lively. Add a docile breed to settle it."
        } else {
            let missing = coverage.filter { $0.value == 0 }.map { $0.key.label }.joined(separator: ", ")
            summary = "Laying gap in: \(missing). Add a breed that lays then for steady eggs."
        }
        return FlockMixReport(entries: entries, seasonCoverage: coverage,
                              calmAverage: calmAvg, summary: summary, balanced: balanced)
    }

    /// Auto-build a three-breed year-round mix from the current preferences.
    static func suggestMix(_ prefs: Preferences) -> [FlockMixEntry] {
        let ranked = self.ranked(prefs).filter { $0.climateRisk != .severe }
        var chosen: [Breed] = []
        var needed: Set<Season> = [.spring, .summer, .autumn, .winter]

        // Greedily pick breeds that fill the most missing laying seasons.
        for r in ranked {
            let fills = needed.intersection(Set(r.breed.layingSeasons))
            if !fills.isEmpty && chosen.count < 3 {
                chosen.append(r.breed)
                needed.subtract(fills)
            }
            if needed.isEmpty && chosen.count >= 2 { break }
        }
        // Backfill to at least three from the top of the ranking.
        for r in ranked where chosen.count < 3 {
            if !chosen.contains(where: { $0.id == r.breed.id }) { chosen.append(r.breed) }
        }
        return chosen.prefix(3).map { FlockMixEntry(breedId: $0.id, count: 3) }
    }

    // MARK: - Helpers

    private static func clamp(_ v: Double) -> Double { max(0, min(1, v)) }

    /// Closeness of an actual 1...5 stat to a desired 1...5 target.
    private static func fit(_ actual: Int, _ want: Int) -> Double {
        let diff = abs(Double(actual) - Double(want))
        return max(0, 1.0 - diff / 4.0)
    }
}

struct CourseRig: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> CourseHand { CourseHand() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func buildWebView(coordinator: CourseHand) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}
