//
//  WordOfTheDayStore.swift
//  Lexa
//

import Foundation

enum WordOfTheDayStore {
    private static let calendarDateKey = "lexa.wordOfTheDay.calendarDate"
    private static let entryIDKey = "lexa.wordOfTheDay.entryID"

    /// IDs 1…1000 only (Kelly-style “top” slice).
    private static let idRange = 1...1000

    private static var todayCalendarKey: String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day], from: Date())
        guard let y = c.year, let m = c.month, let d = c.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Returns today’s pick (stable until midnight); picks randomly from entries whose `id` is in 1…1000.
    static func resolvedEntry(from entries: [VocabularyEntry]) -> VocabularyEntry? {
        let pool = entries.filter { entry in
            guard let id = entry.entryID else { return false }
            return idRange.contains(id)
        }
        guard !pool.isEmpty else { return nil }

        let defaults = UserDefaults.standard
        let today = todayCalendarKey

        if let storedDate = defaults.string(forKey: calendarDateKey),
           storedDate == today,
           let storedID = defaults.object(forKey: entryIDKey) as? Int,
           let match = pool.first(where: { $0.entryID == storedID }) {
            return match
        }

        guard let picked = pool.randomElement(),
              let pickedID = picked.entryID else { return nil }

        defaults.set(today, forKey: calendarDateKey)
        defaults.set(pickedID, forKey: entryIDKey)
        return picked
    }
}
