//
//  UtilityViews.swift
//  BreedPick
//
//  UIKit bridges: PDF report builder, share sheet, photo picker and a
//  finger-drawn signature pad. All local, no network.
//

import SwiftUI
import UIKit

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Photo picker (camera + library)

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onImage: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Signature pad

struct SignaturePad: View {
    @Binding var lines: [[CGPoint]]
    var strokeColor: Color = BPColor.text

    @State private var current: [CGPoint] = []

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(BPColor.bgSoft)
            RoundedRectangle(cornerRadius: 14).stroke(BPColor.border, lineWidth: 1)
            SignatureShape(lines: lines + [current])
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            if lines.isEmpty && current.isEmpty {
                Text("Sign here with your finger")
                    .font(.bpBody(13)).foregroundColor(BPColor.textMute)
            }
        }
        .frame(height: 150)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in current.append(v.location) }
            .onEnded { _ in lines.append(current); current = [] })
    }
}

struct SignatureShape: Shape {
    let lines: [[CGPoint]]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for line in lines {
            guard let first = line.first else { continue }
            p.move(to: first)
            for pt in line.dropFirst() { p.addLine(to: pt) }
        }
        return p
    }
}

enum SignatureRenderer {
    /// Render finger strokes to a PNG for storage / PDF embedding.
    static func png(lines: [[CGPoint]], size: CGSize) -> Data? {
        guard !lines.isEmpty else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.setStrokeColor(UIColor(uiColorHex: "3A2C12").cgColor)
            ctx.cgContext.setLineWidth(2.5)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)
            for line in lines {
                guard let first = line.first else { continue }
                ctx.cgContext.move(to: first)
                for pt in line.dropFirst() { ctx.cgContext.addLine(to: pt) }
            }
            ctx.cgContext.strokePath()
        }
        return img.pngData()
    }
}

extension UIColor {
    convenience init(uiColorHex hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(red: CGFloat((int >> 16) & 0xFF) / 255,
                  green: CGFloat((int >> 8) & 0xFF) / 255,
                  blue: CGFloat(int & 0xFF) / 255, alpha: 1)
    }
}

// MARK: - PDF report builder

enum ReportSection: String, CaseIterable, Identifiable {
    case priorities = "Priorities & Goals"
    case shortlist  = "Shortlist"
    case flockMix   = "Flock Mix"
    case care       = "Care Preview"
    case sources    = "Sources & Cost"
    var id: String { rawValue }
}

enum PDFBuilder {

