import Foundation

struct FlightSearch {
    var origins: [Airport] = []
    var destinations: [Airport] = []
    var outboundStart: Date = Calendar.current.startOfDay(for: Date())
    var outboundEnd: Date = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400 * 30))
    var returnStart: Date = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400 * 7))
    var returnEnd: Date = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400 * 37))
    var passengers: Int = 1
    var cabinClass: CabinClass = .economy

    enum CabinClass: String, CaseIterable, Identifiable {
        case economy = "Economy"
        case premiumEconomy = "Premium Economy"
        case business = "Business"
        case first = "First"

        var id: String { rawValue }
    }
}
