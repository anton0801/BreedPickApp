//
//  BreedsViews.swift
//  BreedPick
//
//  Tab 2 — Breeds. Breed Finder (#06) ranks every breed, and pushes to the
//  Breed Card (#07), Breed Detail (#15), Care Preview (#12), Source & Cost
//  (#13) and Rule-out Note (#14).
//

import SwiftUI

// MARK: - Breed Finder (#06)

struct BreedsTab: View {
    @EnvironmentObject var app: AppViewModel
    @State private var search = ""
    @State private var filter: Purpose? = nil
    @State private var climateOnly = false
    @State private var sort: SortMode = .match

    enum SortMode: String, CaseIterable { case match = "Match", eggs = "Eggs/yr", calm = "Calmest", weight = "Weight" }

    var body: some View {
        NavigationView {
            ZStack {
                BPColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Summary
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Breeds ranked by fit").font(.bpHead(16)).foregroundColor(BPColor.text)
                                Text("\(results.count) shown · \(app.liveMatchCount) strong matches").font(.bpBody(12)).foregroundColor(BPColor.textSoft)
                            }
                            Spacer()
                            BPButton(title: "Refresh", icon: "arrow.clockwise", kind: .secondary, fullWidth: false) {
                                app.objectWillChange.send(); app.flash("Matches refreshed", kind: .info)
                            }
                        }

                        searchBar

                        // Filter + sort
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                BPChip(title: "All", selected: filter == nil) { filter = nil }
                                ForEach(Purpose.allCases) { p in
                                    BPChip(title: p.short, selected: filter == p) { filter = p }
                                }
                                BPChip(title: "Climate OK", selected: climateOnly, tint: BPColor.match) { climateOnly.toggle() }
                            }
                        }
                        HStack {
                            Menu {
                                ForEach(SortMode.allCases, id: \.self) { m in
                                    Button(m.rawValue) { sort = m }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text("Sort: \(sort.rawValue)").font(.bpMono(13))
                                }
                                .foregroundColor(BPColor.primary)
                                .padding(.vertical, 7).padding(.horizontal, 12)
                                .background(Capsule().fill(BPColor.primary.opacity(0.12)))
                            }
                            Spacer()
                            NavigationLink(destination: CompareTabContent()) {
                                HStack(spacing: 5) { Image(systemName: "arrow.left.arrow.right"); Text("Compare").font(.bpMono(13)) }
                                    .foregroundColor(BPColor.action)
                                    .padding(.vertical, 7).padding(.horizontal, 12)
                                    .background(Capsule().fill(BPColor.action.opacity(0.12)))
                            }
                        }

                        // List
                        if results.isEmpty {
                            EmptyHint(icon: "magnifyingglass", title: "No breeds found", message: "Try clearing the search or filters.")
                        } else {
                            ForEach(results) { r in
                                NavigationLink(destination: BreedCardView(breed: r.breed)) {
                                    BreedRow(result: r)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
                }
            }
            .bpScreen("Breeds")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { SettingsGear() } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(BPColor.textMute)
            TextField("Search breeds", text: $search).font(.bpBody(15)).foregroundColor(BPColor.text)
            if !search.isEmpty {
                Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(BPColor.textMute) }
            }
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: 12).fill(BPColor.card))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BPColor.border, lineWidth: 1))
    }

    private var results: [MatchResult] {
        var list = app.rankedMatches
        if let f = filter { list = list.filter { $0.breed.purpose == f } }
        if climateOnly { list = list.filter { $0.climateRisk != .severe } }
        if !search.isEmpty { list = list.filter { $0.breed.name.localizedCaseInsensitiveContains(search) } }
        switch sort {
        case .match: list.sort { $0.percent > $1.percent }
        case .eggs: list.sort { $0.breed.eggsPerYear > $1.breed.eggsPerYear }
        case .calm: list.sort { $0.breed.calmness > $1.breed.calmness }
        case .weight: list.sort { $0.breed.weightLb > $1.breed.weightLb }
        }
        return list
    }
}

// MARK: - Breed row

struct BreedRow: View {
    @EnvironmentObject var app: AppViewModel
    let result: MatchResult