    static func makeReport(title: String,
                           sections: Set<ReportSection>,
                           notes: String,
                           app: AppViewModel) -> URL? {
        let pageW: CGFloat = 595, pageH: CGFloat = 842   // A4 @72dpi
        let margin: CGFloat = 42
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH),
                                             format: format)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BreedPick-Report.pdf")

        let amber = UIColor(uiColorHex: "E0982A")
        let ink = UIColor(uiColorHex: "3A2C12")
        let soft = UIColor(uiColorHex: "6E5A2C")

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y: CGFloat = margin

                func newPageIfNeeded(_ needed: CGFloat) {
                    if y + needed > pageH - margin {
                        ctx.beginPage(); y = margin
                    }
                }
                func draw(_ text: String, font: UIFont, color: UIColor, gap: CGFloat = 6) {
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    let bounding = (text as NSString).boundingRect(
                        with: CGSize(width: pageW - margin * 2, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: attrs, context: nil)
                    newPageIfNeeded(bounding.height + gap)
                    (text as NSString).draw(with: CGRect(x: margin, y: y,
                                                         width: pageW - margin * 2, height: bounding.height),
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            attributes: attrs, context: nil)
                    y += bounding.height + gap
                }

                // Header band
                amber.setFill()
                ctx.cgContext.fill(CGRect(x: 0, y: 0, width: pageW, height: 8))
                draw("Breed Pick", font: .systemFont(ofSize: 13, weight: .bold), color: amber, gap: 2)
                draw(title, font: .systemFont(ofSize: 26, weight: .heavy), color: ink, gap: 4)
                let df = DateFormatter(); df.dateStyle = .long
                draw("Generated \(df.string(from: Date()))",
                     font: .systemFont(ofSize: 11), color: soft, gap: 18)

                if sections.contains(.priorities) {
                    draw("Priorities & Goals", font: .systemFont(ofSize: 17, weight: .bold), color: amber)
                    let p = app.prefs
                    draw("Main want: \(p.mainWant.rawValue)", font: .systemFont(ofSize: 12), color: ink, gap: 3)
                    draw("Egg weight \(pct(p.eggWeight)) · Meat weight \(pct(p.meatWeight)) · Temperament \(pct(p.temperamentWeight)) · Hardiness \(pct(p.hardinessWeight))",
                         font: .systemFont(ofSize: 12), color: ink, gap: 3)
                    draw("Climate: winter \(p.winterLevel.label), summer \(p.summerLevel.label)\(p.damp ? ", damp" : "")",
                         font: .systemFont(ofSize: 12), color: ink, gap: 3)
                    draw("Setup: \(p.setup.label) · Family-friendly: \(p.kidsFamily ? "Yes" : "No")",
                         font: .systemFont(ofSize: 12), color: ink, gap: 14)
                }

                if sections.contains(.shortlist) {
                    draw("Shortlist", font: .systemFont(ofSize: 17, weight: .bold), color: amber)
                    if app.shortlist.isEmpty {
                        draw("No breeds shortlisted yet.", font: .systemFont(ofSize: 12), color: soft, gap: 14)
                    } else {
                        for item in app.shortlist.sorted(by: { $0.rank < $1.rank }) {
                            if let b = BreedDatabase.breed(item.breedId) {
                                let m = app.match(for: b)
                                draw("• \(b.name) — \(m.percent)% match · \(item.status.rawValue)",
                                     font: .systemFont(ofSize: 12, weight: .semibold), color: ink, gap: 2)
                                if !item.notes.isEmpty {
                                    draw("   \(item.notes)", font: .systemFont(ofSize: 11), color: soft, gap: 2)
                                }
                            }
                        }
                        y += 12
                    }
                }

                if sections.contains(.flockMix) {
                    draw("Flock Mix", font: .systemFont(ofSize: 17, weight: .bold), color: amber)
                    let report = MatchEngine.analyzeMix(app.flockMix)
                    if app.flockMix.isEmpty {
                        draw("No flock mix built yet.", font: .systemFont(ofSize: 12), color: soft, gap: 14)
                    } else {
                        for e in app.flockMix {
                            draw("• \(e.count) × \(BreedDatabase.name(e.breedId))",
                                 font: .systemFont(ofSize: 12, weight: .semibold), color: ink, gap: 2)
                        }
                        draw(report.summary, font: .systemFont(ofSize: 11), color: soft, gap: 14)
                    }
                }

                if sections.contains(.care) {
                    draw("Care Preview", font: .systemFont(ofSize: 17, weight: .bold), color: amber)
                    if app.careNotes.isEmpty {
                        draw("No care notes saved.", font: .systemFont(ofSize: 12), color: soft, gap: 14)
                    } else {
                        for c in app.careNotes {
                            draw("• \(BreedDatabase.name(c.breedId))", font: .systemFont(ofSize: 12, weight: .semibold), color: ink, gap: 2)
                            let detail = [c.feedNeed, c.spaceCold, c.specialCare].filter { !$0.isEmpty }.joined(separator: " · ")
                            if !detail.isEmpty { draw("   \(detail)", font: .systemFont(ofSize: 11), color: soft, gap: 2) }
                        }
                        y += 12
                    }
                }

                if sections.contains(.sources) {
                    draw("Sources & Cost", font: .systemFont(ofSize: 17, weight: .bold), color: amber)
                    if app.sourceCosts.isEmpty {
                        draw("No sources logged.", font: .systemFont(ofSize: 12), color: soft, gap: 14)
                    } else {
                        for s in app.sourceCosts {
                            draw("• \(BreedDatabase.name(s.breedId)) — \(s.sourceType.rawValue), \(currency(s.price)), \(s.season)",
                                 font: .systemFont(ofSize: 12), color: ink, gap: 2)
                        }
                        y += 12
                    }
                }

                if !notes.isEmpty {
                    draw("Notes", font: .systemFont(ofSize: 17, weight: .bold), color: amber)
                    draw(notes, font: .systemFont(ofSize: 12), color: ink, gap: 14)
                }
            }
            return url
        } catch {
            return nil
        }
    }

    private static func pct(_ v: Double) -> String { "\(Int(v * 100))%" }
    private static func currency(_ v: Double) -> String { String(format: "$%.0f", v) }
}
