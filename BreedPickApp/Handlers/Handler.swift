import Foundation
import Combine
import AppsFlyerLib

@MainActor
final class Handler {

    private let ring: Ring
    private var card: Card
    private var rung = false
    private var ribboned = false
    private var running = false

    private let scoreSubject = PassthroughSubject<Score, Never>()
    var scoreStream: AnyPublisher<Score, Never> {
        scoreSubject.eraseToAnyPublisher()
    }

    init(ring: Ring) {
        self.ring = ring
        self.card = Card()
    }

    func ensureRung() {
        guard !rung else { return }
        rung = true
        card = ring.bag.recall()
    }

    func takeCues(_ data: [String: Any]) {
        ensureRung()
        for (key, value) in data { card.cues[key] = "\(value)" }
    }

    func takeMarks(_ data: [String: Any]) {
        ensureRung()
        for (key, value) in data { card.marks[key] = "\(value)" }
    }

    func run() async {
        ensureRung()
        guard !ribboned, !running else { return }
        running = true
        defer { running = false }

        let rules = rulebook()
        var rounds = 0
        while rounds < 8 {
            rounds += 1
            guard let rule = rules.first(where: { $0.gate() }) else {
                scoreSubject.send(.stall)
                return
            }
            switch await rule.fire() {
            case .loop:
                continue
            case .halt:
                return
            }
        }
    }

    func acceptReward(then wrap: @escaping () -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            let granted = await self.ring.reward.offer()
            let now = Date()
            self.card.rewardGranted = granted
            self.card.rewardBarred = !granted
            self.card.rewardAt = now
            self.ring.bag.tuck(self.card.stub())
            self.scoreSubject.send(.qualify)
            wrap()
        }
    }

    func skipReward() {
        ensureRung()
        card.rewardAt = Date()
        ring.bag.tuck(card.stub())
        scoreSubject.send(.qualify)
    }

    func reportScratch() -> Bool {
        ensureRung()
        return ribbon()
    }

    private func rulebook() -> [Rule] {
        [
            Rule(gate: { self.stashReady }, fire: { self.finishStash() }),
            Rule(gate: { !self.card.hasCues }, fire: { self.stallOut() }),
            Rule(gate: { self.weaveDue }, fire: { await self.weave() }),
            Rule(gate: { self.card.hasCues }, fire: { await self.tallyRun() })
        ]
    }

    private var stashReady: Bool {
        (UserDefaults.standard.string(forKey: TrialKey.pushURL)?.isEmpty == false)
    }

    private var weaveDue: Bool {
        card.organicScent && card.penned && !card.weaved
    }

    private func finishStash() -> Step {
        let stash = UserDefaults.standard.string(forKey: TrialKey.pushURL) ?? ""
        ribbonUp(clear(stash))
        return .halt
    }

    private func stallOut() -> Step {
        scoreSubject.send(.stall)
        return .halt
    }

    private func weave() async -> Step {
        card.weaved = true
        ring.bag.tuck(card.stub())

        try? await Task.sleep(nanoseconds: 5_000_000_000)

        guard !card.cleared else { return .halt }

        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        do {
            let caught = try await ring.nose.pick(deviceID: deviceID).mapValues { "\($0)" }
            guard !caught.isEmpty else { return .loop }

            let blended = card.marks.reduce(into: caught) { acc, pair in
                acc[pair.key] = acc[pair.key] ?? pair.value
            }
            card.cues = blended
            ring.bag.tuck(card.stub())
        } catch {
        }

        return .loop
    }

    private func tallyRun() async -> Step {
        do {
            let url = try await ring.judge.tally(load: card.cues.mapValues { $0 as Any })
            ribbonUp(clear(url))
        } catch {
            ribbonUp(.eliminate)
        }
        return .halt
    }

    private func clear(_ url: String) -> Score {
        let needsReward = card.rewardDue

        card.routeURL = url
        card.routeMode = "Active"
        card.penned = false
        card.cleared = true

        ring.bag.tuck(card.stub())
        ring.bag.brandRoute(url: url, mode: "Active")
        ring.bag.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: TrialKey.pushURL)

        return needsReward ? .reward : .qualify
    }

    private func ribbonUp(_ score: Score) {
        if ribbon() {
            scoreSubject.send(score)
        }
    }

    @discardableResult
    private func ribbon() -> Bool {
        guard !ribboned else { return false }
        ribboned = true
        return true
    }
}
