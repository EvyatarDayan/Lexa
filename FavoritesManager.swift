import Foundation
import Combine

final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published private(set) var favoriteIDs: Set<String> = []

    private let storageKey = "favoriteVocabularyIDs"

    private init() {
        loadFavorites()
    }

    func isFavorite(_ id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        saveFavorites()
    }

    func clearAll() {
        favoriteIDs.removeAll()
        saveFavorites()
    }

    func removeFavorite(_ id: String) {
        favoriteIDs.remove(id)
        saveFavorites()
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: storageKey)
    }

    private func loadFavorites() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        favoriteIDs = Set(savedIDs)
    }
}
