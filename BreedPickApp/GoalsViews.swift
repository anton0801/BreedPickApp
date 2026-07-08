//
//  GoalsViews.swift
//  BreedPick
//
//  Tab 1 — Goals. Home screen is Goal Setup (#01) with priority weights, plus
//  links to Climate Match (#02), Temperament (#03), Space & Setup (#04) and
//  Egg Profile (#05). All screens edit the shared Preferences live.
//

import SwiftUI

// MARK: - Reusable screen scaffold helpers

extension View {
    func bpScreen(_ title: String) -> some View {
        self.navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

struct NavRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var tint: Color = BPColor.primary

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.15)).frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.bpHead(15)).foregroundColor(BPColor.text)
                Text(subtitle).font(.bpBody(12)).foregroundColor(BPColor.textSoft).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(BPColor.textMute)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(BPColor.card))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BPColor.border, lineWidth: 1))
    }
}

final class Ring {
    let bag: Bag
    let nose: Nose
    let judge: Judge
    let reward: Reward

    init(bag: Bag, nose: Nose, judge: Judge, reward: Reward) {
        self.bag = bag
        self.nose = nose
        self.judge = judge
        self.reward = reward
    }

    static func setUp() -> Ring {
        Ring(
            bag: GearBag(),
            nose: KeenNose(),
            judge: RingJudge(),
            reward: TreatReward()
        )
    }
}

@MainActor
final class Steward {

    static let shared = Steward()

    private var roster: [String: Any] = [:]

    private init() {}

    func park<T>(_ instance: T, as type: T.Type) {
        roster[String(describing: type)] = instance
    }

    func enter<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        if let instance = roster[key] as? T {
            return instance
        }
        let built = raise(type)
        roster[key] = built
        return built
    }

    private func raise<T>(_ type: T.Type) -> T {
        switch String(describing: type) {
        case String(describing: Ring.self):
            return Ring.setUp() as! T
        case String(describing: Handler.self):
            return Handler(ring: enter(Ring.self)) as! T
        default:
            fatalError("Steward: no builder for \(type)")
        }
    }
}


// MARK: - Goals Tab (Goal Setup #01)

struct GoalsTab: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        NavigationView {
            ZStack {
                BPColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        liveBanner

                        BPCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Weight what matters", subtitle: "Drag to weight your priorities — rankings update instantly.", systemIcon: "slider.horizontal.3")
                                BPTextField(title: "Project / List", text: $app.prefs.listTitle, placeholder: "My Flock")
                                WeightSlider(title: "Egg Weight", value: $app.prefs.eggWeight, tint: BPColor.primary)
                                WeightSlider(title: "Meat Weight", value: $app.prefs.meatWeight, tint: BPColor.brick)
                                WeightSlider(title: "Temperament Weight", value: $app.prefs.temperamentWeight, tint: BPColor.action)
                                WeightSlider(title: "Hardiness Weight", value: $app.prefs.hardinessWeight, tint: BPColor.olive)
                            }
                        }

                        HStack(spacing: 10) {
                            BPButton(title: "Apply Goals", icon: "checkmark", kind: .primary) {
                                app.flash("Goals applied · \(app.liveMatchCount) breeds match")
                            }
                            BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                                withAnimation { resetWeights() }
                                app.flash("Weights reset", kind: .info)
                            }
                        }
                        HStack(spacing: 10) {
                            BPButton(title: "Keep Goals", kind: .secondary) { app.flash("Goals kept", kind: .info) }
                            BPButton(title: "Open Breed Finder", icon: "list.bullet", kind: .action) {
                                withAnimation { app.selectedTab = 1 }
                            }
                        }

                        SectionHeader(title: "Refine your match", subtitle: "Tune each axis of the engine.")
                            .padding(.top, 4)

                        NavigationLink(destination: ClimateMatchView()) {
                            NavRow(title: "Climate Match", subtitle: "Filter breeds that survive your weather", icon: "thermometer", tint: BPColor.action)
                        }.buttonStyle(PlainButtonStyle())
                        NavigationLink(destination: TemperamentView()) {
                            NavRow(title: "Temperament & Handling", subtitle: "Calm, friendly, quiet — set the character", icon: "heart.fill", tint: BPColor.brick)
                        }.buttonStyle(PlainButtonStyle())
                        NavigationLink(destination: SpaceSetupView()) {
                            NavRow(title: "Space & Setup", subtitle: "Match breeds to your run and yard", icon: "house.fill", tint: BPColor.olive)
                        }.buttonStyle(PlainButtonStyle())
                        NavigationLink(destination: EggProfileView()) {
                            NavRow(title: "Egg Profile", subtitle: "Colour, size, count and broodiness", icon: "circle.fill", tint: BPColor.primary)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
                }
            }
            .bpScreen("Goals")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { SettingsGear() } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var liveBanner: some View {
        HStack(spacing: 14) {
            ChickenView(size: 50)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(app.liveMatchCount) breeds match").font(.bpHead(18)).foregroundColor(BPColor.text)
                Text("Top: \(app.rankedMatches.first?.breed.name ?? "—")").font(.bpBody(12)).foregroundColor(BPColor.textSoft)
            }
            Spacer()
            if let top = app.rankedMatches.first { ScoreRing(percent: top.percent, size: 50) }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [BPColor.card, BPColor.cardHover], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BPColor.border, lineWidth: 1))
        .shadow(color: BPColor.shadow, radius: 8, y: 4)
    }

    private func resetWeights() {
        app.prefs.eggWeight = 0.7; app.prefs.meatWeight = 0.3
        app.prefs.temperamentWeight = 0.6; app.prefs.hardinessWeight = 0.6
    }
}

