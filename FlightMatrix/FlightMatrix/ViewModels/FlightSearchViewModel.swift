import Foundation
import SwiftUI

@MainActor
class FlightSearchViewModel: ObservableObject {
    @Published var search = FlightSearch()
    @Published var matrixResults: [PriceMatrixResult] = []
    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var errorMessage: String?
    @Published var hasSearched = false

    // Estimated number of Serpapi calls for the current search config
    var estimatedCallCount: Int {
        let outboundDays = min(daysBetween(search.outboundStart, search.outboundEnd) + 1, 14)
        let returnDays   = min(daysBetween(search.returnStart,   search.returnEnd)   + 1, 14)
        return search.origins.count * search.destinations.count * outboundDays * returnDays
    }

    var isUsingLiveData: Bool {
        !storedAPIKey.isEmpty
    }

    @AppStorage("serpapi_key") private var storedAPIKey = ""

    func searchFlights() async {
        guard !search.origins.isEmpty else {
            errorMessage = "Bitte mindestens einen Abflughafen auswählen."
            return
        }
        guard !search.destinations.isEmpty else {
            errorMessage = "Bitte mindestens einen Zielflughafen auswählen."
            return
        }

        isLoading = true
        errorMessage = nil

        let outboundDates = dates(from: search.outboundStart, to: search.outboundEnd, maxCount: 14)
        let returnDates   = dates(from: search.returnStart,   to: search.returnEnd,   maxCount: 14)

        let service: FlightPriceServiceProtocol = storedAPIKey.isEmpty
            ? MockFlightPriceService()
            : SerpAPIFlightService(apiKey: storedAPIKey)

        let totalCalls = search.origins.count * search.destinations.count
            * outboundDates.count * returnDates.count
        loadingMessage = isUsingLiveData
            ? "Lade \(totalCalls) Preiskombinationen via Serpapi…"
            : "Generiere Beispieldaten…"

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

    private func daysBetween(_ a: Date, _ b: Date) -> Int {
        Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
    }

    private func dates(from start: Date, to end: Date, maxCount: Int) -> [Date] {
        var result: [Date] = []
        var current = Calendar.current.startOfDay(for: start)
        let endDay  = Calendar.current.startOfDay(for: end)
        while current <= endDay && result.count < maxCount {
            result.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        return result
    }

    private func buildMatrix(from prices: [FlightPrice]) -> [PriceMatrixResult] {
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

            var pricesByDate: [PriceMatrixResult.DatePair: FlightPrice] = [:]
            for price in groupPrices {
                let pair = PriceMatrixResult.DatePair(
                    outbound:   Calendar.current.startOfDay(for: price.outboundDate),
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
