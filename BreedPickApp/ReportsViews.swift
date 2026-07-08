//
//  ReportsViews.swift
//  BreedPick
//
//  Tab 5 — Reports & Export (#18) with local analytics and PDF export, plus
//  Reminders Center (#17) backed by real UNUserNotificationCenter scheduling.
//

import SwiftUI

// MARK: - Reports & Export (#18)

struct ReportsTab: View {
    @EnvironmentObject var app: AppViewModel

    @State private var sections: Set<ReportSection> = Set(ReportSection.allCases)
    @State private var notes = ""
    @State private var format = "PDF"
    @State private var shareURL: URL? = nil
    @State private var showShare = false

    var body: some View {
        NavigationView {
            ZStack {
                BPColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        analyticsCard

                        BPCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Build a local report", subtitle: "Choose what to include, then export a PDF.", systemIcon: "doc.text.fill")
                                BPTextField(title: "Project", text: $app.prefs.listTitle, placeholder: "My Flock")
                                Text("Include Sections").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                ForEach(ReportSection.allCases) { sec in
                                    Button { toggle(sec) } label: {
                                        HStack {
                                            Image(systemName: sections.contains(sec) ? "checkmark.square.fill" : "square")
                                                .foregroundColor(sections.contains(sec) ? BPColor.match : BPColor.textMute)
                                            Text(sec.rawValue).font(.bpBody(14)).foregroundColor(BPColor.text)
                                            Spacer()
                                        }
                                    }.buttonStyle(PlainButtonStyle())
                                }
                                Text("Format").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                HStack(spacing: 8) {
                                    BPChip(title: "PDF", selected: format == "PDF") { format = "PDF" }
                                    BPChip(title: "Text", selected: format == "Text") { format = "Text" }
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Notes").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                                    TextEditor(text: $notes).frame(height: 70)
                                        .padding(8).background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            BPButton(title: "Generate Report", icon: "doc.text.fill", kind: .primary) {
                                app.flash("Report ready · \(sections.count) sections")
                            }
                            BPButton(title: "Export PDF", icon: "square.and.arrow.up", kind: .action, fullWidth: false) { export() }
                        }
                        HStack(spacing: 10) {
                            BPButton(title: "Share Locally", icon: "square.and.arrow.up", kind: .secondary) { export() }
                            BPButton(title: "Back to Goals", icon: "slider.horizontal.3", kind: .secondary) { withAnimation { app.selectedTab = 0 } }
                        }
                        NavigationLink(destination: RemindersCenterView()) {
                            NavRow(title: "Reminders Center", subtitle: "\(app.reminders.count) local nudges set", icon: "bell.fill", tint: BPColor.action)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
                }
            }
            .bpScreen("Reports")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { SettingsGear() } }
            .sheet(isPresented: $showShare) {
                if let url = shareURL { ShareSheet(items: [url]) }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var analyticsCard: some View {
        let ranked = app.rankedMatches
        let strong = ranked.filter { $0.percent >= 70 }.count
        let risks = app.climateFlagged.count
        let mix = MatchEngine.analyzeMix(app.flockMix)
        let chosen = app.shortlist.filter { $0.status == .chosen }.count
        return BPCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Flock analytics", systemIcon: "chart.bar.fill")
                HStack(spacing: 10) {
                    statTile("\(strong)", "Strong matches", BPColor.match)
                    statTile("\(risks)", "Climate risks", risks > 0 ? BPColor.danger : BPColor.match)
                }
                HStack(spacing: 10) {
                    statTile(mix.balanced ? "Yes" : "No", "Year-round eggs", mix.balanced ? BPColor.match : BPColor.warn)
                    statTile("\(chosen)", "Breeds chosen", BPColor.primary)
                }
                // Readiness bar
                let readiness = readinessScore(strong: strong, chosen: chosen, mixBalanced: mix.balanced)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Purchase readiness").font(.bpMono(12)).foregroundColor(BPColor.textSoft)
                        Spacer()
                        Text("\(readiness)%").font(.bpMono(13)).foregroundColor(BPColor.primary)
                    }
                    MatchBar(percent: readiness).frame(height: 9)
                }
            }
        }
    }

    private func statTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(color)
            Text(label).font(.bpBody(11)).foregroundColor(BPColor.textSoft)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(BPColor.bgSoft))
    }

    private func readinessScore(strong: Int, chosen: Int, mixBalanced: Bool) -> Int {
        var s = 0
        if strong > 0 { s += 25 }
        if chosen > 0 { s += 30 }
        if mixBalanced { s += 25 }
        if !app.reminders.isEmpty { s += 20 }
        return min(100, s)
    }

    private func toggle(_ sec: ReportSection) {
        if sections.contains(sec) { sections.remove(sec) } else { sections.insert(sec) }
    }

    private func export() {
        if let url = PDFBuilder.makeReport(title: app.prefs.listTitle, sections: sections, notes: notes, app: app) {
            shareURL = url; showShare = true
        } else {
            app.flash("Could not build PDF", kind: .error)
        }
    }
}

