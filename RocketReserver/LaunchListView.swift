import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchListViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text("Error: \(viewModel.errorString)")
                Button("reset the list") {
                    Task {
                        await viewModel.reset()
                    }
                }
                List {
                    ForEach(0 ..< viewModel.launches.count, id: \.self) { index in
                        LaunchRow(launch: viewModel.launches[index])
                            .task {
                                if index == viewModel.launches.count - 1, !viewModel.isLoading {
                                    await viewModel.loadMoreLaunchesIfTheyExist()
                                }
                            }
                    }

                    if !viewModel.hasMore {
                        Text("No more items!")
                    } else if viewModel.isLoading {
                        Text("Loading...")
                    } else {
                        Text("Loaded!!!!!!")
                    }
                }
                .onAppear {
                    Task {
                        await viewModel.loadMoreLaunchesIfTheyExist()
                    }
                }
            }
            .navigationTitle("Rocket Launches")
        }
    }
}

struct LaunchListView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchListView()
    }
}
