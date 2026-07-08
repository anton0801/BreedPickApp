import Foundation

struct Card {
    var cues: [String: String] = [:]
    var marks: [String: String] = [:]
    var routeURL: String?
    var routeMode: String?
    var penned: Bool = true
    var cleared: Bool = false
    var weaved: Bool = false
    var rewardGranted: Bool = false
    var rewardBarred: Bool = false
    var rewardAt: Date?

    var hasCues: Bool {
        !cues.isEmpty
    }

    var organicScent: Bool {
        (cues["af_status"] ?? "").caseInsensitiveCompare("Organic") == .orderedSame
    }

    var rewardDue: Bool {
        guard !rewardGranted && !rewardBarred else { return false }
        if let at = rewardAt {
            return Date().timeIntervalSince(at) / 86_400 >= 3
        }
        return true
    }

    func stub() -> Stub {
        Stub(
            cues: cues,
            marks: marks,
            routeURL: routeURL,
            routeMode: routeMode,
            penned: penned,
            weaved: weaved,
            rewardGranted: rewardGranted,
            rewardBarred: rewardBarred,
            rewardAt: rewardAt
        )
    }
}

struct Stub: Codable {
    var cues: [String: String]
    var marks: [String: String]
    var routeURL: String?
    var routeMode: String?
    var penned: Bool
    var weaved: Bool
    var rewardGranted: Bool
    var rewardBarred: Bool
    var rewardAt: Date?

    func reseat() -> Card {
        var card = Card()
        card.cues = cues
        card.marks = marks
        card.routeURL = routeURL
        card.routeMode = routeMode
        card.penned = penned
        card.weaved = weaved
        card.rewardGranted = rewardGranted
        card.rewardBarred = rewardBarred
        card.rewardAt = rewardAt
        return card
    }
}

enum Score {
    case stall
    case reward
    case qualify
    case eliminate
}

enum Step {
    case loop
    case halt
}

struct Rule {
    let gate: () -> Bool
    let fire: () async -> Step
}
