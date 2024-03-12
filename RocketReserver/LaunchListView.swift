import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchListViewModel(client: Network.shared.apollo)

    var body: some View {
        NavigationView {
            List(viewModel.launches) { launch in
                LaunchRow(launch: launch)
                    .task {
                        let triggerIndex = viewModel.launches.endIndex - LaunchListViewModel.Constants.pageSize
                        guard launch.id == viewModel.launches[triggerIndex > .zero ? triggerIndex : .zero].id else {
                            return
                        }
                        viewModel.loadNextPage()
                    }
                    .listRowSeparator(.automatic)
                if launch.id == viewModel.launches.last?.id, viewModel.showTailSpinner {
                    HStack {
                        Spacer()
                        ProgressView("Loading")
                            .progressViewStyle(.circular)
                        Spacer()
                    }.listRowSeparator(.hidden)
                }
            }
            .refreshable {
                viewModel.fetch()
            }
            .alert(viewModel.error?.localizedDescription ?? "", isPresented: $viewModel.showError, actions: {})
            .navigationTitle("Rocket Launches")
        }
    }
}

#Preview {
    LaunchListView()
}