// MARK: - Climate Match (#02)

struct ClimateMatchView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Match breeds to your climate", subtitle: "Birds that can't take your weather drop in rank.", systemIcon: "thermometer")
                            pickerRow("Winter Low", value: $app.prefs.winterLevel, options: [.cold, .mild, .warm])
                            pickerRow("Summer High", value: $app.prefs.summerLevel, options: [.mild, .warm, .hot])
                            HStack {
                                Text("Damp / Wet ground").font(.bpMono(14)).foregroundColor(BPColor.text)
                                Spacer()
                                Toggle("", isOn: $app.prefs.damp).labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                            }
                            RatingSlider(title: "Hardiness Need", value: hardinessNeedBinding, leftLabel: "Easy", rightLabel: "Tough", tint: BPColor.olive)
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Who survives your climate", systemIcon: "checkmark.seal.fill")
                            ForEach(app.rankedMatches.prefix(6)) { r in
                                HStack {
                                    Text(r.breed.name).font(.bpBody(14)).foregroundColor(r.climateRisk == .severe ? BPColor.textMute : BPColor.text)
                                    Spacer()
                                    RiskBadge(risk: r.climateRisk)
                                }
                                .opacity(r.climateRisk == .severe ? 0.55 : 1)
                                if r.id != app.rankedMatches.prefix(6).last?.id { Divider().background(BPColor.divider) }
                            }
                        }
                    }

                    actionRow(applyTitle: "Filter Climate", clear: { app.prefs.winterLevel = .mild; app.prefs.summerLevel = .warm; app.prefs.damp = false },
                              confirm: "Climate filter applied")
                    NavigationLink(destination: TemperamentView()) {
                        NavRow(title: "Open Temperament", subtitle: "Next: set the character you want", icon: "heart.fill", tint: BPColor.brick)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Climate Match")
    }

    private var hardinessNeedBinding: Binding<Int> {
        Binding(get: { Int((app.prefs.hardinessWeight * 4).rounded()) + 1 },
                set: { app.prefs.hardinessWeight = Double($0 - 1) / 4 })
    }

    private func pickerRow(_ title: String, value: Binding<TempLevel>, options: [TempLevel]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.bpMono(14)).foregroundColor(BPColor.text)
            HStack(spacing: 8) {
                ForEach(options) { o in
                    BPChip(title: o.label, selected: value.wrappedValue == o, tint: BPColor.action) { value.wrappedValue = o }
                }
            }
        }
    }

    @ViewBuilder
    private func actionRow(applyTitle: String, clear: @escaping () -> Void, confirm: String) -> some View {
        HStack(spacing: 10) {
            BPButton(title: applyTitle, icon: "checkmark", kind: .primary) { app.flash(confirm) }
            BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                withAnimation { clear() }; app.flash("Cleared", kind: .info)
            }
        }
        BPButton(title: "Keep Filter", kind: .secondary) { app.flash("Filter kept", kind: .info) }
    }
}

