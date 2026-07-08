//
//  Models.swift
//  BreedPick
//
//  Core data models, enums and value types for the breed-matching engine.
//

import Foundation
import SwiftUI

// MARK: - Primary intent / purpose

enum Purpose: String, Codable, CaseIterable, Identifiable {
    case eggs       = "Eggs"
    case meat       = "Meat"
    case dual       = "Dual Purpose"
    case ornamental = "Ornamental/Pets"

    var id: String { rawValue }

    var short: String {
        switch self {
        case .eggs: return "Eggs"
        case .meat: return "Meat"
        case .dual: return "Dual"
        case .ornamental: return "Pets"
        }
    }

    /// Custom-drawn icon name maps to a symbol drawn in code, not SF Symbols.
    var glyph: String {
        switch self {
        case .eggs: return "egg"
        case .meat: return "drumstick"
        case .dual: return "scale"
        case .ornamental: return "feather"
        }
    }
}

// MARK: - Egg attributes

enum EggColor: String, Codable, CaseIterable, Identifiable {
    case white, cream, brown, darkBrown, blue, green

    var id: String { rawValue }

    var label: String {
        switch self {
        case .white: return "White"
        case .cream: return "Cream"
        case .brown: return "Brown"
        case .darkBrown: return "Dark Brown"
        case .blue: return "Blue"
        case .green: return "Green"
        }
    }

    var swatch: Color {
        switch self {
        case .white: return Color(hex: "FFFFFF")
        case .cream: return Color(hex: "F3E4C4")
        case .brown: return Color(hex: "C98A52")
        case .darkBrown: return Color(hex: "8A4B25")
        case .blue: return Color(hex: "A8CBD6")
        case .green: return Color(hex: "AEBE8A")
        }
    }
}

enum EggSize: String, Codable, CaseIterable, Identifiable {
    case small, medium, large, extraLarge

    var id: String { rawValue }
    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "X-Large"
        }
    }
    var rank: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        case .extraLarge: return 4
        }
    }
}

enum Season: String, Codable, CaseIterable, Identifiable {
    case spring, summer, autumn, winter
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

// MARK: - Climate

enum TempLevel: String, Codable, CaseIterable, Identifiable {
    case cold, mild, warm, hot
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ClimateRisk: String, Codable {
    case none, caution, severe

    var label: String {
        switch self {
        case .none: return "Climate OK"
        case .caution: return "Climate Caution"
        case .severe: return "Climate Risk"
        }
    }
}

// MARK: - Housing setup

enum Setup: String, Codable, CaseIterable, Identifiable {
    case freeRange = "Free-range"
    case smallYard = "Small Yard"
    case confined  = "Run/Confined"
    var id: String { rawValue }
    var label: String { rawValue }
}

// MARK: - Breed

struct Breed: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var purpose: Purpose
    var eggsPerYear: Int
    var eggColor: EggColor
    var eggSize: EggSize
    var weightLb: Double          // hen live weight
    var coldHardiness: Int        // 1...5
    var heatTolerance: Int        // 1...5
    var calmness: Int             // 1...5 (5 = very calm)
    var friendliness: Int         // 1...5
    var flightiness: Int          // 1...5 (5 = very flighty)
    var noise: Int                // 1...5 (5 = loud)
    var broodiness: Int           // 1...5
    var confinementTolerance: Int // 1...5
    var foraging: Int             // 1...5
    var layingSeasons: [Season]
    var pros: [String]
    var cons: [String]
    var appearance: String
    var summary: String
    var accentHex: String

    var accent: Color { Color(hex: accentHex) }

    var kidFriendly: Bool { calmness >= 4 && friendliness >= 4 && flightiness <= 2 }
}

// MARK: - User preferences (single source of truth for matching)

struct Preferences: Codable, Equatable {
    var listTitle: String = "My Flock"
    var mainWant: Purpose = .eggs
    var useFrequency: String = "Daily"

    // Priority weights 0...1
    var eggWeight: Double = 0.7
    var meatWeight: Double = 0.3
    var temperamentWeight: Double = 0.6
    var hardinessWeight: Double = 0.6

    // Onboarding goal-dials (also feed weights live)
    var eggMeatDial: Double = 0.3     // 0 = full egg, 1 = full meat
    var calmActiveDial: Double = 0.4  // 0 = calm, 1 = active
    var hardyDelicateDial: Double = 0.3 // 0 = hardy, 1 = delicate

    // Climate
    var winterLevel: TempLevel = .mild
    var summerLevel: TempLevel = .warm
    var damp: Bool = false
    var useMetric: Bool = true

    // Temperament desires (targets, 1...5)
    var calmnessWant: Int = 3
    var friendlinessWant: Int = 3
    var lowFlightWant: Int = 3   // higher = want calmer / less flighty
    var quietWant: Int = 3       // higher = want quieter

    // Space / household
    var setup: Setup = .freeRange
    var confinementNeed: Int = 3 // how much confinement tolerance the flock needs
    var kidsFamily: Bool = false

