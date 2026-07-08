//
//  OnboardingView.swift
//  BreedPick
//
//  Five-screen "goal-dial" onboarding. Each screen has its own illustrated
//  scene and a distinct interaction: tap-burst, rotary drag, scroll parallax,
//  press-and-hold, and a tap-to-reveal ranked list. All choices flow into the
//  shared Preferences so the live match counter is real. Loops stop on disappear.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppViewModel
    let onFinish: () -> Void

    @State private var page = 0
    private let pageCount = 5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient.warmBackdrop.ignoresSafeArea()

                // Paged content — sits between the fixed top bar and bottom nav.
                HStack(spacing: 0) {
                    O1Entry().frame(width: geo.size.width)
                    O2Dials().frame(width: geo.size.width)
                    O3Climate().frame(width: geo.size.width)
                    O4Space().frame(width: geo.size.width)
                    O5Matches(onFinish: finish).frame(width: geo.size.width)
                }
                .frame(width: geo.size.width, alignment: .leading)
                .offset(x: -CGFloat(page) * geo.size.width)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)
                .padding(.top, 54)
                .padding(.bottom, 100)

                // Top bar (always visible): progress dots + Skip
                HStack {
                    HStack(spacing: 7) {
                        ForEach(0..<pageCount, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? BPColor.primary : BPColor.border)
                                .frame(width: i == page ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                        }
                    }
                    Spacer()
                    Button("Skip") { finish() }
                        .font(.bpMono(15)).foregroundColor(BPColor.textSoft)
                }
                .padding(.horizontal, 22).padding(.top, 16)

                // Bottom navigation (always visible, pinned)
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 12) {
                        if page > 0 {
                            BPButton(title: "Back", icon: "chevron.left", kind: .secondary, fullWidth: false) {
                                withAnimation { page -= 1 }
                            }
                        }
                        if page < pageCount - 1 {
                            BPButton(title: nextTitle, kind: .primary) {
                                withAnimation { page += 1 }
                            }
                        } else {
                            BPButton(title: "Open Matches", icon: "checkmark", kind: .match) { finish() }
                        }
                    }
                    .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 16)
                    .background(
                        LinearGradient(colors: [BPColor.bg.opacity(0), BPColor.bgDeep],
                                       startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
    }

    private var nextTitle: String {
        switch page {
        case 0: return "Enter Eggs"
        case 1: return "Set Priorities"
        case 2: return "Set Climate"
        case 3: return "Set Space"
        default: return "Next"
        }
    }

    private func finish() {
        app.prefs.syncWeightsFromDials()
        onFinish()
    }
}

// MARK: - O1 · Entry (tap-to-burst)

private struct O1Entry: View {
    @EnvironmentObject var app: AppViewModel
    @State private var burst = 0

    private let frequencies = ["Daily", "Weekly", "Hobby"]
    private let startModes = ["Fresh start", "Have a coop", "Expanding flock"]
    @State private var startMode = "Fresh start"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(BPColor.primary.opacity(0.12)).frame(width: 150, height: 150)
                    ChickenView(size: 120)
                    BurstView(trigger: burst)
                }
                .padding(.top, 6)

                OnbHeader(title: "Breed Pick Entry",
                          text: "Tell us what you want from your birds. No sign-up — ever.")

                BPCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Main Want").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Purpose.allCases) { p in
                                PurposeCard(purpose: p, selected: app.prefs.mainWant == p) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        app.prefs.mainWant = p
                                    }
                                    burst += 1
                                }
                            }
                        }

                        Text("Use Frequency").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                        HStack(spacing: 8) {
                            ForEach(frequencies, id: \.self) { f in
                                BPChip(title: f, selected: app.prefs.useFrequency == f) {
                                    app.prefs.useFrequency = f
                                }
                            }
                        }

                        Text("Start Mode").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                        HStack(spacing: 8) {
                            ForEach(startModes, id: \.self) { m in
                                BPChip(title: m, selected: startMode == m, tint: BPColor.action) {
                                    startMode = m
                                }
                            }
                        }
                    }
                }
                Text("Tap a card — the matching breed group lights up.")
                    .font(.bpBody(12)).foregroundColor(BPColor.textMute)
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 22)
        }
    }
}

