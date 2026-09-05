import Foundation
import CoreLocation

enum GameType: String, CaseIterable, Identifiable, Codable {
    case trivia = "Trivia"
    case musicBingo = "Music Bingo"
    case karaoke = "Karaoke"
    case themedNights = "Themed Nights"

    var id: String { rawValue }
}

struct Event: Identifiable, Codable {
    let id: UUID
    let name: String
    let venueName: String
    let latitude: Double
    let longitude: Double
    let gameType: GameType
    let startDate: Date
    let lastVerified: Date
    let url: URL?
    let sourceUrl: URL?
    let address: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(from location: CLLocation?) -> CLLocationDistance? {
        guard let location = location else { return nil }
        let eventLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: eventLocation)
    }

    func isWithin(radiusMiles: Double, from location: CLLocation?) -> Bool {
        guard let meters = distance(from: location) else { return true }
        return meters <= radiusMiles * 1609.34
    }
}
