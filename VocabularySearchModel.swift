//
//  VocabularySearchModel.swift
//  Lexa
//

import Foundation
import Observation

@Observable
@MainActor
final class VocabularySearchModel {
    private(set) var entries: [VocabularyEntry] = []
    private(set) var loadError: String?

    var query: String = ""

    var filteredEntries: [VocabularyEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return entries
            .compactMap { entry -> (entry: VocabularyEntry, rank: Int)? in
                guard let rank = matchRank(for: entry, query: trimmed) else {
                    return nil
                }
                return (entry, rank)
            }
            .sorted { lhs, rhs in
                if lhs.rank == rhs.rank {
                    return lhs.entry.word.localizedCompare(rhs.entry.word) == .orderedAscending
                }
                return lhs.rank < rhs.rank
            }
            .map(\.entry)
    }

    init() {
        load()
    }

    func load() {
        loadError = nil

        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            loadError = "Could not find vocabulary.json in the app bundle."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode([VocabularyEntry].self, from: data)

            // Keep only the first occurrence of each exact word string.
            var seenWords = Set<String>()
            let deduplicated = decoded.filter { entry in
                seenWords.insert(entry.word).inserted
            }

            entries = deduplicated.sorted { $0.word.localizedCompare($1.word) == .orderedAscending }
        } catch {
            loadError = error.localizedDescription
            entries = []
        }
    }

    private func matchRank(for entry: VocabularyEntry, query: String) -> Int? {
        // Prefer exact spelling (including å/ä/ö) before diacritic-folded matches — e.g. query
        // "känna" must rank above "kanna", which only ties when using diacriticInsensitive.
        if entry.word.compare(query, options: [.caseInsensitive]) == .orderedSame {
            return 0
        }

        if entry.word.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
            return 1
        }

        if entry.word.range(of: query, options: [.caseInsensitive, .anchored]) != nil {
            return 2
        }

        if entry.word.range(of: query, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil {
            return 3
        }

        if entry.word.range(of: query, options: [.caseInsensitive]) != nil {
            return 4
        }

        if entry.word.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
            return 5
        }

        let matchesOtherFields =
            entry.translation.localizedCaseInsensitiveContains(query)
            || entry.grammarType.localizedCaseInsensitiveContains(query)
            || entry.grammarBreakdown.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            || entry.data.contains(where: {
                $0.swedish.localizedCaseInsensitiveContains(query)
                    || $0.english.localizedCaseInsensitiveContains(query)
            })

        return matchesOtherFields ? 6 : nil
    }
}
