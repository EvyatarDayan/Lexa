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
    }
}