// MARK: - Temperament & Handling (#03)

struct TemperamentView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(title: "Set the temperament you want", subtitle: "Calmer birds rise for families and tight yards.", systemIcon: "heart.fill")
                            RatingSlider(title: "Calmness", value: $app.prefs.calmnessWant, leftLabel: "Lively", rightLabel: "Placid", tint: BPColor.primary)
                            RatingSlider(title: "Friendliness", value: $app.prefs.friendlinessWant, leftLabel: "Aloof", rightLabel: "Cuddly", tint: BPColor.action)
                            RatingSlider(title: "Stays Grounded", value: $app.prefs.lowFlightWant, leftLabel: "Flighty OK", rightLabel: "No flyers", tint: BPColor.brick)
                            RatingSlider(title: "Quietness", value: $app.prefs.quietWant, leftLabel: "Noise OK", rightLabel: "Quiet", tint: BPColor.olive)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Kids / Family").font(.bpMono(14)).foregroundColor(BPColor.text)
                                    Text("Lifts gentle, child-safe breeds").font(.bpBody(11)).foregroundColor(BPColor.textMute)
                                }
                                Spacer()
                                Toggle("", isOn: $app.prefs.kidsFamily).labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                            }
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Gentlest matches", systemIcon: "checkmark.seal.fill")
                            ForEach(app.rankedMatches.filter { $0.breed.kidFriendly }.prefix(4)) { r in
                                HStack {
                                    Text(r.breed.name).font(.bpBody(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    StatPill(icon: "heart.fill", text: "Calm \(r.breed.calmness)/5", tint: BPColor.match)
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Apply Temper", icon: "checkmark", kind: .primary) { app.flash("Temperament applied") }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            withAnimation {
                                app.prefs.calmnessWant = 3; app.prefs.friendlinessWant = 3
                                app.prefs.lowFlightWant = 3; app.prefs.quietWant = 3; app.prefs.kidsFamily = false
                            }
                            app.flash("Cleared", kind: .info)
                        }
                    }
                    BPButton(title: "Keep Temper", kind: .secondary) { app.flash("Kept", kind: .info) }
                    NavigationLink(destination: SpaceSetupView()) {
                        NavRow(title: "Open Space & Setup", subtitle: "Next: match breeds to your space", icon: "house.fill", tint: BPColor.olive)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Temperament")
    }
}

// MARK: - Space & Setup (#04)