    var body: some View {
        HStack(spacing: 13) {
            ScoreRing(percent: result.percent, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(result.breed.name).font(.bpHead(15)).foregroundColor(BPColor.text).lineLimit(1)
                    if app.isShortlisted(result.breed.id) {
                        Image(systemName: "heart.fill").font(.system(size: 11)).foregroundColor(BPColor.danger)
                    }
                }
                HStack(spacing: 6) {
                    PurposeGlyph(purpose: result.breed.purpose, size: 14).frame(width: 18, height: 18)
                    Text(result.breed.purpose.short).font(.bpBody(11)).foregroundColor(BPColor.textSoft)
                    Text("· \(result.breed.eggsPerYear)/yr").font(.bpBody(11)).foregroundColor(BPColor.textSoft)
                }
                MatchBar(percent: result.percent).frame(height: 7)
            }
            if result.climateRisk != .none {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13)).foregroundColor(result.climateRisk == .severe ? BPColor.danger : BPColor.warn)
            }
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(BPColor.textMute)
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 16).fill(BPColor.card))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(result.breed.accent.opacity(0.4), lineWidth: 1))
        .shadow(color: BPColor.shadow, radius: 5, y: 3)
    }
}

// MARK: - Breed Card (#07)

struct BreedCardView: View {
    @EnvironmentObject var app: AppViewModel
    let breed: Breed

    var body: some View {
        let m = app.match(for: breed)
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Hero
                    VStack(spacing: 10) {
                        ChickenView(size: 96, bodyColor: breed.accent)
                        Text(breed.name).font(.bpTitle(24)).foregroundColor(BPColor.text)
                        Text(breed.summary).font(.bpBody(13)).foregroundColor(BPColor.textSoft)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 8) {
                            ScoreRing(percent: m.percent, size: 56)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(m.band.label).font(.bpHead(15)).foregroundColor(m.band.color)
                                RiskBadge(risk: m.climateRisk)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity).padding(18)
                    .background(RoundedRectangle(cornerRadius: 20).fill(BPColor.card))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(breed.accent.opacity(0.4), lineWidth: 1.4))
                    .shadow(color: BPColor.shadow, radius: 10, y: 5)

