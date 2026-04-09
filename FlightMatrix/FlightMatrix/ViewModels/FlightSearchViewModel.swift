import Foundation
import SwiftUI

@MainActor
class FlightSearchViewModel: ObservableObject {
    @Published var search = FlightSearch()
    @Published var matrixResults: [PriceMatrixResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false

    private let service: FlightPriceServiceProtocol

    init(service: FlightPriceServiceProtocol = MockFlightPriceService()) {
        self.service = service
    }

    func searchFlights() async {
        guard !search.origins.isEmpty else {
            errorMessage = "Bitte mindestens einen Abflughafen auswählen."
            return
        }
        guard !search.destinations.isEmpty else {
            errorMessage = "Bitte mindestens einen Zielflughafen auswählen."
            return
        }
        guard search.outboundStart <= search.outboundEnd else {
            errorMessage = "Hinflug-Enddatum muss nach dem Startdatum liegen."
            return
        }
        guard search.returnStart <= search.returnEnd else {
            errorMessage = "Rückflug-Enddatum muss nach dem Startdatum liegen."
            return
        }

        isLoading = true
        errorMessage = nil

        let outboundDates = dates(from: search.outboundStart, to: search.outboundEnd, maxCount: 14)
        let returnDates = dates(from: search.returnStart, to: search.returnEnd, maxCount: 14)

        do {
            let prices = try await service.fetchPrices(
                origins: search.origins,
                destinations: search.destinations,
                outboundDates: outboundDates,
                returnDates: returnDates,
                passengers: search.passengers,
                cabinClass: search.cabinClass
            )
            matrixResults = buildMatrix(from: prices)
            hasSearched = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private

    private func dates(from start: Date, to end: Date, maxCount: Int) -> [Date] {
        var result: [Date] = []
        var current = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        while current <= endDay && result.count < maxCount {
            result.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        return result
    }

    private func buildMatrix(from prices: [FlightPrice]) -> [PriceMatrixResult] {
        // Group by origin-destination pair
        var groups: [String: [FlightPrice]] = [:]
        for price in prices {
            let key = "\(price.origin.iata)-\(price.destination.iata)"
            groups[key, default: []].append(price)
        }

        var results: [PriceMatrixResult] = []
        for (key, groupPrices) in groups {
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let origin = Airport.allAirports.first(where: { $0.iata == String(parts[0]) }),
                  let destination = Airport.allAirports.first(where: { $0.iata == String(parts[1]) })
            else { continue }

            // For each date pair, keep only the cheapest option
            var pricesByDate: [PriceMatrixResult.DatePair: FlightPrice] = [:]
            for price in groupPrices {
                let pair = PriceMatrixResult.DatePair(
                    outbound: Calendar.current.startOfDay(for: price.outboundDate),
                    returnDate: Calendar.current.startOfDay(for: price.returnDate)
                )
                if let existing = pricesByDate[pair] {
                    if price.price < existing.price { pricesByDate[pair] = price }
                } else {
                    pricesByDate[pair] = price
                }
            }

            results.append(PriceMatrixResult(
                origin: origin,
                destination: destination,
                pricesByDate: pricesByDate
            ))
        }

        return results.sorted { ($0.minPrice ?? .infinity) < ($1.minPrice ?? .infinity) }
    }
}
