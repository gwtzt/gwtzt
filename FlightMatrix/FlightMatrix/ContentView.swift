import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FlightSearchViewModel()
    @State private var selectedTab = 0
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Search Tab
            NavigationStack {
                SearchConfigView(viewModel: viewModel)
                    .navigationTitle("Flugsuche")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showSettings = true
                            } label: {
                                Label("Einstellungen", systemImage: "gearshape")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task {
                                    await viewModel.searchFlights()
                                    if !viewModel.matrixResults.isEmpty {
                                        selectedTab = 1
                                    }
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                } else {
                                    Label("Suchen", systemImage: "magnifyingglass")
                                }
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
            }
            .tabItem { Label("Suche", systemImage: "magnifyingglass") }
            .tag(0)

            // MARK: Matrix Tab
            NavigationStack {
                PriceMatrixView(viewModel: viewModel)
                    .navigationTitle("Preismatrix")
                    .toolbar {
                        if viewModel.hasSearched && !viewModel.isLoading {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Neu suchen") { selectedTab = 0 }
                            }
                        }
                    }
                    .overlay {
                        if viewModel.isLoading {
                            ZStack {
                                Color.black.opacity(0.25).ignoresSafeArea()
                                VStack(spacing: 14) {
                                    ProgressView().scaleEffect(1.4)
                                    Text(viewModel.loadingMessage)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(24)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 32)
                            }
                        }
                    }
            }
            .tabItem { Label("Matrix", systemImage: "tablecells") }
            .tag(1)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Hinweis", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
}
