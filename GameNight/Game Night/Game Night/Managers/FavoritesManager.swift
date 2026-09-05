import Foundation
import Combine

final class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: Set<UUID> = [] {
        didSet {
            saveFavorites()
        }
    }

    private let favoritesKey = "GameNightFavorites"

    init() {
        loadFavorites()
    }

    func toggleFavorite(eventID: UUID) {
        if favorites.contains(eventID) {
            favorites.remove(eventID)
        } else {
            favorites.insert(eventID)
        }
    }

    func isFavorite(eventID: UUID) -> Bool {
        favorites.contains(eventID)
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let saved = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return
        }
        favorites = saved
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }
}