                    // Quick stats
                    BPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Profile", systemIcon: "list.bullet")
                            statRow(icon: "circle.fill", label: "Eggs", value: "\(breed.eggsPerYear)/yr · \(breed.eggColor.label) · \(breed.eggSize.label)")
                            statRow(icon: "scalemass.fill", label: "Hen weight", value: String(format: "%.1f lb", breed.weightLb))
                            statRow(icon: "thermometer", label: "Climate", value: "Cold \(breed.coldHardiness)/5 · Heat \(breed.heatTolerance)/5")
                            statRow(icon: "heart.fill", label: "Temperament", value: "Calm \(breed.calmness)/5 · Friendly \(breed.friendliness)/5")
                            statRow(icon: "house.fill", label: "Confinement", value: "Tolerance \(breed.confinementTolerance)/5 · Forage \(breed.foraging)/5")
                            statRow(icon: "leaf.arrow.circlepath", label: "Broody", value: "\(breed.broodiness)/5 · Lays: \(breed.layingSeasons.map { $0.label }.joined(separator: ", "))")
                        }
                    }

                    // Match breakdown
                    BPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Why this score", systemIcon: "chart.bar.fill")
                            breakdown("Egg fit", m.eggScore)
                            breakdown("Meat fit", m.meatScore)
                            breakdown("Climate fit", m.climateScore)
                            breakdown("Temperament fit", m.temperamentScore)
                            breakdown("Space fit", m.spaceScore)
                        }
                    }

                    // Pros / cons
                    BPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Pros").font(.bpHead(14)).foregroundColor(BPColor.match)
                                ForEach(breed.pros, id: \.self) { bullet($0, color: BPColor.match, icon: "checkmark") }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Cons").font(.bpHead(14)).foregroundColor(BPColor.danger)
                                ForEach(breed.cons, id: \.self) { bullet($0, color: BPColor.danger, icon: "xmark") }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Appearance").font(.bpHead(14)).foregroundColor(BPColor.text)
                                Text(breed.appearance).font(.bpBody(13)).foregroundColor(BPColor.textSoft)
                            }
                        }
                    }

                    if m.climateRisk != .none, let reason = m.climateReason {
                        BPCard {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(m.climateRisk == .severe ? BPColor.danger : BPColor.warn)
                                Text(reason).font(.bpBody(13)).foregroundColor(BPColor.text)
                            }
                        }
                    }

                    // Actions
                    BPButton(title: app.isShortlisted(breed.id) ? "Remove from Shortlist" : "Add to Shortlist",
                             icon: app.isShortlisted(breed.id) ? "heart.slash.fill" : "heart.fill",
                             kind: app.isShortlisted(breed.id) ? .danger : .match) {
                        app.toggleShortlist(breed)
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Compare", icon: "arrow.left.arrow.right", kind: .action) {
                            if !app.compareSelection.contains(breed.id) && app.compareSelection.count < 3 {
                                app.compareSelection.append(breed.id)
                            }
                            app.flash("Added to Compare", kind: .info)
                            withAnimation { app.selectedTab = 2 }
                        }
                        NavigationLink(destination: CarePreviewView(breed: breed)) {
                            Text("Care Preview").font(.bpHead(15)).foregroundColor(BPColor.text)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
                        }
                    }
                    HStack(spacing: 10) {
                        NavigationLink(destination: BreedDetailView(breed: breed)) {
                            navButtonLabel("Breed Detail", icon: "doc.text.fill")
                        }
                        NavigationLink(destination: SourceCostView(breed: breed)) {
                            navButtonLabel("Source & Cost", icon: "cart.fill")
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen(breed.name)
    }

    private func navButtonLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title).font(.bpHead(14)) }
            .foregroundColor(BPColor.text)
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(BPColor.primary).frame(width: 20)
            Text(label).font(.bpMono(13)).foregroundColor(BPColor.textSoft)
            Spacer()
            Text(value).font(.bpBody(13)).foregroundColor(BPColor.text).multilineTextAlignment(.trailing)
        }
    }

    private func breakdown(_ label: String, _ value: Double) -> some View {
        HStack(spacing: 10) {
            Text(label).font(.bpBody(13)).foregroundColor(BPColor.textSoft).frame(width: 120, alignment: .leading)
            MatchBar(percent: Int(value * 100)).frame(height: 8)
            Text("\(Int(value * 100))%").font(.bpMono(12)).foregroundColor(BPColor.text).frame(width: 38, alignment: .trailing)
        }
    }

    private func bullet(_ text: String, color: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundColor(color)
                .padding(.top, 3)
            Text(text).font(.bpBody(13)).foregroundColor(BPColor.text)
        }
    }
}

// MARK: - Breed Detail (#15)

struct BreedDetailView: View {
    @EnvironmentObject var app: AppViewModel
    let breed: Breed

    @State private var status: ShortStatus = .considering
    @State private var role = "Layer"
    @State private var notes = ""
    private let roles = ["Layer", "Meat", "Mother", "Pet", "Show"]

    var body: some View {
        let m = app.match(for: breed)
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ChickenView(size: 56, bodyColor: breed.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(breed.name).font(.bpHead(18)).foregroundColor(BPColor.text)
                                    Text("\(m.percent)% match").font(.bpMono(13)).foregroundColor(m.band.color)
                                }
                                Spacer()
                                ScoreRing(percent: m.percent, size: 50)
                            }
                            Divider().background(BPColor.divider)

