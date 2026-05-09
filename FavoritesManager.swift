import Foundation
import Combine

enum FavoriteSortOption: String {
    case recent = "Recent"
    case alphabetical = "A-B"
}

final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published private(set) var favoriteIDs: Set<String> = []
    @Published private(set) var favoriteOrder: [String] = []
    @Published var sortOption: FavoriteSortOption = .recent

    private let storageKey = "favoriteVocabularyIDs"
    private let orderStorageKey = "favoriteVocabularyOrder"

    private init() {
        loadFavorites()
    }

    func isFavorite(_ id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            favoriteOrder.removeAll { $0 == id }
        } else {
            favoriteIDs.insert(id)
            favoriteOrder.removeAll { $0 == id }
            favoriteOrder.append(id)
        }
        saveFavorites()
    }

    func clearAll() {
        favoriteIDs.removeAll()
        favoriteOrder.removeAll()
        saveFavorites()
    }

    func removeFavorite(_ id: String) {
        favoriteIDs.remove(id)
        favoriteOrder.removeAll { $0 == id }
        saveFavorites()
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: storageKey)
        UserDefaults.standard.set(favoriteOrder, forKey: orderStorageKey)
    }

    private func loadFavorites() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        favoriteIDs = Set(savedIDs)
        let savedOrder = UserDefaults.standard.stringArray(forKey: orderStorageKey) ?? []
        favoriteOrder = savedOrder.filter { favoriteIDs.contains($0) }

        // Backfill any IDs not already in order (older app data).
        for id in savedIDs where !favoriteOrder.contains(id) {
            favoriteOrder.append(id)
        }
    }
}