struct SpaceSetupView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var fencing = "Standard"
    private let fencingOptions = ["Open", "Standard", "High / Netted"]

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Match breeds to your space", subtitle: "Confined runs favour tolerant, settled birds.", systemIcon: "house.fill")
                            Text("Setup").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                ForEach(Setup.allCases) { s in
                                    BPChip(title: s.label, selected: app.prefs.setup == s) { app.prefs.setup = s }
                                }
                            }
                            RatingSlider(title: "Space per Bird", value: $app.prefs.confinementNeed, leftLabel: "Tight", rightLabel: "Roomy", tint: BPColor.action)
                            Text("Fencing").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                ForEach(fencingOptions, id: \.self) { f in
                                    BPChip(title: f, selected: fencing == f, tint: BPColor.olive) { fencing = f }
                                }
                            }
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: app.prefs.setup == .confined ? "Best for confinement" : "Best for your space", systemIcon: "checkmark.seal.fill")
                            ForEach(app.rankedMatches.prefix(4)) { r in
                                HStack {
                                    Text(r.breed.name).font(.bpBody(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    StatPill(icon: "house.fill", text: "Tol \(r.breed.confinementTolerance)/5", tint: BPColor.primary)
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Apply Space", icon: "checkmark", kind: .primary) { app.flash("Space settings applied") }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            withAnimation { app.prefs.setup = .freeRange; app.prefs.confinementNeed = 3; fencing = "Standard" }
                            app.flash("Cleared", kind: .info)
                        }
                    }
                    BPButton(title: "Keep Space", kind: .secondary) { app.flash("Kept", kind: .info) }
                    NavigationLink(destination: EggProfileView()) {
                        NavRow(title: "Open Egg Profile", subtitle: "Next: pick your egg type", icon: "circle.fill", tint: BPColor.primary)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Space & Setup")
    }
}

// MARK: - Egg Profile (#05)

struct EggProfileView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Pick the egg type you want", subtitle: "Want a chick factory? Turn on broodiness.", systemIcon: "circle.fill")

                            Text("Egg Colour").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            FlowChips {
                                BPChip(title: "Any", selected: app.prefs.eggColorWant == nil, tint: BPColor.primary) { app.prefs.eggColorWant = nil }
                                ForEach(EggColor.allCases) { c in
                                    EggColorChip(color: c, selected: app.prefs.eggColorWant == c) { app.prefs.eggColorWant = c }
                                }
                            }

                            Text("Egg Size").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                BPChip(title: "Any", selected: app.prefs.eggSizeWant == nil, tint: BPColor.action) { app.prefs.eggSizeWant = nil }
                                ForEach(EggSize.allCases) { s in
                                    BPChip(title: s.label, selected: app.prefs.eggSizeWant == s, tint: BPColor.action) { app.prefs.eggSizeWant = s }
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Eggs / Year target").font(.bpMono(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    Text("\(app.prefs.eggsPerYearWant)").font(.bpMono(13)).foregroundColor(BPColor.primary)
                                }
                                Slider(value: Binding(get: { Double(app.prefs.eggsPerYearWant) },
                                                      set: { app.prefs.eggsPerYearWant = Int($0) }),
                                       in: 100...320, step: 10).accentColor(BPColor.primary)
                            }

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Broodiness wanted").font(.bpMono(14)).foregroundColor(BPColor.text)
                                    Text("For hatching your own chicks").font(.bpBody(11)).foregroundColor(BPColor.textMute)
                                }
                                Spacer()
                                Toggle("", isOn: $app.prefs.wantBroody).labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                            }
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Best egg matches", systemIcon: "checkmark.seal.fill")
                            ForEach(app.rankedMatches.prefix(4)) { r in
                                HStack(spacing: 10) {
                                    EggShape().fill(r.breed.eggColor.swatch)
                                        .overlay(EggShape().stroke(BPColor.border, lineWidth: 1))
                                        .frame(width: 16, height: 21)
                                    Text(r.breed.name).font(.bpBody(14)).foregroundColor(BPColor.text)
                                    Spacer()
                                    Text("\(r.breed.eggsPerYear)/yr").font(.bpMono(12)).foregroundColor(BPColor.textSoft)
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Apply Eggs", icon: "checkmark", kind: .primary) { app.flash("Egg profile applied") }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            withAnimation {
                                app.prefs.eggColorWant = nil; app.prefs.eggSizeWant = nil
                                app.prefs.eggsPerYearWant = 250; app.prefs.wantBroody = false
                            }
                            app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Eggs", kind: .secondary) { app.flash("Kept", kind: .info) }
                        BPButton(title: "Open Breed Finder", icon: "list.bullet", kind: .action) { withAnimation { app.selectedTab = 1 } }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Egg Profile")
    }
}

// MARK: - Small helpers

struct EggColorChip: View {
    let color: EggColor
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                EggShape().fill(color.swatch).overlay(EggShape().stroke(BPColor.border, lineWidth: 1)).frame(width: 12, height: 16)
                Text(color.label).font(.bpMono(12))
            }
            .padding(.vertical, 7).padding(.horizontal, 11)
            .foregroundColor(selected ? .white : BPColor.textSoft)
            .background(Capsule().fill(selected ? BPColor.primary : BPColor.bgSoft))
            .overlay(Capsule().stroke(selected ? BPColor.primary : BPColor.border, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Simple wrapping chip layout for iOS 14 (no Layout protocol).
struct FlowChips<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Two rows via LazyVGrid adaptive
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                content()
            }
        }
    }
}