                            Text("Status").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                ForEach(ShortStatus.allCases) { s in
                                    BPChip(title: s.rawValue, selected: status == s, tint: s.color) { status = s }
                                }
                            }
                            Text("Role in Flock").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                ForEach(roles, id: \.self) { r in
                                    BPChip(title: r, selected: role == r, tint: BPColor.action) { role = r }
                                }
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Notes").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                TextEditor(text: $notes).frame(height: 90)
                                    .padding(8).background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Update Breed", icon: "checkmark", kind: .primary) {
                            var item = app.shortlist.first(where: { $0.breedId == breed.id }) ?? ShortlistItem(breedId: breed.id, rank: app.shortlist.count + 1)
                            item.status = status; item.notes = notes
                            if app.isShortlisted(breed.id) { app.updateShortlist(item) } else { app.shortlist.append(item) }
                            app.flash("\(breed.name) updated")
                        }
                        BPButton(title: "Duplicate Note", icon: "doc.on.doc.fill", kind: .secondary, fullWidth: false) {
                            notes += (notes.isEmpty ? "" : "\n") + "Copy: \(role) role, \(status.rawValue)."
                            app.flash("Note duplicated", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        NavigationLink(destination: BreedCardView(breed: breed)) {
                            Text("Open Card").font(.bpHead(15)).foregroundColor(BPColor.text)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
                        }
                        BPButton(title: "Open Reports", icon: "doc.text.fill", kind: .action) {
                            withAnimation { app.selectedTab = 4 }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Breed Detail")
        .onAppear {
            if let item = app.shortlist.first(where: { $0.breedId == breed.id }) {
                status = item.status; notes = item.notes
            }
        }
    }
}

// MARK: - Care Preview (#12)

struct CarePreviewView: View {
    @EnvironmentObject var app: AppViewModel
    let breed: Breed
    @State private var note = CareNote(breedId: "")

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Care for \(breed.name)", subtitle: "Auto-suggested needs you can edit.", systemIcon: "leaf.arrow.circlepath")
                            careHint("Feed", autoFeed)
                            careHint("Space & Cold", autoSpace)
                            careHint("Special", autoSpecial)
                        }
                    }
                    BPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            editor("Feed Need", text: $note.feedNeed, placeholder: autoFeed)
                            editor("Space / Cold", text: $note.spaceCold, placeholder: autoSpace)
                            editor("Special Care", text: $note.specialCare, placeholder: autoSpecial)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Save Preview", icon: "checkmark", kind: .primary) {
                            app.saveCareNote(note); app.flash("Care preview saved")
                        }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            note = CareNote(breedId: breed.id); app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Preview", kind: .secondary) { app.saveCareNote(note); app.flash("Kept", kind: .info) }
                        NavigationLink(destination: SourceCostView(breed: breed)) {
                            navLabel("Source & Cost", icon: "cart.fill")
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Care Preview")
        .onAppear { note = app.careNote(for: breed.id) }
    }

    private var autoFeed: String {
        breed.weightLb > 7.5 ? "Large bird — needs more layer feed; watch the waistline." : "Standard layer ration; grit and oyster shell free-choice."
    }
    private var autoSpace: String {
        breed.coldHardiness >= 4 ? "Cold hardy — dry, draft-free coop is enough." : "Provide extra winter warmth and wind protection."
    }
    private var autoSpecial: String {
        if breed.broodiness >= 4 { return "Goes broody often — collect eggs daily or give a brooder." }
        if breed.flightiness >= 4 { return "Flighty — clip a wing or net the run." }
        return breed.foraging >= 4 ? "Loves to forage — let it range when you can." : "Easy keeper, no special demands."
    }

    private func careHint(_ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title).font(.bpMono(12)).foregroundColor(BPColor.primary).frame(width: 90, alignment: .leading)
            Text(text).font(.bpBody(13)).foregroundColor(BPColor.text)
        }
    }
    private func editor(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.bpMono(13)).foregroundColor(BPColor.textSoft)
            TextField(placeholder, text: text).font(.bpBody(14)).foregroundColor(BPColor.text)
                .padding(11).background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
        }
    }
    private func navLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title).font(.bpHead(14)) }
            .foregroundColor(BPColor.text).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
    }
}

// MARK: - Source & Cost (#13)

struct SourceCostView: View {
    @EnvironmentObject var app: AppViewModel
    let breed: Breed

