import Foundation

// MARK: - Serpapi Response Models

struct SerpAPIResponse: Codable {
    let bestFlights: [SerpFlightOption]?
    let otherFlights: [SerpFlightOption]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case bestFlights = "best_flights"
        case otherFlights = "other_flights"
        case error
    }
}

struct SerpFlightOption: Codable {
    let flights: [SerpFlightSegment]
    let totalDuration: Int
    let price: Int

    enum CodingKeys: String, CodingKey {
        case flights
        case totalDuration = "total_duration"
        case price
    }
}

struct SerpFlightSegment: Codable {
    let airline: String
    let duration: Int

    enum CodingKeys: String, CodingKey {
        case airline
        case duration
    }
}

// MARK: - CabinClass mapping

extension FlightSearch.CabinClass {
    var serpAPIValue: String {
        switch self {
        case .economy:        return "1"
        case .premiumEconomy: return "2"
        case .business:       return "3"
        case .first:          return "4"
        }
    }
}

// MARK: - Service

class SerpAPIFlightService: FlightPriceServiceProtocol {
    private let apiKey: String
    private let session: URLSession

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchPrices(
        origins: [Airport],
        destinations: [Airport],
        outboundDates: [Date],
        returnDates: [Date],
        passengers: Int,
        cabinClass: FlightSearch.CabinClass
    ) async throws -> [FlightPrice] {

        // Build all (origin, destination, outbound, return) combinations
        typealias Combo = (Airport, Airport, Date, Date)
        var combos: [Combo] = []
        for origin in origins {
            for destination in destinations {
                for outbound in outboundDates {
                    for ret in returnDates where ret > outbound {
                        combos.append((origin, destination, outbound, ret))
                    }
                }
            }
        }

        // Process in batches of 4 concurrent requests
        var allPrices: [FlightPrice] = []
        let batchSize = 4

        for batchStart in stride(from: 0, to: combos.count, by: batchSize) {
            let slice = combos[batchStart..<min(batchStart + batchSize, combos.count)]
            let batchPrices = try await withThrowingTaskGroup(of: FlightPrice?.self) { group in
                for (origin, destination, outbound, ret) in slice {
                    group.addTask {
                        try await self.fetchSingle(
                            origin: origin,
                            destination: destination,
                            outboundDate: outbound,
                            returnDate: ret,
                            passengers: passengers,
                            cabinClass: cabinClass
                        )
                    }
                }
                var results: [FlightPrice] = []
                for try await price in group {
                    if let price { results.append(price) }
                }
                return results
            }
            allPrices.append(contentsOf: batchPrices)
        }

        return allPrices
    }

    // MARK: - Single request

    private func fetchSingle(
        origin: Airport,
        destination: Airport,
        outboundDate: Date,
        returnDate: Date,
        passengers: Int,
        cabinClass: FlightSearch.CabinClass
    ) async throws -> FlightPrice? {
        var components = URLComponents(string: "https://serpapi.com/search")!
        components.queryItems = [
            URLQueryItem(name: "engine",        value: "google_flights"),
            URLQueryItem(name: "departure_id",  value: origin.iata),
            URLQueryItem(name: "arrival_id",    value: destination.iata),
            URLQueryItem(name: "outbound_date", value: Self.dateFormatter.string(from: outboundDate)),
            URLQueryItem(name: "return_date",   value: Self.dateFormatter.string(from: returnDate)),
            URLQueryItem(name: "adults",        value: String(passengers)),
            URLQueryItem(name: "travel_class",  value: cabinClass.serpAPIValue),
            URLQueryItem(name: "currency",      value: "EUR"),
            URLQueryItem(name: "hl",            value: "de"),
            URLQueryItem(name: "api_key",       value: apiKey),
        ]

        guard let url = components.url else { throw FlightPriceError.invalidResponse }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else { throw FlightPriceError.invalidResponse }

        switch http.statusCode {
        case 200: break
        case 401: throw FlightPriceError.apiError("Ungültiger API-Key – bitte in den Einstellungen prüfen.")
        case 429: throw FlightPriceError.apiError("API-Limit erreicht. Bitte später erneut versuchen.")
        default:  throw FlightPriceError.apiError("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(SerpAPIResponse.self, from: data)

        if let apiError = decoded.error {
            throw FlightPriceError.apiError(apiError)
        }

        let options = (decoded.bestFlights ?? []) + (decoded.otherFlights ?? [])
        guard let cheapest = options.min(by: { $0.price < $1.price }) else { return nil }

        return FlightPrice(
            origin: origin,
            destination: destination,
            outboundDate: outboundDate,
            returnDate: returnDate,
            price: Double(cheapest.price),
            currency: "EUR",
            airline: cheapest.flights.first?.airline ?? "Unbekannt",
            isDirectFlight: cheapest.flights.count == 1,
            durationMinutes: cheapest.totalDuration
        )
    }
}
