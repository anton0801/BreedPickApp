//
//  NotificationManager.swift
//  BreedPick
//
//  Real local notifications via UNUserNotificationCenter — seasonal chick-buy
//  windows, availability checks and coop-prep nudges. No push, no server.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var authorized = false

    private let center = UNUserNotificationCenter.current()

    private init() { refreshStatus() }

    func refreshStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
            }
        }
    }

    func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.authorized = granted
                completion?(granted)
            }
        }
    }

    func schedule(_ reminder: Reminder) {
        cancel(reminder.id)
        guard reminder.enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.type.rawValue
        var body = ""
        switch reminder.type {
        case .buySeason:
            body = reminder.breedName.isEmpty
                ? "Chick season is here — time to order your young birds."
                : "Chick season is here — order your \(reminder.breedName)."
        case .checkAvailability:
            body = reminder.breedName.isEmpty
                ? "Check which breeds your hatchery has in stock."
                : "Check availability of \(reminder.breedName) at your hatchery."
        case .prepCoop:
            body = reminder.breedName.isEmpty
                ? "Prepare and weatherproof the coop before the birds arrive."
                : "Prepare the coop for your \(reminder.breedName)."
        case .recheckDefect:
            body = reminder.breedName.isEmpty
                ? "Revisit your shortlist and confirm your breed choice."
                : "Take another look at \(reminder.breedName) before you decide."
        }
        content.body = body
        content.sound = .default

        let trigger = makeTrigger(for: reminder)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString,
                                            content: content, trigger: trigger)
        center.add(request)
    }

    private func makeTrigger(for reminder: Reminder) -> UNNotificationTrigger {
        let cal = Calendar.current
        switch reminder.repeats {
        case .none:
            // Fire at the chosen moment (must be in the future).
            let fireDate = reminder.date > Date() ? reminder.date : Date().addingTimeInterval(5)
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        case .weekly:
            let comps = cal.dateComponents([.weekday, .hour, .minute], from: reminder.date)
            return UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .monthly:
            let comps = cal.dateComponents([.day, .hour, .minute], from: reminder.date)
            return UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .yearly:
            let comps = cal.dateComponents([.month, .day, .hour, .minute], from: reminder.date)
            return UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        }
    }

    func cancel(_ id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Re-sync every enabled reminder (used after a bulk change).
    func resync(_ reminders: [Reminder]) {
        cancelAll()
        for r in reminders where r.enabled { schedule(r) }
    }
}
