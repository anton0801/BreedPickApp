//
//  AppViewModel.swift
//  BreedPick
//
//  App-wide observable state: preferences, shortlist, flock mix, rule-outs,
//  reminders, decisions and the global toast. Every mutation persists to
//  UserDefaults immediately.
//

import SwiftUI
import Combine

final class AppViewModel: ObservableObject {

    // MARK: - Persisted collections

    @Published var prefs: Preferences { didSet { Store.save(prefs, StoreKey.prefs) } }
    @Published var shortlist: [ShortlistItem] { didSet { Store.save(shortlist, StoreKey.shortlist) } }
    @Published var flockMix: [FlockMixEntry] { didSet { Store.save(flockMix, StoreKey.flockMix) } }
    @Published var ruleOuts: [RuleOutNote] { didSet { Store.save(ruleOuts, StoreKey.ruleOuts) } }
    @Published var careNotes: [CareNote] { didSet { Store.save(careNotes, StoreKey.careNotes) } }
    @Published var sourceCosts: [SourceCost] { didSet { Store.save(sourceCosts, StoreKey.sourceCosts) } }
    @Published var reminders: [Reminder] { didSet { Store.save(reminders, StoreKey.reminders) } }
    @Published var decisions: [DecisionRecord] { didSet { Store.save(decisions, StoreKey.decisions) } }

    // MARK: - Transient UI state

    @Published var selectedTab: Int = 0
    @Published var showSettings: Bool = false
    @Published var toast: ToastMessage? = nil
    /// Breeds the Compare screen is showing; shared so a Breed Card can push one in.
    @Published var compareSelection: [String] = []

    private var toastWork: DispatchWorkItem?

    // MARK: - Init

    init() {
        prefs       = Store.load(Preferences.self, StoreKey.prefs, default: Preferences())
        shortlist   = Store.load([ShortlistItem].self, StoreKey.shortlist, default: [])
        flockMix    = Store.load([FlockMixEntry].self, StoreKey.flockMix, default: [])
        ruleOuts    = Store.load([RuleOutNote].self, StoreKey.ruleOuts, default: [])
        careNotes   = Store.load([CareNote].self, StoreKey.careNotes, default: [])
        sourceCosts = Store.load([SourceCost].self, StoreKey.sourceCosts, default: [])
        reminders   = Store.load([Reminder].self, StoreKey.reminders, default: [])
        decisions   = Store.load([DecisionRecord].self, StoreKey.decisions, default: [])
    }

    // MARK: - Derived data

    var rankedMatches: [MatchResult] { MatchEngine.ranked(prefs) }

    func match(for breed: Breed) -> MatchResult { MatchEngine.evaluate(breed, prefs: prefs) }

    var liveMatchCount: Int { MatchEngine.matchCount(prefs) }

    var climateFlagged: [MatchResult] {
        rankedMatches.filter { $0.climateRisk != .none }
    }

    // MARK: - Toast

