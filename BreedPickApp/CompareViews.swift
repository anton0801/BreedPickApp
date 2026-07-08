//
//  CompareViews.swift
//  BreedPick
//
//  Tab 3 — Compare Breeds (#08) side by side with a winner marker per row,
//  plus Climate Warning (#11).
//

import SwiftUI

struct CompareTab: View {
    var body: some View {
        NavigationView {
            CompareTabContent()
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { SettingsGear() } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Compare content (#08) — reusable as a pushed screen too

struct CompareTabContent: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Compare breeds side by side", subtitle: "Pick 2–3 breeds and see who wins each row.", systemIcon: "arrow.left.arrow.right")
                            ForEach(0..<3, id: \.self) { slot in
                                slotPicker(slot)
                            }
                        }
                    }

                    if selected.count >= 2 {
                        comparisonTable
                        tradeOff
                    } else {
                        EmptyHint(icon: "arrow.left.arrow.right", title: "Choose breeds",
                                  message: "Add at least two breeds above to compare them.")
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Compare", icon: "arrow.left.arrow.right", kind: .primary) {
                            app.flash(selected.count >= 2 ? "Comparing \(selected.count) breeds" : "Pick at least 2 breeds", kind: selected.count >= 2 ? .success : .warning)
                        }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            withAnimation { app.compareSelection = [] }; app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Compare", kind: .secondary) { app.flash("Comparison kept", kind: .info) }
                        BPButton(title: "Open Shortlist", icon: "heart.fill", kind: .action) { withAnimation { app.selectedTab = 3 } }
                    }
                    NavigationLink(destination: ClimateWarningView()) {
                        NavRow(title: "Climate Warning", subtitle: "\(app.climateFlagged.count) breeds flagged for your weather", icon: "exclamationmark.triangle.fill", tint: BPColor.danger)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Compare")
    }

    private var selected: [Breed] { app.compareSelection.compactMap { BreedDatabase.breed($0) } }

    private func slotPicker(_ slot: Int) -> some View {
        let current = slot < app.compareSelection.count ? BreedDatabase.breed(app.compareSelection[slot]) : nil
        return HStack(spacing: 10) {
            Text(["A", "B", "C"][slot]).font(.bpHead(15)).foregroundColor(BPColor.primary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(BPColor.primary.opacity(0.15)))
            Menu {
                Button("None") { setSlot(slot, nil) }
                ForEach(BreedDatabase.all) { b in
                    Button(b.name) { setSlot(slot, b.id) }
                }
            } label: {
                HStack {
                    Text(current?.name ?? "Choose breed \(["A", "B", "C"][slot])")
                        .font(.bpBody(14)).foregroundColor(current == nil ? BPColor.textMute : BPColor.text)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundColor(BPColor.textMute)
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
            }
        }
    }

    private func setSlot(_ slot: Int, _ id: String?) {
        var sel = app.compareSelection
        // Normalise to a fixed-length-ish list using slots.
        while sel.count <= slot { sel.append("") }
        if let id = id { sel[slot] = id } else { sel[slot] = "" }
        sel = sel.filter { !$0.isEmpty }
        app.compareSelection = Array(sel.prefix(3))
    }

    // MARK: - Table

    private var comparisonTable: some View {
        let rows: [(String, (Breed) -> Double, (Breed) -> String)] = [
            ("Match %", { Double(app.match(for: $0).percent) }, { "\(app.match(for: $0).percent)%" }),
            ("Eggs/yr", { Double($0.eggsPerYear) }, { "\($0.eggsPerYear)" }),
            ("Weight", { $0.weightLb }, { String(format: "%.1f", $0.weightLb) }),
            ("Cold", { Double($0.coldHardiness) }, { "\($0.coldHardiness)/5" }),
            ("Heat", { Double($0.heatTolerance) }, { "\($0.heatTolerance)/5" }),
            ("Calm", { Double($0.calmness) }, { "\($0.calmness)/5" }),
            ("Confine", { Double($0.confinementTolerance) }, { "\($0.confinementTolerance)/5" }),
            ("Broody", { Double($0.broodiness) }, { "\($0.broodiness)/5" })
        ]
        return BPCard {
            VStack(spacing: 8) {
                // Header
                HStack(spacing: 6) {
                    Text("").frame(width: 64, alignment: .leading)
                    ForEach(selected) { b in
                        VStack(spacing: 4) {
                            ChickenView(size: 30, bodyColor: b.accent)
                            Text(b.name).font(.bpMono(11)).foregroundColor(BPColor.text).lineLimit(2).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    }
                }
                Divider().background(BPColor.divider)
                ForEach(rows.indices, id: \.self) { i in
                    let row = rows[i]
                    let best = selected.map(row.1).max() ?? 0
                    HStack(spacing: 6) {
                        Text(row.0).font(.bpMono(12)).foregroundColor(BPColor.textSoft).frame(width: 64, alignment: .leading)
                        ForEach(selected) { b in
                            let isWinner = row.1(b) == best && best > 0
                            Text(row.2(b)).font(.bpMono(13))
                                .foregroundColor(isWinner ? .white : BPColor.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(isWinner ? BPColor.match : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                    if i < rows.count - 1 { Divider().background(BPColor.divider) }
                }
            }
        }
    }

    private var tradeOff: some View {
        let best = selected.max(by: { app.match(for: $0).percent < app.match(for: $1).percent })
        return BPCard {
            HStack(spacing: 10) {
                Image(systemName: "star.fill").foregroundColor(BPColor.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best overall fit: \(best?.name ?? "—")").font(.bpHead(14)).foregroundColor(BPColor.text)
                    Text(tradeOffText).font(.bpBody(12)).foregroundColor(BPColor.textSoft)
                }
            }
        }
    }

    private var tradeOffText: String {
        guard selected.count >= 2 else { return "" }
        let mostEggs = selected.max(by: { $0.eggsPerYear < $1.eggsPerYear })!
        let calmest = selected.max(by: { $0.calmness < $1.calmness })!
        let hardiest = selected.max(by: { $0.coldHardiness < $1.coldHardiness })!
        return "\(mostEggs.name) lays most; \(calmest.name) is calmest; \(hardiest.name) is hardiest."
    }
}

// MARK: - Climate Warning (#11)

struct ClimateWarningView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 22)).foregroundColor(BPColor.warn)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Climate warnings").font(.bpHead(16)).foregroundColor(BPColor.text)
                                Text("Winter \(app.prefs.winterLevel.label) · Summer \(app.prefs.summerLevel.label)").font(.bpBody(12)).foregroundColor(BPColor.textSoft)
                            }
                        }
                    }

