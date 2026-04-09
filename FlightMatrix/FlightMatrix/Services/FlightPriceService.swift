import Foundation

enum FlightPriceError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let err): return "Netzwerkfehler: \(err.localizedDescription)"
        case .invalidResponse: return "Ungültige Serverantwort"
        case .apiError(let msg): return "API-Fehler: \(msg)"
        }
    }
}

protocol FlightPriceServiceProtocol {
    func fetchPrices(
        origins: [Airport],
        destinations: [Airport],
        outboundDates: [Date],
        returnDates: [Date],
        passengers: Int,
        cabinClass: FlightSearch.CabinClass
    ) async throws -> [FlightPrice]
}

// MARK: - Mock Service (Development)

class MockFlightPriceService: FlightPriceServiceProtocol {
    func fetchPrices(
        origins: [Airport],
        destinations: [Airport],
        outboundDates: [Date],
        returnDates: [Date],
        passengers: Int,
        cabinClass: FlightSearch.CabinClass
    ) async throws -> [FlightPrice] {
        try await Task.sleep(nanoseconds: 1_200_000_000)

        let airlines = ["Lufthansa", "United", "American Airlines", "Delta", "Condor", "Norse Atlantic"]
        var prices: [FlightPrice] = []
        var rng = SystemRandomNumberGenerator()

        for origin in origins {
            for destination in destinations {
                let routeBase = Double.random(in: 380...1600, using: &rng)
                for outbound in outboundDates {
                    for returnDate in returnDates where returnDate > outbound {
                        let dayVariance = Double.random(in: 0.85...1.35, using: &rng)
                        let cabinMultiplier: Double
                        switch cabinClass {
                        case .economy:        cabinMultiplier = 1.0
                        case .premiumEconomy: cabinMultiplier = 1.7
                        case .business:       cabinMultiplier = 3.8
                        case .first:          cabinMultiplier = 7.5
                        }

                        let price = FlightPrice(
                            origin: origin,
                            destination: destination,
                            outboundDate: outbound,
                            returnDate: returnDate,
                            price: (routeBase * dayVariance * cabinMultiplier * Double(passengers)).rounded(),
                            currency: "EUR",
                            airline: airlines.randomElement()!,
                            isDirectFlight: Double.random(in: 0...1, using: &rng) > 0.4,
                            durationMinutes: Int.random(in: 450...720, using: &rng)
                        )
                        prices.append(price)
                    }
                }
            }
        }
        return prices
    }
}

// MARK: - Amadeus API Service (Production)
// To activate: replace MockFlightPriceService with AmadeusFlightPriceService
// and provide API credentials from https://developers.amadeus.com

/*
class AmadeusFlightPriceService: FlightPriceServiceProtocol {
    private let clientId: String
    private let clientSecret: String
    private var accessToken: String?

    init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    func fetchPrices(...) async throws -> [FlightPrice] {
        // 1. Authenticate: POST /v1/security/oauth2/token
        // 2. For each origin/destination pair and date: GET /v2/shopping/flight-offers
        // 3. Parse and return FlightPrice objects
        fatalError("Not yet implemented")
    }
}
*/