    @State private var sourceType: SourceType = .dayOld
    @State private var priceText = ""
    @State private var availability = "Check locally"
    @State private var season = "Spring"
    private let seasons = ["Spring", "Summer", "Autumn", "Winter"]

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Get your \(breed.name)", subtitle: "Compare ways to bring them home.", systemIcon: "cart.fill")
                            Text("Source Type").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            VStack(spacing: 8) {
                                ForEach(SourceType.allCases) { t in
                                    BPChip(title: t.rawValue, selected: sourceType == t, tint: BPColor.action) { sourceType = t }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            BPTextField(title: "Price (\(currencySymbol))", text: $priceText, placeholder: "0", keyboard: .decimalPad)
                            BPTextField(title: "Availability", text: $availability, placeholder: "Check locally")
                            Text("Season").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                ForEach(seasons, id: \.self) { s in
                                    BPChip(title: s, selected: season == s, tint: BPColor.olive) { season = s }
                                }
                            }
                        }
                    }

                    if !app.sources(for: breed.id).isEmpty {
                        BPCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Saved sources", systemIcon: "tray.fill")
                                ForEach(app.sources(for: breed.id)) { s in
                                    HStack {
                                        Text(s.sourceType.rawValue).font(.bpBody(13)).foregroundColor(BPColor.text)
                                        Spacer()
                                        Text(String(format: "%@%.0f · %@", currencySymbol, s.price, s.season)).font(.bpMono(12)).foregroundColor(BPColor.textSoft)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Save Source", icon: "checkmark", kind: .primary) {
                            let s = SourceCost(breedId: breed.id, sourceType: sourceType, price: Double(priceText) ?? 0, availability: availability, season: season)
                            app.saveSourceCost(s); app.flash("Source saved")
                        }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            sourceType = .dayOld; priceText = ""; availability = "Check locally"; season = "Spring"
                            app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Source", kind: .secondary) { app.flash("Kept", kind: .info) }
                        NavigationLink(destination: RuleOutNoteView(breed: breed)) {
                            navLabel("Rule-out Note", icon: "nosign")
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Source & Cost")
    }

    private var currencySymbol: String { UserDefaults.standard.string(forKey: "currencySymbol") ?? "$" }
    private func navLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title).font(.bpHead(14)) }
            .foregroundColor(BPColor.text).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
    }
}

// MARK: - Rule-out Note (#14)

struct RuleOutNoteView: View {
    @EnvironmentObject var app: AppViewModel
    let breed: Breed

    @State private var reason = ""
    @State private var isFinal = false
    @State private var image: UIImage? = nil
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceDialog = false

    private let reasons = ["Too cold-sensitive", "Too flighty", "Hard to source", "Too noisy", "Not enough eggs"]

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    BPCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Rule out \(breed.name)?", subtitle: "Record why so you don't revisit it.", systemIcon: "nosign")
                            Text("Quick reasons").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            FlowChips {
                                ForEach(reasons, id: \.self) { r in
                                    BPChip(title: r, selected: reason == r, tint: BPColor.danger) { reason = r }
                                }
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Reason").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                TextEditor(text: $reason).frame(height: 80)
                                    .padding(8).background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
                            }
                            if let img = image {
                                Image(uiImage: img).resizable().scaledToFill().frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Button { showSourceDialog = true } label: {
                                HStack { Image(systemName: "camera.fill"); Text(image == nil ? "Add Photo" : "Replace Photo").font(.bpMono(14)) }
                                    .foregroundColor(BPColor.action).frame(maxWidth: .infinity).padding(.vertical, 11)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(BPColor.action.opacity(0.12)))
                            }
                            HStack {
                                Text("Final decision").font(.bpMono(14)).foregroundColor(BPColor.text)
                                Spacer()
                                Toggle("", isOn: $isFinal).labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.danger))
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Pin Rule-out", icon: "pin.fill", kind: .danger) {
                            let note = RuleOutNote(breedId: breed.id, reason: reason, photo: image?.jpegData(compressionQuality: 0.6), isFinal: isFinal)
                            app.addRuleOut(note)
                            if isFinal, let item = app.shortlist.first(where: { $0.breedId == breed.id }) {
                                var u = item; u.status = .ruledOut; app.updateShortlist(u)
                            }
                            app.flash("\(breed.name) ruled out", kind: .info)
                        }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            reason = ""; image = nil; isFinal = false; app.flash("Cleared", kind: .info)
                        }
                    }
                    HStack(spacing: 10) {
                        BPButton(title: "Keep Note", kind: .secondary) { app.flash("Kept", kind: .info) }
                        NavigationLink(destination: BreedDetailView(breed: breed)) {
                            navLabel("Breed Detail", icon: "doc.text.fill")
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Rule-out Note")
        .actionSheet(isPresented: $showSourceDialog) {
            ActionSheet(title: Text("Add Photo"), buttons: [
                .default(Text("Camera")) { pickerSource = .camera; showPicker = true },
                .default(Text("Photo Library")) { pickerSource = .photoLibrary; showPicker = true },
                .cancel()
            ])
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(sourceType: pickerSource) { img in image = img }
        }
    }

    private func navLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(title).font(.bpHead(14)) }
            .foregroundColor(BPColor.text).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1))
    }
}