                    if app.climateFlagged.isEmpty {
                        EmptyHint(icon: "checkmark.seal.fill", title: "All clear", message: "No breeds are flagged for your current climate.")
                    } else {
                        ForEach(app.climateFlagged) { r in
                            warningCard(r)
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Save Warning", icon: "checkmark", kind: .primary) {
                            app.flash("\(app.climateFlagged.count) warnings noted")
                        }
                        BPButton(title: "Keep Note", kind: .secondary, fullWidth: false) { app.flash("Kept", kind: .info) }
                    }
                    if let first = app.climateFlagged.first {
                        NavigationLink(destination: CarePreviewView(breed: first.breed)) {
                            NavRow(title: "Open Care Preview", subtitle: "Care needs for \(first.breed.name)", icon: "leaf.arrow.circlepath", tint: BPColor.olive)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Climate Warning")
    }

    private func warningCard(_ r: MatchResult) -> some View {
        let alt = MatchEngine.alternative(for: r.breed, prefs: app.prefs)
        return BPCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(r.breed.name).font(.bpHead(15)).foregroundColor(BPColor.text)
                    Spacer()
                    StatPill(icon: "exclamationmark.triangle.fill", text: r.climateRisk.label,
                             tint: r.climateRisk == .severe ? BPColor.danger : BPColor.warn)
                }
                if let reason = r.climateReason {
                    Text(reason).font(.bpBody(13)).foregroundColor(BPColor.textSoft)
                }
                if let alt = alt {
                    Divider().background(BPColor.divider)
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill").foregroundColor(BPColor.match)
                        Text("Try instead: \(alt.name)").font(.bpMono(13)).foregroundColor(BPColor.text)
                        Spacer()
                        Button {
                            app.toggleShortlist(alt)
                        } label: {
                            Text(app.isShortlisted(alt.id) ? "Saved" : "Shortlist").font(.bpMono(12)).foregroundColor(.white)
                                .padding(.vertical, 6).padding(.horizontal, 11)
                                .background(Capsule().fill(BPColor.match))
                        }
                    }
                }
            }
        }
    }
}
