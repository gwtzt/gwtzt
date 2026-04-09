import SwiftUI

struct PriceMatrixView: View {
    @ObservedObject var viewModel: FlightSearchViewModel

    var body: some View {
        Group {
            if !viewModel.hasSearched {
                ContentUnavailableView(
                    "Noch keine Suche",
                    systemImage: "magnifyingglass",
                    description: Text("Konfiguriere deine Suche und tippe auf das Lupen-Symbol.")
                )
            } else if viewModel.matrixResults.isEmpty {
                ContentUnavailableView(
                    "Keine Flüge gefunden",
                    systemImage: "airplane.departure",
                    description: Text("Versuche einen anderen Zeitraum oder andere Flughäfen.")
                )
            } else {
                List {
                    ForEach(viewModel.matrixResults) { result in
                        Section {
                            RouteMatrixView(result: result)
                                .listRowInsets(EdgeInsets())
                        } header: {
                            HStack {
                                Text("\(result.origin.city) (\(result.origin.iata)) → \(result.destination.city) (\(result.destination.iata))")
                                Spacer()
                                if let min = result.minPrice {
                                    Text("ab \(Int(min)) €")
                                        .foregroundStyle(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - Route Matrix

struct RouteMatrixView: View {
    let result: PriceMatrixResult

    private let cellWidth: CGFloat = 62
    private let rowHeaderWidth: CGFloat = 54
    private let rowHeight: CGFloat = 46

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM."
        return f
    }()

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                Divider()
                ForEach(result.sortedOutboundDates, id: \.self) { outbound in
                    dataRow(outbound: outbound)
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // Column headers: return dates
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Corner cell
            VStack(spacing: 0) {
                Text("Hin ↓")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text("Rück →")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(width: rowHeaderWidth, height: rowHeight)
            .background(Color(.systemGroupedBackground))

            ForEach(result.sortedReturnDates, id: \.self) { date in
                Text(Self.dateFormatter.string(from: date))
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: cellWidth, height: rowHeight)
                    .background(Color(.systemGroupedBackground))
            }
        }
    }

    // Row with outbound date header + price cells
    private func dataRow(outbound: Date) -> some View {
        HStack(spacing: 0) {
            Text(Self.dateFormatter.string(from: outbound))
                .font(.system(size: 11, weight: .medium))
                .frame(width: rowHeaderWidth, height: rowHeight)
                .background(Color(.systemGroupedBackground))

            ForEach(result.sortedReturnDates, id: \.self) { ret in
                let key = PriceMatrixResult.DatePair(outbound: outbound, returnDate: ret)
                PriceCell(
                    price: result.pricesByDate[key],
                    minPrice: result.minPrice
                )
            }
        }
    }
}

// MARK: - Price Cell

struct PriceCell: View {
    let price: FlightPrice?
    let minPrice: Double?

    private var background: Color {
        guard let price, let minPrice, minPrice > 0 else { return Color(.systemGray6) }
        let ratio = (price.price - minPrice) / minPrice
        switch ratio {
        case ..<0.1:  return Color.green.opacity(0.35)
        case ..<0.3:  return Color.yellow.opacity(0.40)
        case ..<0.6:  return Color.orange.opacity(0.25)
        default:      return Color(.systemGray6)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            if let price {
                Text("\(Int(price.price))€")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                Image(systemName: price.isDirectFlight ? "arrow.right" : "arrow.triangle.turn.up.right.circle")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            } else {
                Text("–")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .frame(width: 62, height: 46)
        .background(background)
    }
}

#Preview {
    let vm = FlightSearchViewModel()
    vm.hasSearched = true
    vm.matrixResults = [
        PriceMatrixResult(
            origin: Airport.germanAirports[0],
            destination: Airport.americanAirports[0],
            pricesByDate: {
                var d: [PriceMatrixResult.DatePair: FlightPrice] = [:]
                let cal = Calendar.current
                let today = cal.startOfDay(for: Date())
                for o in 0..<3 {
                    for r in 7..<10 {
                        let out = cal.date(byAdding: .day, value: o, to: today)!
                        let ret = cal.date(byAdding: .day, value: r, to: today)!
                        d[PriceMatrixResult.DatePair(outbound: out, returnDate: ret)] = FlightPrice(
                            origin: Airport.germanAirports[0],
                            destination: Airport.americanAirports[0],
                            outboundDate: out, returnDate: ret,
                            price: Double.random(in: 500...900),
                            currency: "EUR", airline: "Lufthansa",
                            isDirectFlight: true, durationMinutes: 540
                        )
                    }
                }
                return d
            }()
        )
    ]
    return NavigationStack {
        PriceMatrixView(viewModel: vm)
            .navigationTitle("Preismatrix")
    }
}