private struct PurposeCard: View {
    let purpose: Purpose
    let selected: Bool
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PurposeGlyph(purpose: purpose, size: 34)
                    .frame(height: 38)
                    .scaleEffect(selected && pulse ? 1.12 : 1)
                Text(purpose.rawValue).font(.bpMono(13))
                    .foregroundColor(selected ? BPColor.onPrimary : BPColor.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft)
                    if selected { RoundedRectangle(cornerRadius: 14).fill(LinearGradient.amber) }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? BPColor.primary : BPColor.border, lineWidth: 1.2))
            .shadow(color: selected ? BPColor.amberGlow : .clear, radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: selected) { sel in
            if sel { withAnimation(.easeInOut(duration: 0.4).repeatCount(2, autoreverses: true)) { pulse = true } }
            else { pulse = false }
        }
    }
}

private struct BurstView: View {
    let trigger: Int
    @State private var go = false

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                let angle = Double(i) / 10 * 2 * .pi
                EggShape().fill(BPColor.primaryGlow)
                    .frame(width: 9, height: 12)
                    .offset(x: go ? CGFloat(cos(angle)) * 80 : 0,
                            y: go ? CGFloat(sin(angle)) * 80 : 0)
                    .opacity(go ? 0 : 0.9)
                    .scaleEffect(go ? 0.4 : 1)
            }
        }
        .onChange(of: trigger) { _ in
            go = false
            withAnimation(.easeOut(duration: 0.65)) { go = true }
        }
    }
}

// MARK: - O2 · Priority Dials (rotary drag + live counter)

private struct O2Dials: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                OnbHeader(title: "Priority Dials",
                          text: "Set your priorities — matches update live as you turn the dials.")

                // Live counter
                HStack(spacing: 10) {
                    ChickenView(size: 40)
                    Text("\(liveCount)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(BPColor.match)
                    Text("breeds match")
                        .font(.bpHead(16)).foregroundColor(BPColor.text)
                }
                .padding(.vertical, 12).padding(.horizontal, 20)
                .background(Capsule().fill(BPColor.card))
                .overlay(Capsule().stroke(BPColor.border, lineWidth: 1))
                .shadow(color: BPColor.shadow, radius: 8, y: 4)

                BPCard {
                    VStack(spacing: 22) {
                        GoalDial(value: dial(\.eggMeatDial),
                                 leftLabel: "Eggs", rightLabel: "Meat",
                                 centerLabel: "egg ↔ meat", tint: BPColor.primary)
                        Divider().background(BPColor.divider)
                        GoalDial(value: dial(\.calmActiveDial),
                                 leftLabel: "Calm", rightLabel: "Active",
                                 centerLabel: "temperament", tint: BPColor.action, size: 130)
                        Divider().background(BPColor.divider)
                        GoalDial(value: dial(\.hardyDelicateDial),
                                 leftLabel: "Hardy", rightLabel: "Delicate",
                                 centerLabel: "constitution", tint: BPColor.olive, size: 130)
                    }
                }

                HStack(spacing: 8) {
                    BPChip(title: "Balanced", selected: false, tint: BPColor.match) { applyPreset(0.5, 0.5, 0.4) }
                    BPChip(title: "Egg-focused", selected: false) { applyPreset(0.15, 0.35, 0.3) }
                    BPChip(title: "Hardy-focused", selected: false, tint: BPColor.olive) { applyPreset(0.4, 0.4, 0.1) }
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 22)
        }
    }

    private var liveCount: Int {
        var p = app.prefs; p.syncWeightsFromDials()
        return MatchEngine.matchCount(p)
    }

    private func dial(_ key: WritableKeyPath<Preferences, Double>) -> Binding<Double> {
        Binding(get: { app.prefs[keyPath: key] },
                set: { app.prefs[keyPath: key] = $0; app.prefs.syncWeightsFromDials() })
    }

    private func applyPreset(_ eggMeat: Double, _ calmActive: Double, _ hardy: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            app.prefs.eggMeatDial = eggMeat
            app.prefs.calmActiveDial = calmActive
            app.prefs.hardyDelicateDial = hardy
            app.prefs.syncWeightsFromDials()
        }
    }
}

// MARK: - O3 · Climate (scroll-driven parallax)

