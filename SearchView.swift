//
//  SearchView.swift
//  Lexa
//

import SwiftUI
import Foundation

/// Slightly darker than `.secondary` for supporting copy on `systemGroupedBackground` (better contrast).
private enum SearchSupportingText {
    static let body: Color = Color.primary.opacity(0.86)
    static let caption: Color = Color.primary.opacity(0.72)
    static let chrome: Color = Color.primary.opacity(0.62)
}

struct SearchView: View {
    @State private var model = VocabularySearchModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @FocusState private var searchFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var wordOfTheDayEntry: VocabularyEntry?
    @State private var showFavoriteAddedPopup = false
    @State private var popupDontShowAgain = false
    @State private var navigateToFavorites = false
    @AppStorage("hideFavoriteAddedPopup") private var hideFavoriteAddedPopup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                googleStyleSearchHeader
                Divider().opacity(colorScheme == .dark ? 0.42 : 0.5)
                resultsSection
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .background(
                NavigationLink(isActive: $navigateToFavorites) {
                    FavoritesView(entries: model.entries)
                } label: {
                    EmptyView()
                }
                .hidden()
            )
            .onAppear { refreshWordOfTheDay() }
            .onChange(of: model.entries.count) { _, _ in
                refreshWordOfTheDay()
            }
            .overlay {
                if showFavoriteAddedPopup {
                    FavoriteAddedPopup(
                        dontShowAgain: $popupDontShowAgain,
                        onFavorites: {
                            if popupDontShowAgain {
                                hideFavoriteAddedPopup = true
                            }
                            showFavoriteAddedPopup = false
                            navigateToFavorites = true
                        },
                        onOK: {
                            if popupDontShowAgain {
                                hideFavoriteAddedPopup = true
                            }
                            showFavoriteAddedPopup = false
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        searchFocused = false
                    } label: {
                        Label("Collapse", systemImage: "keyboard.chevron.compact.down")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }

    private var googleStyleSearchHeader: some View {
        VStack(spacing: 20) {
            HStack {
                NavigationLink {
                    FavoritesView(entries: model.entries)
                } label: {
                    Image("stars")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.primary)
                        .frame(width: 20, height: 20)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                NavigationLink {
                    SettingsView()
                } label: {
                    Image("sett")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.primary)
                        .frame(width: 20, height: 20)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text("Lexa")
                .font(.system(size: 45, weight: .regular, design: .rounded))
                .foregroundStyle(LexaBrand.wordmarkGradient)
                .padding(.top, -20)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(SearchSupportingText.chrome)
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
                            .foregroundStyle(SearchSupportingText.chrome)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if isRecording {
                        speechRecognizer.stopRecording()
                        isRecording = false
                    } else {
                        speechRecognizer.startRecording(language: "sv-SE") { text in
                            model.query = text
                        }
                        isRecording = true
                    }
                } label: {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isRecording ? .red : SearchSupportingText.chrome)
                }
                .buttonStyle(.plain)
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
        .onAppear {
            speechRecognizer.setOnRecordingStopped {
                isRecording = false
            }
        }
        .onDisappear {
            if isRecording {
                speechRecognizer.stopRecording()
                isRecording = false
            }
        }
    }

    private func refreshWordOfTheDay() {
        wordOfTheDayEntry = WordOfTheDayStore.resolvedEntry(from: model.entries)
    }

    private var wordOfTheDayHeaderTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_GB")
        return "🔥 Word of the day - \(formatter.string(from: Date()))"
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
                ScrollView {
                    VStack(spacing: 24) {
                        if let wod = wordOfTheDayEntry {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(wordOfTheDayHeaderTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SearchSupportingText.caption)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                WordOfTheDayCard(entry: wod) {
                                    model.query = wod.word
                                    searchFocused = false
                                }
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 30)
                        }

                        VStack(spacing: 12) {
                            Text("Welcome to Lexa")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(LexaBrand.wordmarkGradient)
                            
                            Text("Learn Swedish faster 🇸🇪 \nExplore thousands of Swedish words with translations, grammar explanations, pronunciation, and real-life examples, fully available offline.")
                                .font(.body)
                                .foregroundStyle(SearchSupportingText.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: model.query)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(results) { entry in
                            VocabularyResultCard(entry: entry) {
                                guard !hideFavoriteAddedPopup else { return }
                                popupDontShowAgain = false
                                showFavoriteAddedPopup = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }
}

private struct FavoriteAddedPopup: View {
    @Binding var dontShowAgain: Bool
    var onFavorites: () -> Void
    var onOK: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Word added to favorites")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button {
                    dontShowAgain.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                            .foregroundStyle(dontShowAgain ? .blue : .secondary)
                        Text("Don't show this again")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button("Favorites") {
                        onFavorites()
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )

                    Button("OK") {
                        onOK()
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )
                }
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

private struct WordOfTheDayCard: View {
    let entry: VocabularyEntry
    var onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var audioManager = WordAudioManager()
    private var firstExampleSentence: VocabularyEntry.ExampleSentence? {
        guard let first = entry.data.first else { return nil }
        let swedish = first.swedish.trimmingCharacters(in: .whitespacesAndNewlines)
        let english = first.english.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !swedish.isEmpty else { return nil }
        return .init(swedish: swedish, english: english)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Headword row: flag + lemma (tappable) + pronunciation, same rhythm as result cards.
            HStack(alignment: .center, spacing: 10) {
                Text("🇸🇪")
                    .font(.body)

                Text(entry.wordForDisplay)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.blue)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    audioManager.playAudio()
                }) {
                    Group {
                        if audioManager.isPlaying {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                        } else {
                            Image("audio-headphone")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 17, height: 17)
                                .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )
                }
                .buttonStyle(.plain)
                .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("🇬🇧")
                    .font(.body)
                Text(entry.translationForDisplay)
                    .font(.body)
                    .foregroundStyle(SearchSupportingText.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 8)

            if firstExampleSentence != nil {
                Divider()
                    .opacity(colorScheme == .dark ? 0.35 : 0.55)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            if let firstExampleSentence {
                ExampleSentenceRow(
                    sentence: firstExampleSentence,
                    swedishHighlightTerms: EntryExampleHighlighting.swedishHighlightTerms(for: entry),
                    translationHighlightTerms: EntryExampleHighlighting.translationHighlightTerms(for: entry),
                    highlightedText: EntryExampleHighlighting.highlightedText
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.15, green: 0.15, blue: 0.17)
                        : Color(.systemBackground)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            onSelect()
        }
        .onAppear {
            audioManager.generateAudio(for: entry.word)
        }
        .onChange(of: entry.word) { _, newWord in
            audioManager.generateAudio(for: newWord)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

/// Shared example-sentence highlighting (Swedish lemma / verb stems + English gloss tokens).
private enum EntryExampleHighlighting {
    static func translationHighlightTerms(for entry: VocabularyEntry) -> [String] {
        let tokenizedTerms = entry.translation
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 3 }

        return [entry.translation] + tokenizedTerms
    }

    static func swedishHighlightTerms(for entry: VocabularyEntry) -> [String] {
        var terms = Set<String>()
        terms.insert(entry.word)

        for item in entry.grammarBreakdown {
            let leftSide = item.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? item
            for token in tokenizeWords(in: leftSide) where token.count >= 3 {
                terms.insert(token)
            }
        }

        if entry.grammarType.localizedCaseInsensitiveContains("verb") {
            let lowered = entry.word.lowercased()
            if lowered.count > 2, lowered.hasSuffix("a") {
                let stem = String(lowered.dropLast())
                terms.insert(stem)
                terms.insert("\(stem)r")
                terms.insert("\(stem)er")
                terms.insert("\(stem)de")
                terms.insert("\(stem)te")
                terms.insert("\(stem)t")
            }
        }

        return Array(terms)
    }

    static func tokenizeWords(in text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.letters.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func highlightedText(_ text: String, terms: [String]) -> Text {
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

private struct VocabularyResultCard: View {
    let entry: VocabularyEntry
    var showsFavoriteButton: Bool = true
    var onFavoriteAdded: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var audioManager = WordAudioManager()
    @ObservedObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("🇸🇪")
                        .font(.body)
                    Text(entry.wordForDisplay)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    audioManager.playAudio()
                }) {
                    Group {
                        if audioManager.isPlaying {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                        } else {
                            Image("audio-headphone")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 17, height: 17)
                                .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                        }
                    }
                    .frame(width: 25, height: 25)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemFill))
                    )
                }
                .buttonStyle(.plain)
                .disabled(audioManager.isPlaying || !audioManager.isAudioReady)

                HStack(spacing: 6) {
                    Text(entry.grammarTypeForDisplay)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .frame(height: 25)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                        )

                    if showsFavoriteButton {
                        Button {
                            let wasFavorite = favoritesManager.isFavorite(entry.id)
                            favoritesManager.toggleFavorite(entry.id)
                            if !wasFavorite {
                                onFavoriteAdded?()
                            }
                        } label: {
                            Image("favorite")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundStyle(favoritesManager.isFavorite(entry.id) ? .green : SearchSupportingText.chrome)
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color(.tertiarySystemFill))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("🇬🇧")
                    .font(.body)
                Text(entry.translationForDisplay)
                    .font(.body)
                    .foregroundStyle(SearchSupportingText.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("Grammar", systemImage: "text.book.closed")
                    .font(.subheadline.weight(.semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(entry.grammarBreakdown, id: \.self) { item in
                            Text("• \(item)")
                                .font(.subheadline)
                                .foregroundStyle(SearchSupportingText.body)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(detailBackgroundColor)
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Examples", systemImage: "quote.opening")
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(entry.data.enumerated()), id: \.offset) { _, sentence in
                    ExampleSentenceRow(
                        sentence: sentence,
                        swedishHighlightTerms: EntryExampleHighlighting.swedishHighlightTerms(for: entry),
                        translationHighlightTerms: EntryExampleHighlighting.translationHighlightTerms(for: entry),
                        highlightedText: EntryExampleHighlighting.highlightedText
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
        .onAppear {
            audioManager.generateAudio(for: entry.word)
        }
        .onChange(of: entry.word) { _, newWord in
            audioManager.generateAudio(for: newWord)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }

    private var detailBackgroundColor: Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemGray6)
    }
}

private struct ExampleSentenceRow: View {
    let sentence: VocabularyEntry.ExampleSentence
    let swedishHighlightTerms: [String]
    let translationHighlightTerms: [String]
    let highlightedText: (String, [String]) -> Text
    @StateObject private var audioManager = WordAudioManager()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    highlightedText(sentence.swedish, swedishHighlightTerms)
                        .font(.body)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    highlightedText(sentence.english, translationHighlightTerms)
                        .font(.subheadline)
                        .foregroundStyle(SearchSupportingText.body)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            Button(action: {
                audioManager.playAudio()
            }) {
                Group {
                    if audioManager.isPlaying {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                    } else {
                        Image("audio-headphone")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                    }
                }
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                )
            }
            .buttonStyle(.plain)
            .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemGray6))
        )
        .onAppear {
            audioManager.generateAudio(for: sentence.swedish)
        }
        .onChange(of: sentence.swedish) { _, newValue in
            audioManager.generateAudio(for: newValue)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

private struct FavoritesView: View {
    let entries: [VocabularyEntry]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var showClearAllConfirmation = false
    @State private var searchText = ""
    @State private var selectedEntry: VocabularyEntry?
    @FocusState private var searchFocused: Bool

    private var favoriteEntries: [VocabularyEntry] {
        let favorites = entries.filter { favoritesManager.isFavorite($0.id) }
        switch favoritesManager.sortOption {
        case .alphabetical:
            return favorites.sorted { $0.word.localizedCompare($1.word) == .orderedAscending }
        case .recent:
            let byID = Dictionary(uniqueKeysWithValues: favorites.map { ($0.id, $0) })
            let orderedRecent = favoritesManager.favoriteOrder.reversed().compactMap { byID[$0] }
            let orderedRecentIDs = Set(orderedRecent.map(\.id))
            let untracked = favorites
                .filter { !orderedRecentIDs.contains($0.id) }
                .sorted { $0.word.localizedCompare($1.word) == .orderedAscending }
            return orderedRecent + untracked
        }
    }

    private var filteredFavoriteEntries: [VocabularyEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return favoriteEntries }
        return favoriteEntries.filter {
            $0.word.localizedCaseInsensitiveContains(trimmed)
                || $0.translation.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            favoritesTopBar

            Group {
                if favoriteEntries.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "star",
                        description: Text("Tap the star button on a word to add it to favorites.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(SearchSupportingText.chrome)

                            TextField("Search favorites...", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($searchFocused)

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(SearchSupportingText.chrome)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )

                        Menu {
                            Button("A-B") {
                                favoritesManager.sortOption = .alphabetical
                            }
                            Button("Recent") {
                                favoritesManager.sortOption = .recent
                            }
                        } label: {
                            Image("sort")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 23, height: 23)
                                .foregroundStyle(.primary)
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    if filteredFavoriteEntries.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredFavoriteEntries) { entry in
                                Button {
                                    selectedEntry = entry
                                } label: {
                                    FavoriteCollapsedRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        favoritesManager.removeFavorite(entry.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert("Are you sure? this cannot be undone.", isPresented: $showClearAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Yes", role: .destructive) {
                favoritesManager.clearAll()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationDestination(item: $selectedEntry) { entry in
            FavoriteWordDetailView(entry: entry)
        }
    }

    private var favoritesTopBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Favorites")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Group {
                if !favoriteEntries.isEmpty {
                    Button {
                        showClearAllConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .frame(width: 20, height: 20)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct FavoriteCollapsedRow: View {
    let entry: VocabularyEntry
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var audioManager = WordAudioManager()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("🇸🇪")
                        .font(.body)
                    Text(entry.wordForDisplay)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("🇬🇧")
                        .font(.body)
                    Text(entry.translationForDisplay)
                        .font(.subheadline)
                        .foregroundStyle(SearchSupportingText.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                audioManager.playAudio()
            }) {
                Group {
                    if audioManager.isPlaying {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                    } else {
                        Image("audio-headphone")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                    }
                }
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
            }
            .buttonStyle(.plain)
            .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.15, green: 0.15, blue: 0.17)
                        : Color(.systemBackground)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .onAppear {
            audioManager.generateAudio(for: entry.word)
        }
        .onChange(of: entry.word) { _, newWord in
            audioManager.generateAudio(for: newWord)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

private struct FavoriteWordDetailView: View {
    let entry: VocabularyEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(entry.wordForDisplay)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Color.clear
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)

            ScrollView {
                VocabularyResultCard(entry: entry, showsFavoriteButton: false)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SearchView()
}
