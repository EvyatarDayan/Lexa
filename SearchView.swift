//
//  SearchView.swift
//  Lexa
//

import SwiftUI
import Foundation

struct SearchView: View {
    @State private var model = VocabularySearchModel()
    @FocusState private var searchFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                googleStyleSearchHeader
                Divider().opacity(0.35)
                resultsSection
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var googleStyleSearchHeader: some View {
        VStack(spacing: 20) {
            HStack {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(.systemBackground)))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text("Lexa")
                .font(.system(size: 42, weight: .regular, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.52, blue: 0.96),
                            Color(red: 0.92, green: 0.25, blue: 0.21),
                            Color(red: 0.98, green: 0.75, blue: 0.18),
                            Color(red: 0.20, green: 0.66, blue: 0.33),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 8)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body.weight(.medium))

                TextField("Search Swedish or English…", text: $model.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)

                if !model.query.isEmpty {
                    Button {
                        model.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(red: 0.15, green: 0.15, blue: 0.17)
                            : Color(.systemBackground)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var resultsSection: some View {
        if let message = model.loadError {
            ContentUnavailableView(
                "Could not load dictionary",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let results = model.filteredEntries

            if model.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    "Welcome to Lexa",
                    systemImage: "book.closed.fill",
                    description: Text("Your offline dictionary with more than 8,000 Swedish words and examples.\n\nTry searching in Swedish or English to get started.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: model.query)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(results) { entry in
                            VocabularyResultCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }
}

private struct VocabularyResultCard: View {
    let entry: VocabularyEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.word)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.blue)
                    if let entryID = entry.entryID {
                        Text("#\(entryID)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Text(entry.grammarType)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(.tertiarySystemFill)))
            }

            Text(entry.translation)
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("Grammar", systemImage: "text.book.closed")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.grammarBreakdown, id: \.self) { item in
                        Text("• \(item)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Examples", systemImage: "quote.opening")
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(entry.data.enumerated()), id: \.offset) { _, sentence in
                    VStack(alignment: .leading, spacing: 2) {
                        highlightedText(sentence.swedish, terms: swedishHighlightTerms)
                            .font(.body)
                        highlightedText(sentence.english, terms: translationHighlightTerms)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.15, green: 0.15, blue: 0.17)
                        : Color(.systemBackground)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }

    private var translationHighlightTerms: [String] {
        let tokenizedTerms = entry.translation
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 3 }

        return [entry.translation] + tokenizedTerms
    }

    private var swedishHighlightTerms: [String] {
        var terms = Set<String>()
        terms.insert(entry.word)

        // Pull likely forms from grammar breakdown lines, e.g. "trycka: to press..."
        for item in entry.grammarBreakdown {
            let leftSide = item.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? item
            for token in tokenizeWords(in: leftSide) where token.count >= 3 {
                terms.insert(token)
            }
        }

        // Add common verb forms so imperative/past/supine forms are highlighted.
        if entry.grammarType.localizedCaseInsensitiveContains("verb") {
            let lowered = entry.word.lowercased()
            if lowered.count > 2, lowered.hasSuffix("a") {
                let stem = String(lowered.dropLast())
                terms.insert(stem)         // tryck
                terms.insert("\(stem)r")   // standard present for some verbs
                terms.insert("\(stem)er")  // trycker
                terms.insert("\(stem)de")  // regular past
                terms.insert("\(stem)te")  // tryckte
                terms.insert("\(stem)t")   // tryckt
            }
        }

        return Array(terms)
    }

    private func tokenizeWords(in text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.letters.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func highlightedText(_ text: String, terms: [String]) -> Text {
        let cleanTerms = terms
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanTerms.isEmpty else { return Text(text) }

        var attributed = AttributedString(text)

        for term in cleanTerms {
            var searchStart = text.startIndex

            while searchStart < text.endIndex,
                  let range = text.range(
                    of: term,
                    options: [.caseInsensitive, .diacriticInsensitive],
                    range: searchStart..<text.endIndex
                  ) {
                if let lowerBound = AttributedString.Index(range.lowerBound, within: attributed),
                   let upperBound = AttributedString.Index(range.upperBound, within: attributed) {
                    attributed[lowerBound..<upperBound].inlinePresentationIntent = .stronglyEmphasized
                }
                searchStart = range.upperBound
            }
        }

        return Text(attributed)
    }
}

#Preview {
    SearchView()
}