private struct O3Climate: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Parallax thermometer header
                GeometryReader { geo in
                    let minY = geo.frame(in: .global).minY
                    let stretch = max(0, minY) // pull-down stretch
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(LinearGradient(
                            colors: [BPColor.action.opacity(0.25), BPColor.primary.opacity(0.12)],
                            startPoint: .top, endPoint: .bottom))
                        HStack(spacing: 26) {
                            Image(systemName: "snowflake").font(.system(size: 30))
                                .foregroundColor(Color(hex: "6E9BFF"))
                                .offset(y: -stretch * 0.2)
                            Image(systemName: "thermometer").font(.system(size: 54, weight: .semibold))
                                .foregroundColor(BPColor.action)
                                .scaleEffect(1 + stretch / 600)
                            Image(systemName: "sun.max.fill").font(.system(size: 30))
                                .foregroundColor(BPColor.warn)
                                .offset(y: stretch * 0.2)
                        }
                    }
                    .frame(height: 150 + stretch)
                    .offset(y: -stretch)
                }
                .frame(height: 150)

                OnbHeader(title: "Climate Match",
                          text: "Pick your climate to filter breeds. Birds that can't take it dim in the list.")

                BPCard {
                    VStack(alignment: .leading, spacing: 16) {
                        climateRow("Winter", selection: Binding(get: { app.prefs.winterLevel },
                                                                set: { app.prefs.winterLevel = $0 }),
                                   options: [.cold, .mild, .warm])
                        climateRow("Summer", selection: Binding(get: { app.prefs.summerLevel },
                                                                set: { app.prefs.summerLevel = $0 }),
                                   options: [.mild, .warm, .hot])
                        HStack {
                            Text("Damp / Wet").font(.bpMono(14)).foregroundColor(BPColor.text)
                            Spacer()
                            Toggle("", isOn: Binding(get: { app.prefs.damp }, set: { app.prefs.damp = $0 }))
                                .labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                        }
                        HStack {
                            Text("Units").font(.bpMono(14)).foregroundColor(BPColor.text)
                            Spacer()
                            HStack(spacing: 8) {
                                BPChip(title: "°C / m", selected: app.prefs.useMetric) { app.prefs.useMetric = true }
                                BPChip(title: "°F / ft", selected: !app.prefs.useMetric) { app.prefs.useMetric = false }
                            }
                        }
                    }
                }

                // Live dim preview
                BPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Climate fit preview", systemIcon: "thermometer")
                        ForEach(MatchEngine.ranked(app.prefs).prefix(4)) { r in
                            HStack {
                                Text(r.breed.name).font(.bpBody(13))
                                    .foregroundColor(r.climateRisk == .severe ? BPColor.textMute : BPColor.text)
                                Spacer()
                                RiskBadge(risk: r.climateRisk)
                            }
                            .opacity(r.climateRisk == .severe ? 0.5 : 1)
                        }
                    }
                }
                Text("Scroll up — the thermometer stretches with the climate.")
                    .font(.bpBody(12)).foregroundColor(BPColor.textMute)
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 22)
        }
    }

    private func climateRow(_ title: String, selection: Binding<TempLevel>, options: [TempLevel]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.bpMono(14)).foregroundColor(BPColor.text)
            HStack(spacing: 8) {
                ForEach(options) { lvl in
                    BPChip(title: lvl.label, selected: selection.wrappedValue == lvl,
                           tint: BPColor.action) { selection.wrappedValue = lvl }
                }
            }
        }
    }
}

// MARK: - O4 · Space & Family (press-and-hold)

