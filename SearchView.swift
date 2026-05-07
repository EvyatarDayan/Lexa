//
//  SearchView.swift
//  Lexa
//

import SwiftUI
import Foundation

struct SearchView: View {
    @State private var model = VocabularySearchModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
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
                        .background(Circle().fill(Color(.systemBackground)))
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
                        .background(Circle().fill(Color(.systemBackground)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text("Lexa")
                .font(.system(size: 45, weight: .regular, design: .rounded))
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
                .padding(.top, -20)

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
                        .foregroundStyle(isRecording ? .red : .secondary)
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
                VStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("Welcome to Lexa")
                        .font(.title2.weight(.semibold))
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

                    Text("Your offline dictionary with more than 8,400 Swedish words and examples.\n\nTry searching in Swedish or English to get started.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -28)
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
    var showsFavoriteButton: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var audioManager = WordAudioManager()
    @ObservedObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.word)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.blue)
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
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Text(entry.grammarType)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))

                    if showsFavoriteButton {
                        Button {
                            favoritesManager.toggleFavorite(entry.id)
                        } label: {
                            Image("star")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundStyle(favoritesManager.isFavorite(entry.id) ? .green : .secondary)
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

            Text(entry.translation)
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("Grammar", systemImage: "text.book.closed")
                    .font(.subheadline.weight(.semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(entry.grammarBreakdown, id: \.self) { item in
                            Text("• \(item)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
                        swedishHighlightTerms: swedishHighlightTerms,
                        translationHighlightTerms: translationHighlightTerms,
                        highlightedText: highlightedText
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
                        .foregroundStyle(.secondary)
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
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var showClearAllConfirmation = false
    @State private var searchText = ""
    @State private var selectedEntry: VocabularyEntry?
    @FocusState private var searchFocused: Bool

    private var favoriteEntries: [VocabularyEntry] {
        entries
            .filter { favoritesManager.isFavorite($0.id) }
            .sorted { $0.word.localizedCompare($1.word) == .orderedAscending }
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
        Group {
            if favoriteEntries.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "star",
                    description: Text("Tap the star button on a word to add it to favorites.")
                )
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search favorites...", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($searchFocused)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
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
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !favoriteEntries.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        showClearAllConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
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
}

private struct FavoriteCollapsedRow: View {
    let entry: VocabularyEntry
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var audioManager = WordAudioManager()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.word)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(entry.translation)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                audioManager.playAudio()
            }) {
                Group {
                    if audioManager.isPlaying {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 18, weight: .medium))
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
                .frame(width: 44, height: 44)
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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
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

    var body: some View {
        ScrollView {
            VocabularyResultCard(entry: entry, showsFavoriteButton: false)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SearchView()
}
