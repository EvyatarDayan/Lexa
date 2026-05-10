//
//  VocabularyEntry.swift
//  Lexa
//

import Foundation

struct VocabularyEntry: Identifiable, Codable, Hashable {
    var id: String {
        if let entryID {
            return "entry-\(entryID)"
        }
        return "word-\(word)"
    }

    let entryID: Int?
    let word: String
    let translation: String
    let grammarType: String
    let grammarBreakdown: [String]
    let data: [ExampleSentence]

    /// Swedish headword for UI: only the first letter is capitalized (e.g. "Då och då").
    var wordForDisplay: String {
        Self.sentenceCaseFirstOnly(word, locale: Locale(identifier: "sv_SE"))
    }

    /// English gloss for UI: only the first letter is capitalized (e.g. "Now and then").
    var translationForDisplay: String {
        Self.sentenceCaseFirstOnly(translation, locale: Locale(identifier: "en_US"))
    }

    /// Lowercases the string with `locale`, then uppercases only the first character.
    private static func sentenceCaseFirstOnly(_ string: String, locale: Locale) -> String {
        guard !string.isEmpty else { return string }
        let normalized = string.lowercased(with: locale)
        let first = normalized.prefix(1).uppercased(with: locale)
        return String(first) + normalized.dropFirst()
    }

    enum CodingKeys: String, CodingKey {
        case entryID = "id"
        case word
        case translation
        case grammarType = "grammar_type"
        case grammarBreakdown = "grammar_breakdown"
        case data
    }

    struct ExampleSentence: Codable, Hashable {
        let swedish: String
        let english: String

        enum CodingKeys: String, CodingKey {
            case swedish
            case english
        }

        init(swedish: String, english: String) {
            self.swedish = swedish
            self.english = english
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            swedish = try c.decodeIfPresent(String.self, forKey: .swedish) ?? ""
            english = try c.decodeIfPresent(String.self, forKey: .english) ?? ""
        }
    }
}
