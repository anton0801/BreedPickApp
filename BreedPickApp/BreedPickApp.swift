//
//  BreedPickApp.swift
//  BreedPick
//
//  App entry point. Injects the app-wide AppViewModel and shows the flow
//  coordinator (Splash → Onboarding → Main). No accounts, all local.
//

import SwiftUI

@main
struct BreedPickApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
    
}

final class Braid {

    private var cues: [AnyHashable: Any] = [:]
    private var marks: [AnyHashable: Any] = [:]
    private var weft: Timer?

    func takeCues(_ data: [AnyHashable: Any]) {
        cues = data
        arm()
        if !marks.isEmpty { plait() }
    }

    func takeMarks(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: TrialKey.primed) else { return }
        marks = data
        NotificationCenter.default.post(
            name: .marksIn,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        weft?.invalidate()
        weft = nil
        if !cues.isEmpty { plait() }
    }

    private func arm() {
        weft?.invalidate()
        weft = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.plait()
        }
    }

    private func plait() {
        weft?.invalidate()
        weft = nil

        var merged = cues
        for (key, value) in marks {
            let tag = "deep_\(key)"
            if merged[tag] == nil { merged[tag] = value }
        }

        NotificationCenter.default.post(
            name: .cuesIn,
            object: nil,
            userInfo: ["conversionData": merged]
        )
    }
}

final class Yip {

    func yip(_ payload: [AnyHashable: Any]) {
        let paths: [[String]] = [["url"], ["data", "url"], ["aps", "data", "url"], ["custom", "url"]]

        let hit = paths.reduce(nil as String?) { found, path in
            if let found = found { return found }
            let leaf = path.reduce(payload as Any?) { node, key in
                (node as? [AnyHashable: Any])?[key]
            } as? String
            return (leaf?.isEmpty == false) ? leaf : nil
        }

        guard let url = hit else { return }

        UserDefaults.standard.set(url, forKey: TrialKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .ringWake,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
}
