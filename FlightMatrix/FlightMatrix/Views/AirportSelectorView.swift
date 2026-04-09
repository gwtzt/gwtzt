import SwiftUI

struct AirportSelectorView: View {
    let title: String
    @Binding var selectedAirports: [Airport]
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredGerman: [Airport] {
        filter(Airport.germanAirports)
    }

    private var filteredAmerican: [Airport] {
        filter(Airport.americanAirports)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Deutschland") {
                    ForEach(filteredGerman) { airport in
                        AirportRow(airport: airport, isSelected: selectedAirports.contains(airport)) {
                            toggle(airport)
                        }
                    }
                }
                Section("USA") {
                    ForEach(filteredAmerican) { airport in
                        AirportRow(airport: airport, isSelected: selectedAirports.contains(airport)) {
                            toggle(airport)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Stadt oder IATA-Code...")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Alle entfernen") { selectedAirports.removeAll() }
                        .foregroundStyle(.red)
                        .disabled(selectedAirports.isEmpty)
                }
            }
        }
    }

    private func filter(_ airports: [Airport]) -> [Airport] {
        guard !searchText.isEmpty else { return airports }
        return airports.filter {
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.iata.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func toggle(_ airport: Airport) {
        if let index = selectedAirports.firstIndex(of: airport) {
            selectedAirports.remove(at: index)
        } else {
            selectedAirports.append(airport)
        }
    }
}

struct AirportRow: View {
    let airport: Airport
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.city)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(airport.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(airport.iata)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .buttonStyle(.plain)
    }
}
