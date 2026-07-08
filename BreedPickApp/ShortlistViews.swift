//
//  ShortlistViews.swift
//  BreedPick
//
//  Tab 4 — Shortlist (#09), Flock Mix Advisor (#10) and Decision Signoff (#16).
//

import SwiftUI

// MARK: - Shortlist (#09)

struct ShortlistTab: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        NavigationView {
            ZStack {
                BPColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        BPCard {
                            HStack(spacing: 12) {
                                ChickenView(size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(app.shortlist.count) breeds shortlisted").font(.bpHead(16)).foregroundColor(BPColor.text)
                                    Text("\(app.shortlist.filter { $0.status == .chosen }.count) chosen · \(app.shortlist.filter { $0.status == .considering }.count) considering")
                                        .font(.bpBody(12)).foregroundColor(BPColor.textSoft)
                                }
                                Spacer()
                            }
                        }

                        if app.shortlist.isEmpty {
                            EmptyHint(icon: "heart", title: "No favourites yet",
                                      message: "Open a breed card and tap ‘Add to Shortlist’ to start your finalists.")
                            BPButton(title: "Browse Breeds", icon: "list.bullet", kind: .primary) { withAnimation { app.selectedTab = 1 } }
                        } else {
                            ForEach(app.shortlist.sorted(by: { $0.rank < $1.rank })) { item in
                                if let breed = BreedDatabase.breed(item.breedId) {
                                    ShortlistCard(item: item, breed: breed)
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            BPButton(title: "Save Shortlist", icon: "checkmark", kind: .primary) { app.flash("Shortlist saved") }
                            BPButton(title: "Clear", icon: "trash.fill", kind: .secondary, fullWidth: false) {
                                withAnimation { app.shortlist = [] }; app.flash("Shortlist cleared", kind: .info)
                            }
                        }
                        HStack(spacing: 10) {
                            BPButton(title: "Keep List", kind: .secondary) { app.flash("Kept", kind: .info) }
                            NavigationLink(destination: FlockMixView()) {
                                navLabel("Flock Mix", icon: "square.grid.2x2.fill")
                            }
                        }
                        NavigationLink(destination: DecisionSignoffView()) {
                            NavRow(title: "Decision Signoff", subtitle: "Record and sign your final choice", icon: "pencil", tint: BPColor.action)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
                }
            }
            .bpScreen("Shortlist")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { SettingsGear() } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func navLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title).font(.bpHead(14)) }
            .foregroundColor(BPColor.text).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
    }
}

struct ShortlistCard: View {
    @EnvironmentObject var app: AppViewModel
    let item: ShortlistItem
    let breed: Breed
    @State private var notes: String = ""

    var body: some View {
        let m = app.match(for: breed)
        BPCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ScoreRing(percent: m.percent, size: 44)
                    NavigationLink(destination: BreedCardView(breed: breed)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(breed.name).font(.bpHead(15)).foregroundColor(BPColor.text)
                            Text(breed.purpose.rawValue).font(.bpBody(12)).foregroundColor(BPColor.textSoft)
                        }
                    }.buttonStyle(PlainButtonStyle())
                    Spacer()
                    Button { withAnimation { app.removeShortlist(breed.id) } } label: {
                        Image(systemName: "trash.fill").foregroundColor(BPColor.danger)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(ShortStatus.allCases) { s in
                        BPChip(title: s.rawValue, selected: item.status == s, tint: s.color) {
                            var u = item; u.status = s; app.updateShortlist(u)
                        }
                    }
                }
                TextField("Notes…", text: $notes, onCommit: {
                    var u = item; u.notes = notes; app.updateShortlist(u)
                })
                .font(.bpBody(13)).foregroundColor(BPColor.text)
                .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(BPColor.bgSoft))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BPColor.border, lineWidth: 1))

                HStack {
                    Text("Rank #\(item.rank)").font(.bpMono(12)).foregroundColor(BPColor.textMute)
                    Spacer()
                    Button { changeRank(-1) } label: { Image(systemName: "arrow.up.circle.fill").foregroundColor(BPColor.primary) }
                    Button { changeRank(1) } label: { Image(systemName: "arrow.down.circle.fill").foregroundColor(BPColor.primary) }
                }
            }
        }
        .onAppear { notes = item.notes }
    }

    private func changeRank(_ delta: Int) {
        var u = item; u.rank = max(1, item.rank + delta)
        app.updateShortlist(u)
    }
}

