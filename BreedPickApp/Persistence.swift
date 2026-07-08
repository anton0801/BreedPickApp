//
//  Persistence.swift
//  BreedPick
//
//  Thin JSON-over-UserDefaults store. No accounts, no network — everything
//  stays on device.
//

import Foundation

enum Store {
    private static let defaults = UserDefaults.standard
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func save<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, _ key: String, default def: T) -> T {
        guard let data = defaults.data(forKey: key),
              let value = try? decoder.decode(type, from: data) else { return def }
        return value
    }
}

enum StoreKey {
    static let prefs        = "bp.prefs"
    static let shortlist    = "bp.shortlist"
    static let flockMix     = "bp.flockMix"
    static let ruleOuts     = "bp.ruleOuts"
    static let careNotes    = "bp.careNotes"
    static let sourceCosts  = "bp.sourceCosts"
    static let reminders    = "bp.reminders"
    static let decisions    = "bp.decisions"
}
