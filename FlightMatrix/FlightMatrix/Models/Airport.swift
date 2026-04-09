import Foundation

struct Airport: Identifiable, Hashable, Codable {
    let iata: String
    let name: String
    let city: String
    let country: String

    var id: String { iata }

    static let germanAirports: [Airport] = [
        Airport(iata: "FRA", name: "Frankfurt am Main", city: "Frankfurt", country: "Deutschland"),
        Airport(iata: "MUC", name: "Franz Josef Strauß", city: "München", country: "Deutschland"),
        Airport(iata: "BER", name: "Brandenburg", city: "Berlin", country: "Deutschland"),
        Airport(iata: "DUS", name: "Düsseldorf", city: "Düsseldorf", country: "Deutschland"),
        Airport(iata: "HAM", name: "Hamburg", city: "Hamburg", country: "Deutschland"),
        Airport(iata: "STR", name: "Stuttgart", city: "Stuttgart", country: "Deutschland"),
        Airport(iata: "CGN", name: "Köln/Bonn", city: "Köln", country: "Deutschland"),
    ]

    static let americanAirports: [Airport] = [
        Airport(iata: "JFK", name: "John F. Kennedy Intl.", city: "New York", country: "USA"),
        Airport(iata: "EWR", name: "Newark Liberty Intl.", city: "Newark/NYC", country: "USA"),
        Airport(iata: "LAX", name: "Los Angeles Intl.", city: "Los Angeles", country: "USA"),
        Airport(iata: "ORD", name: "O'Hare International", city: "Chicago", country: "USA"),
        Airport(iata: "MIA", name: "Miami International", city: "Miami", country: "USA"),
        Airport(iata: "SFO", name: "San Francisco Intl.", city: "San Francisco", country: "USA"),
        Airport(iata: "BOS", name: "Logan International", city: "Boston", country: "USA"),
        Airport(iata: "SEA", name: "Seattle-Tacoma Intl.", city: "Seattle", country: "USA"),
        Airport(iata: "DFW", name: "Dallas/Fort Worth Intl.", city: "Dallas", country: "USA"),
        Airport(iata: "ATL", name: "Hartsfield-Jackson Intl.", city: "Atlanta", country: "USA"),
    ]

    static let allAirports: [Airport] = germanAirports + americanAirports
}
