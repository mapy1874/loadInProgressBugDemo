import SwiftUI

@main
struct RocketReserverApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                NavigationLink {
                    LaunchListView()
                } label: { Text("Go to list") }
            }
        }
    }
}