    func flash(_ text: String, kind: ToastMessage.Kind = .success) {
        toastWork?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toast = ToastMessage(text: text, kind: kind)
        }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.toast = nil }
        }
        toastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    // MARK: - Shortlist

    func isShortlisted(_ id: String) -> Bool { shortlist.contains { $0.breedId == id } }

    func toggleShortlist(_ breed: Breed) {
        if let idx = shortlist.firstIndex(where: { $0.breedId == breed.id }) {
            shortlist.remove(at: idx)
            flash("Removed \(breed.name) from shortlist", kind: .info)
        } else {
            shortlist.append(ShortlistItem(breedId: breed.id, rank: shortlist.count + 1))
            flash("Added \(breed.name) to shortlist")
        }
    }

    func updateShortlist(_ item: ShortlistItem) {
        if let idx = shortlist.firstIndex(where: { $0.id == item.id }) { shortlist[idx] = item }
    }

    func removeShortlist(_ id: String) {
        shortlist.removeAll { $0.breedId == id }
    }

    // MARK: - Flock mix

    func inMix(_ id: String) -> Bool { flockMix.contains { $0.breedId == id } }

    func toggleMix(_ id: String) {
        if let idx = flockMix.firstIndex(where: { $0.breedId == id }) {
            flockMix.remove(at: idx)
        } else if flockMix.count < 5 {
            flockMix.append(FlockMixEntry(breedId: id))
        } else {
            flash("A mix of up to 5 breeds is plenty", kind: .warning)
        }
    }

    func setMixCount(_ id: String, _ count: Int) {
        if let idx = flockMix.firstIndex(where: { $0.breedId == id }) {
            flockMix[idx].count = max(1, count)
        }
    }

    // MARK: - Care notes / source

    func careNote(for id: String) -> CareNote {
        careNotes.first { $0.breedId == id } ?? CareNote(breedId: id)
    }

    func saveCareNote(_ note: CareNote) {
        if let idx = careNotes.firstIndex(where: { $0.breedId == note.breedId }) { careNotes[idx] = note }
        else { careNotes.append(note) }
    }

    func saveSourceCost(_ s: SourceCost) {
        if let idx = sourceCosts.firstIndex(where: { $0.id == s.id }) { sourceCosts[idx] = s }
        else { sourceCosts.append(s) }
    }

    func sources(for id: String) -> [SourceCost] { sourceCosts.filter { $0.breedId == id } }

    // MARK: - Rule-outs

    func addRuleOut(_ note: RuleOutNote) {
        ruleOuts.insert(note, at: 0)
    }

    func removeRuleOut(_ id: UUID) { ruleOuts.removeAll { $0.id == id } }

    func isRuledOut(_ breedId: String) -> Bool { ruleOuts.contains { $0.breedId == breedId } }

    // MARK: - Reminders

    func addReminder(_ r: Reminder) {
        reminders.insert(r, at: 0)
        NotificationManager.shared.schedule(r)
    }

    func updateReminder(_ r: Reminder) {
        if let idx = reminders.firstIndex(where: { $0.id == r.id }) { reminders[idx] = r }
        NotificationManager.shared.schedule(r)
    }

    func removeReminder(_ r: Reminder) {
        reminders.removeAll { $0.id == r.id }
        NotificationManager.shared.cancel(r.id)
    }

    func toggleReminder(_ r: Reminder) {
        var copy = r
        copy.enabled.toggle()
        updateReminder(copy)
    }

    // MARK: - Decisions

    func addDecision(_ d: DecisionRecord) { decisions.insert(d, at: 0) }
    func removeDecision(_ id: UUID) { decisions.removeAll { $0.id == id } }

    // MARK: - Reset (used by Settings)

    func clearAllData() {
        shortlist = []; flockMix = []; ruleOuts = []
        careNotes = []; sourceCosts = []; decisions = []
        reminders = []
        NotificationManager.shared.cancelAll()
        flash("All saved data cleared", kind: .info)
    }
}

// MARK: - Toast model

struct ToastMessage: Equatable {
    enum Kind { case success, info, warning, error }
    let text: String
    var kind: Kind = .success

    var color: Color {
        switch kind {
        case .success: return BPColor.match
        case .info: return BPColor.primary
        case .warning: return BPColor.warn
        case .error: return BPColor.danger
        }
    }
    var glyph: String {
        switch kind {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

@MainActor
final class Slate: ObservableObject {

    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false

    private let handler: Handler
    private var uiLocked = false

    init() {
        self.handler = Steward.shared.enter(Handler.self)
        wireScores()
    }

    deinit {
        deadlineTask?.cancel()
    }

    private func wireScores() {
        handler.scoreStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in
                self?.settle(score)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?

    func ignite() {
        handler.ensureRung()
        armDeadline()
    }

    func ingestCues(_ data: [String: Any]) {
        Task {
            handler.takeCues(data)
            await handler.run()
        }
    }
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    private func settle(_ score: Score) {
        guard !uiLocked else { return }

        switch score {
        case .stall:
            break
        case .reward:
            showPermissionPrompt = true
        case .qualify:
            navigateToWeb = true
        case .eliminate:
            navigateToMain = true
        }
    }

    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self = self else { return }
            if self.handler.reportScratch() {
                self.settle(.eliminate)
            }
        }
    }
    
    func ingestMarks(_ data: [String: Any]) {
        handler.takeMarks(data)
    }

    func skipConsent() {
        showPermissionPrompt = false
        handler.skipReward()
    }
    

    func acceptConsent() {
        handler.acceptReward {
            self.showPermissionPrompt = false
        }
    }
    

    func dasdsad() {
        handler.acceptReward {
            self.showPermissionPrompt = false
        }
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        if !connected {
            showOfflineView = true
            uiLocked = true
        }
    }
    
}
