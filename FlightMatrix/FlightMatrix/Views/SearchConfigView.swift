import SwiftUI

struct SearchConfigView: View {
    @ObservedObject var viewModel: FlightSearchViewModel
    @State private var showOriginPicker = false
    @State private var showDestinationPicker = false

    var body: some View {
        Form {
            // MARK: Airports
            Section {
                airportRow(
                    label: "Von",
                    airports: viewModel.search.origins,
                    systemImage: "airplane.departure"
                ) { showOriginPicker = true }

                airportRow(
                    label: "Nach",
                    airports: viewModel.search.destinations,
                    systemImage: "airplane.arrival"
                ) { showDestinationPicker = true }
            } header: {
                Text("Flughäfen")
            }

            // MARK: Outbound dates
            Section("Hinflug-Zeitraum") {
                DatePicker(
                    "Frühester Abflug",
                    selection: $viewModel.search.outboundStart,
                    in: Date()...,
                    displayedComponents: .date
                )
                DatePicker(
                    "Spätester Abflug",
                    selection: Binding(
                        get: { viewModel.search.outboundEnd },
                        set: { newVal in
                            if newVal >= viewModel.search.outboundStart {
                                viewModel.search.outboundEnd = newVal
                            }
                        }
                    ),
                    in: viewModel.search.outboundStart...,
                    displayedComponents: .date
                )
            }

            // MARK: Return dates
            Section("Rückflug-Zeitraum") {
                DatePicker(
                    "Frühester Rückflug",
                    selection: $viewModel.search.returnStart,
                    in: viewModel.search.outboundStart...,
                    displayedComponents: .date
                )
                DatePicker(
                    "Spätester Rückflug",
                    selection: Binding(
                        get: { viewModel.search.returnEnd },
                        set: { newVal in
                            if newVal >= viewModel.search.returnStart {
                                viewModel.search.returnEnd = newVal
                            }
                        }
                    ),
                    in: viewModel.search.returnStart...,
                    displayedComponents: .date
                )
            }

            // MARK: Passengers & class
            Section("Reise-Optionen") {
                Stepper(
                    "Passagiere: \(viewModel.search.passengers)",
                    value: $viewModel.search.passengers,
                    in: 1...9
                )
                Picker("Klasse", selection: $viewModel.search.cabinClass) {
                    ForEach(FlightSearch.CabinClass.allCases) { cls in
                        Text(cls.rawValue).tag(cls)
                    }
                }
            }

            Section {
                Text("Bis zu 14 Abflug- und 14 Rückflugdaten werden in der Matrix angezeigt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showOriginPicker) {
            AirportSelectorView(title: "Abflughafen", selectedAirports: $viewModel.search.origins)
        }
        .sheet(isPresented: $showDestinationPicker) {
            AirportSelectorView(title: "Zielflughafen", selectedAirports: $viewModel.search.destinations)
        }
    }

    @ViewBuilder
    private func airportRow(label: String, airports: [Airport], systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if airports.isEmpty {
                        Text("Tippen zum Auswählen")
                            .foregroundStyle(.secondary)
                    } else {
                        AirportTagsRow(airports: airports)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

struct AirportTagsRow: View {
    let airports: [Airport]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(airports) { airport in
                    Text(airport.iata)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
