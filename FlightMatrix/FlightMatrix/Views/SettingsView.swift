import SwiftUI

struct SettingsView: View {
    @AppStorage("serpapi_key") private var apiKey = ""
    @State private var showKey = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField("Hier API-Key einfügen", text: $apiKey)
                            } else {
                                SecureField("Hier API-Key einfügen", text: $apiKey)
                            }
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if !apiKey.isEmpty {
                        Label("API-Key gespeichert", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                } header: {
                    Text("Serpapi API-Key")
                } footer: {
                    Text("Kostenlos registrieren auf serpapi.com · 100 Suchanfragen/Monat im Free-Plan.\nDer Key wird lokal auf dem Gerät gespeichert.")
                }

                Section("Hinweise zu API-Kosten") {
                    VStack(alignment: .leading, spacing: 8) {
                        CostHintRow(icon: "calendar.badge.exclamationmark",
                                    text: "Jede Datumskombination pro Route = 1 API-Anfrage")
                        CostHintRow(icon: "exclamationmark.triangle",
                                    text: "2 Abflüge × 2 Ziele × 7 × 7 Tage = bis zu 196 Anfragen")
                        CostHintRow(icon: "lightbulb",
                                    text: "Tipp: Wenige Flughäfen + enger Zeitraum spart Credits")
                    }
                    .padding(.vertical, 4)
                }

                if !apiKey.isEmpty {
                    Section {
                        Button("API-Key löschen", role: .destructive) {
                            apiKey = ""
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct CostHintRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