// MARK: - Flock Mix Advisor (#10)

struct FlockMixView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        let report = MatchEngine.analyzeMix(app.flockMix)
        return ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Mix for year-round eggs", subtitle: "Balance laying seasons and temperament.", systemIcon: "square.grid.2x2.fill")
                            HStack(spacing: 8) {
                                ForEach(Season.allCases) { s in
                                    seasonPill(s, count: report.seasonCoverage[s] ?? 0)
                                }
                            }
                            HStack(spacing: 10) {
                                Image(systemName: report.balanced ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(report.balanced ? BPColor.match : BPColor.warn)
                                Text(report.summary).font(.bpBody(13)).foregroundColor(BPColor.text)
                            }
                            HStack {
                                Text("Calm balance").font(.bpMono(12)).foregroundColor(BPColor.textSoft)
                                Spacer()
                                Text(String(format: "%.1f/5", report.calmAverage)).font(.bpMono(13))
                                    .foregroundColor(report.calmAverage >= 3.2 ? BPColor.match : BPColor.warn)
                            }
                        }
                    }

                    // Chosen breeds with counts
                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionHeader(title: "Chosen breeds", systemIcon: "list.bullet")
                                Spacer()
                                Menu {
                                    ForEach(BreedDatabase.all) { b in
                                        Button(b.name) { app.toggleMix(b.id) }
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(BPColor.primary)
                                }
                            }
                            if app.flockMix.isEmpty {
                                Text("No breeds yet — tap Build Mix or add your own.").font(.bpBody(13)).foregroundColor(BPColor.textMute)
                            } else {
                                ForEach(app.flockMix) { entry in
                                    if let b = BreedDatabase.breed(entry.breedId) {
                                        mixRow(entry, breed: b)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Build Mix", icon: "sparkles", kind: .primary) {
                            withAnimation { app.flockMix = MatchEngine.suggestMix(app.prefs) }
                            app.flash("Built a year-round mix")
                        }
                        BPButton(title: "Clear", icon: "trash.fill", kind: .secondary, fullWidth: false) {
                            withAnimation { app.flockMix = [] }; app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Mix", kind: .secondary) { app.flash("Mix kept", kind: .info) }
                        if let first = app.flockMix.first, let b = BreedDatabase.breed(first.breedId) {
                            NavigationLink(destination: CarePreviewView(breed: b)) {
                                SoftNavLabel(title: "Care Preview", icon: "leaf.arrow.circlepath")
                            }
                        } else {
                            BPButton(title: "Open Breeds", icon: "list.bullet", kind: .action) { withAnimation { app.selectedTab = 1 } }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Flock Mix")
    }

    private func seasonPill(_ s: Season, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(s.label.prefix(3).uppercased()).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(BPColor.textSoft)
            ZStack {
                Circle().fill(count > 0 ? BPColor.match.opacity(0.18) : BPColor.bgSoft).frame(width: 34, height: 34)
                Text("\(count)").font(.bpMono(14)).foregroundColor(count > 0 ? BPColor.match : BPColor.textMute)
            }
        }.frame(maxWidth: .infinity)
    }

    private func mixRow(_ entry: FlockMixEntry, breed: Breed) -> some View {
        HStack(spacing: 10) {
            ChickenView(size: 30, bodyColor: breed.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(breed.name).font(.bpMono(13)).foregroundColor(BPColor.text)
                Text(breed.layingSeasons.map { $0.label.prefix(3) }.joined(separator: " ")).font(.bpBody(10)).foregroundColor(BPColor.textMute)
            }
            Spacer()
            Stepper(value: Binding(get: { entry.count }, set: { app.setMixCount(entry.breedId, $0) }), in: 1...20) {
                Text("\(entry.count)").font(.bpMono(14)).foregroundColor(BPColor.primary)
            }.labelsHidden()
            Text("\(entry.count)").font(.bpMono(14)).foregroundColor(BPColor.primary).frame(width: 24)
            Button { withAnimation { app.toggleMix(entry.breedId) } } label: {
                Image(systemName: "minus.circle.fill").foregroundColor(BPColor.danger)
            }
        }
    }
}

// MARK: - Decision Signoff (#16)

struct DecisionSignoffView: View {
    @EnvironmentObject var app: AppViewModel

    @State private var chosen: Set<String> = []
    @State private var reasons = ""
    @State private var comment = ""
    @State private var lines: [[CGPoint]] = []
    @State private var padSize: CGSize = CGSize(width: 320, height: 150)
    @State private var date = Date()

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Record the final breed choice", subtitle: "Pick the breeds you're committing to.", systemIcon: "pencil")
                            if app.shortlist.isEmpty {
                                Text("Shortlist some breeds first to choose from.").font(.bpBody(13)).foregroundColor(BPColor.textMute)
                            } else {
                                FlowChips {
                                    ForEach(app.shortlist) { item in
                                        if let b = BreedDatabase.breed(item.breedId) {
                                            BPChip(title: b.name, selected: chosen.contains(b.id), tint: BPColor.match) {
                                                if chosen.contains(b.id) { chosen.remove(b.id) } else { chosen.insert(b.id) }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Reasons").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                TextEditor(text: $reasons).frame(height: 70)
                                    .padding(8).background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
                            }
                            BPTextField(title: "Comment", text: $comment, placeholder: "Any final note")
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .font(.bpMono(13)).accentColor(BPColor.primary)
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Signature").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                Spacer()
                                Button("Erase") { lines = [] }.font(.bpMono(12)).foregroundColor(BPColor.danger)
                            }
                            SignaturePad(lines: $lines)
                                .background(GeometryReader { geo in Color.clear.onAppear { padSize = geo.size } })
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Confirm Choice", icon: "checkmark.seal.fill", kind: .match) { confirm() }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            chosen = []; reasons = ""; comment = ""; lines = []; app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Decision", kind: .secondary) { app.flash("Kept", kind: .info) }
                        BPButton(title: "Open Reports", icon: "doc.text.fill", kind: .action) { withAnimation { app.selectedTab = 4 } }
                    }

                    if !app.decisions.isEmpty {
                        BPCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Past decisions", systemIcon: "clock.fill")
                                ForEach(app.decisions) { d in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(d.chosenBreedIds.map { BreedDatabase.name($0) }.joined(separator: ", "))
                                                .font(.bpMono(13)).foregroundColor(BPColor.text).lineLimit(1)
                                            Text(dateString(d.date)).font(.bpBody(11)).foregroundColor(BPColor.textMute)
                                        }
                                        Spacer()
                                        if d.signature != nil { Image(systemName: "scribble").foregroundColor(BPColor.match) }
                                        Button { app.removeDecision(d.id) } label: { Image(systemName: "trash.fill").foregroundColor(BPColor.danger) }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Decision Signoff")
        .onAppear { chosen = Set(app.shortlist.filter { $0.status == .chosen }.map { $0.breedId }) }
    }

    private func confirm() {
        guard !chosen.isEmpty else { app.flash("Pick at least one breed", kind: .warning); return }
        let sig = SignatureRenderer.png(lines: lines, size: padSize)
        let record = DecisionRecord(listTitle: app.prefs.listTitle, chosenBreedIds: Array(chosen),
                                    reasons: reasons, comment: comment, signature: sig, date: date)
        app.addDecision(record)
        // Mark chosen breeds in the shortlist too.
        for id in chosen {
            if let item = app.shortlist.first(where: { $0.breedId == id }) {
                var u = item; u.status = .chosen; app.updateShortlist(u)
            }
        }
        app.flash("Decision recorded")
    }

    private func dateString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
}