private struct O4Space: View {
    @EnvironmentObject var app: AppViewModel
    @State private var build: CGFloat = 0
    @State private var built = false
    private let reminderStyles = ["Gentle", "Seasonal", "Off"]
    @State private var reminderStyle = "Seasonal"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Press-and-hold coop illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 22).fill(BPColor.bgSoft).frame(height: 160)
                    // yard fill
                    RoundedRectangle(cornerRadius: 18).fill(BPColor.match.opacity(0.18))
                        .frame(height: 130).scaleEffect(x: build, anchor: .leading)
                        .padding(.horizontal, 18)
                    VStack(spacing: 6) {
                        ZStack {
                            Triangle().fill(BPColor.brick).frame(width: 64, height: 30)
                                .rotationEffect(.degrees(90))
                            Image(systemName: "house.fill").font(.system(size: 40))
                                .foregroundColor(BPColor.primary)
                        }
                        Text(built ? "Coop ready!" : "Hold to build the coop")
                            .font(.bpMono(13)).foregroundColor(built ? BPColor.match : BPColor.textSoft)
                    }
                    Circle().trim(from: 0, to: build)
                        .stroke(BPColor.match, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 96, height: 96).rotationEffect(.degrees(-90))
                }
                .onLongPressGesture(minimumDuration: 0.9, maximumDistance: 40, pressing: { pressing in
                    if pressing {
                        withAnimation(.linear(duration: 0.9)) { build = 1 }
                    } else if !built {
                        withAnimation(.easeOut(duration: 0.3)) { build = 0 }
                    }
                }, perform: {
                    built = true; build = 1
                    app.prefs.setup = .confined
                    app.prefs.confinementNeed = 4
                })

                OnbHeader(title: "Space & Family",
                          text: "Describe your space and household. Confined coops favour calm, tolerant birds.")

                BPCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Setup").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                        HStack(spacing: 8) {
                            ForEach(Setup.allCases) { s in
                                BPChip(title: s.label, selected: app.prefs.setup == s) { app.prefs.setup = s }
                            }
                        }

                        RatingSlider(title: "Coop Size (space per bird)",
                                     value: Binding(get: { app.prefs.confinementNeed },
                                                    set: { app.prefs.confinementNeed = $0 }),
                                     leftLabel: "Tight", rightLabel: "Roomy", tint: BPColor.action)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kids / Family").font(.bpMono(14)).foregroundColor(BPColor.text)
                                Text("Boosts gentle, child-safe breeds").font(.bpBody(11)).foregroundColor(BPColor.textMute)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(get: { app.prefs.kidsFamily }, set: { app.prefs.kidsFamily = $0 }))
                                .labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.primary))
                        }

                        Text("Reminder Style").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                        HStack(spacing: 8) {
                            ForEach(reminderStyles, id: \.self) { r in
                                BPChip(title: r, selected: reminderStyle == r, tint: BPColor.olive) { reminderStyle = r }
                            }
                        }
                    }
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 22)
        }
    }
}

// MARK: - O5 · See First Matches (tap-to-reveal)

private struct O5Matches: View {
    @EnvironmentObject var app: AppViewModel
    let onFinish: () -> Void

    @State private var revealed = false
    @State private var mode = "Show Matches"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                OnbHeader(title: "See First Matches",
                          text: "See your matches now, load a sample flock, or start with an empty list.")

                BPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        BPTextField(title: "List Title",
                                    text: Binding(get: { app.prefs.listTitle }, set: { app.prefs.listTitle = $0 }),
                                    placeholder: "My Flock")
                        HStack(spacing: 8) {
                            ForEach(["Show Matches", "Use Sample", "Start Empty"], id: \.self) { m in
                                BPChip(title: m, selected: mode == m, tint: BPColor.action) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        mode = m
                                        revealed = (m != "Start Empty")
                                    }
                                }
                            }
                        }
                    }
                }

                if revealed {
                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: mode == "Use Sample" ? "Your sample flock mix" : "Your top matches",
                                          systemIcon: "list.bullet")
                            ForEach(previewList) { r in
                                HStack(spacing: 12) {
                                    ScoreRing(percent: r.percent, size: 44, lineWidth: 5)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.breed.name).font(.bpMono(14)).foregroundColor(BPColor.text)
                                        Text(r.breed.summary).font(.bpBody(11)).foregroundColor(BPColor.textSoft)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    EmptyHint(icon: "tray", title: "Empty start",
                              message: "You'll begin with a blank shortlist and can add breeds anytime.")
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 22)
        }
        .onAppear { revealed = (mode != "Start Empty") }
    }

    private var previewList: [MatchResult] {
        if mode == "Use Sample" {
            let mix = MatchEngine.suggestMix(app.prefs)
            return mix.compactMap { BreedDatabase.breed($0.breedId) }.map { app.match(for: $0) }
        }
        return Array(MatchEngine.ranked(app.prefs).prefix(3))
    }
}

// MARK: - Shared header

private struct OnbHeader: View {
    let title: String
    let text: String
    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.bpTitle(26)).foregroundColor(BPColor.text)
            Text(text).font(.bpBody(14)).foregroundColor(BPColor.textSoft)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
