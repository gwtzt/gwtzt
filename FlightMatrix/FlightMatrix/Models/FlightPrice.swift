import Foundation

struct FlightPrice: Identifiable {
    let id = UUID()
    let origin: Airport
    let destination: Airport
    let outboundDate: Date
    let returnDate: Date
    let price: Double
    let currency: String
    let airline: String
    let isDirectFlight: Bool
    let durationMinutes: Int

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(Int(price))"
    }
}

struct PriceMatrixResult: Identifiable {
    let id = UUID()
    let origin: Airport
    let destination: Airport
    let pricesByDate: [DatePair: FlightPrice]

    struct DatePair: Hashable {
        let outbound: Date
        let returnDate: Date
    }

    var minPrice: Double? {
        pricesByDate.values.map(\.price).min()
    }

    var sortedOutboundDates: [Date] {
        Array(Set(pricesByDate.keys.map(\.outbound))).sorted()
    }

    var sortedReturnDates: [Date] {
        Array(Set(pricesByDate.keys.map(\.returnDate))).sorted()
    }
}