// MARK: - Reminders Center (#17)

struct RemindersCenterView: View {
    @EnvironmentObject var app: AppViewModel
    @ObservedObject private var notif = NotificationManager.shared

    @State private var type: ReminderType = .buySeason
    @State private var date = Date().addingTimeInterval(60 * 60 * 24)
    @State private var breedName = ""
    @State private var repeats: RepeatRule = .none

    var body: some View {
        ZStack {
            BPColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if !notif.authorized {
                        BPCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.slash.fill").foregroundColor(BPColor.warn)
                                    Text("Notifications are off").font(.bpHead(15)).foregroundColor(BPColor.text)
                                }
                                Text("Enable local reminders for chick-buying season, availability checks and coop prep.")
                                    .font(.bpBody(13)).foregroundColor(BPColor.textSoft)
                                BPButton(title: "Enable Notifications", icon: "bell.fill", kind: .primary) {
                                    notif.requestAuthorization { granted in
                                        app.flash(granted ? "Notifications enabled" : "Permission denied", kind: granted ? .success : .warning)
                                    }
                                }
                            }
                        }
                    }

                    BPCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "New reminder", subtitle: "Local nudges for getting your birds.", systemIcon: "bell.fill")
                            Text("Reminder Type").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            VStack(spacing: 8) {
                                ForEach(ReminderType.allCases) { t in
                                    Button { type = t } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: t.glyph).foregroundColor(type == t ? .white : BPColor.primary).frame(width: 22)
                                            Text(t.rawValue).font(.bpBody(14)).foregroundColor(type == t ? .white : BPColor.text)
                                            Spacer()
                                            if type == t { Image(systemName: "checkmark").foregroundColor(.white) }
                                        }
                                        .padding(11)
                                        .background(RoundedRectangle(cornerRadius: 11).fill(type == t ? BPColor.primary : BPColor.bgSoft))
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }
                            DatePicker("When", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .font(.bpMono(13)).accentColor(BPColor.primary)
                            Text("Breed (optional)").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            Menu {
                                Button("Any breed") { breedName = "" }
                                ForEach(BreedDatabase.all) { b in Button(b.name) { breedName = b.name } }
                            } label: {
                                HStack {
                                    Text(breedName.isEmpty ? "Any breed" : breedName).font(.bpBody(14))
                                        .foregroundColor(breedName.isEmpty ? BPColor.textMute : BPColor.text)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundColor(BPColor.textMute)
                                }
                                .padding(11).background(RoundedRectangle(cornerRadius: 11).fill(BPColor.bgSoft))
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(BPColor.border, lineWidth: 1))
                            }
                            Text("Repeat").font(.bpMono(13)).foregroundColor(BPColor.textSoft)
                            HStack(spacing: 8) {
                                ForEach(RepeatRule.allCases) { r in
                                    BPChip(title: r.rawValue, selected: repeats == r, tint: BPColor.olive) { repeats = r }
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        BPButton(title: "Add Reminder", icon: "plus", kind: .primary) {
                            if !notif.authorized { notif.requestAuthorization() }
                            let r = Reminder(type: type, breedName: breedName, date: date, repeats: repeats, enabled: true)
                            app.addReminder(r); app.flash("Reminder scheduled")
                        }
                        BPButton(title: "Clear", icon: "arrow.counterclockwise", kind: .secondary, fullWidth: false) {
                            type = .buySeason; breedName = ""; repeats = .none; date = Date().addingTimeInterval(86400)
                            app.flash("Cleared", kind: .info)
                        }
                    }

                    if !app.reminders.isEmpty {
                        BPCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(title: "Scheduled", systemIcon: "list.bullet")
                                ForEach(app.reminders) { r in reminderRow(r) }
                            }
                        }
                        HStack(spacing: 10) {
                            BPButton(title: "Keep Reminders", kind: .secondary) { app.flash("Kept", kind: .info) }
                            BPButton(title: "Open Reports", icon: "doc.text.fill", kind: .action) { withAnimation { app.selectedTab = 4 } }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 30)
            }
        }
        .bpScreen("Reminders")
        .onAppear { notif.refreshStatus() }
    }

    private func reminderRow(_ r: Reminder) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(BPColor.action.opacity(0.15)).frame(width: 38, height: 38)
                Image(systemName: r.type.glyph).foregroundColor(BPColor.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(r.type.rawValue).font(.bpMono(13)).foregroundColor(BPColor.text)
                Text("\(dateString(r.date)) · \(r.repeats.rawValue)\(r.breedName.isEmpty ? "" : " · \(r.breedName)")")
                    .font(.bpBody(11)).foregroundColor(BPColor.textMute)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { r.enabled }, set: { _ in app.toggleReminder(r) }))
                .labelsHidden().toggleStyle(SwitchToggleStyle(tint: BPColor.match))
            Button { app.removeReminder(r) } label: { Image(systemName: "trash.fill").foregroundColor(BPColor.danger) }
        }
    }

    private func dateString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f.string(from: d)
    }
}