    // Egg profile
    var eggColorWant: EggColor? = nil   // nil = any
    var eggSizeWant: EggSize? = nil     // nil = any
    var eggsPerYearWant: Int = 250
    var wantBroody: Bool = false

    /// Re-derive priority weights from the onboarding dials so the live
    /// counter and rankings respond as the user turns the dials.
    mutating func syncWeightsFromDials() {
        eggWeight = max(0.1, 1.0 - eggMeatDial)
        meatWeight = max(0.1, eggMeatDial)
        // Active birds care less about temperament fit; calm birds care more.
        temperamentWeight = max(0.2, 1.0 - calmActiveDial * 0.6)
        // Delicate preference lowers the demand for hardiness.
        hardinessWeight = max(0.2, 1.0 - hardyDelicateDial)
        // Reflect dials into temperament targets too.
        calmnessWant = Int((1.0 - calmActiveDial) * 4) + 1
        lowFlightWant = Int((1.0 - calmActiveDial) * 4) + 1
    }
}

// MARK: - Match result

struct MatchResult: Identifiable {
    var id: String { breed.id }
    var breed: Breed
    var percent: Int
    var eggScore: Double
    var meatScore: Double
    var climateScore: Double
    var temperamentScore: Double
    var spaceScore: Double
    var climateRisk: ClimateRisk
    var climateReason: String?

    var band: MatchBand {
        if percent >= 70 { return .good }
        if percent >= 50 { return .fair }
        return .poor
    }
}

enum MatchBand {
    case good, fair, poor
    var color: Color {
        switch self {
        case .good: return BPColor.match
        case .fair: return BPColor.warn
        case .poor: return BPColor.danger
        }
    }
    var label: String {
        switch self {
        case .good: return "Strong fit"
        case .fair: return "Possible fit"
        case .poor: return "Weak fit"
        }
    }
}

// MARK: - Shortlist

enum ShortStatus: String, Codable, CaseIterable, Identifiable {
    case considering = "Considering"
    case chosen      = "Chosen"
    case ruledOut    = "Ruled Out"
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .considering: return BPColor.primary
        case .chosen: return BPColor.match
        case .ruledOut: return BPColor.danger
        }
    }
}

enum TrialKey {
    static let routeURL = "bp_route_url"
    static let routeMode = "bp_route_mode"
    static let primed = "bp_primed"
    static let rewardGranted = "bp_reward_granted"
    static let rewardBarred = "bp_reward_barred"
    static let rewardAt = "bp_reward_at"
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
    static let attStatus = "att_status"
    static let sharedFcm = "shared_fcm"
}

struct ShortlistItem: Identifiable, Codable, Hashable {
    var id: String { breedId }
    var breedId: String
    var status: ShortStatus = .considering
    var notes: String = ""
    var rank: Int = 0
}

// MARK: - Flock mix

struct FlockMixEntry: Identifiable, Codable, Hashable {
    var id: String { breedId }
    var breedId: String
    var count: Int = 3
}

// MARK: - Rule-out note

struct RuleOutNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var breedId: String
    var reason: String = ""
    var photo: Data? = nil
    var isFinal: Bool = false
    var date: Date = Date()
}

// MARK: - Care & source notes

struct CareNote: Identifiable, Codable, Hashable {
    var id: String { breedId }
    var breedId: String
    var feedNeed: String = ""
    var spaceCold: String = ""
    var specialCare: String = ""
}

enum SourceType: String, Codable, CaseIterable, Identifiable {
    case dayOld = "Day-old Chicks"
    case grown  = "Started Pullets"
    case eggs   = "Hatching Eggs"
    var id: String { rawValue }
}

struct SourceCost: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var breedId: String
    var sourceType: SourceType = .dayOld
    var price: Double = 0
    var availability: String = "Check locally"
    var season: String = "Spring"
}

// MARK: - Reminders

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case buySeason        = "Buy chicks season"
    case checkAvailability = "Check availability"
    case prepCoop         = "Prepare the coop"
    case recheckDefect    = "Re-check breed"
    var id: String { rawValue }

    var glyph: String {
        switch self {
        case .buySeason: return "calendar"
        case .checkAvailability: return "magnifyingglass"
        case .prepCoop: return "house.fill"
        case .recheckDefect: return "arrow.clockwise"
        }
    }
}

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case none = "Once"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    var id: String { rawValue }
}

struct Reminder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: ReminderType = .buySeason
    var breedName: String = ""
    var date: Date = Date().addingTimeInterval(60 * 60 * 24)
    var repeats: RepeatRule = .none
    var enabled: Bool = true
}

extension Notification.Name {
    static let cuesIn = Notification.Name("ConversionDataReceived")
    static let marksIn = Notification.Name("deeplink_values")
    static let ringWake = Notification.Name("LoadTempURL")
}

// MARK: - Decision signoff

struct DecisionRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var listTitle: String = "My Flock"
    var chosenBreedIds: [String] = []
    var reasons: String = ""
    var comment: String = ""
    var signature: Data? = nil
    var date: Date = Date()
}
