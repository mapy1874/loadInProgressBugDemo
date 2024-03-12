import Apollo
import ApolloPagination
import RocketReserverAPI
import SwiftUI

extension LaunchListQuery.Data.Launches.Launch: Identifiable {}

@Observable
final class LaunchListViewModel: ObservableObject {
    public enum Constants {
        static let pageSize = 15
    }

    var showTailSpinner = false
    var canLoadNext: Bool { pager.canLoadNext }
    var launches: [LaunchListQuery.Data.Launches.Launch] = []
    var error: Error?
    var showError: Bool {
        get { error != nil }
        set { error = nil }
    }

    private var pager: GraphQLQueryPager<[LaunchListQuery.Data.Launches.Launch]>

    init(client: ApolloClientProtocol) {
        let initialQuery = LaunchListQuery(pageSize: .some(Constants.pageSize), cursor: .none)
        pager = GraphQLQueryPager(
            client: client,
            initialQuery: initialQuery,
            extractPageInfo: { data in
                CursorBasedPagination.Forward(hasNext: data.launches.hasMore, endCursor: data.launches.cursor)
            },
            pageResolver: { page, _ in
                LaunchListQuery(pageSize: .some(Constants.pageSize), cursor: page.endCursor ?? .none)
            },
            transform: { data in
                data.launches.launches.compactMap { $0 }
            }
        )
        pager.subscribe { result in

            switch result {
            case let .success((launches, _)):
                self.launches = launches
            case let .failure(error):
                // These are network errors, and worth showing to the user.
                self.error = error
            }
        }

        fetch()
    }

    func refresh() {
        pager.refetch()
    }

    func fetch() {
        pager.fetch()
    }

    func loadNextPage() {
        guard canLoadNext, !showTailSpinner else {
            return
        }
        showTailSpinner = true
        pager.loadNext { error in
            self.showTailSpinner = false
            // This is a usage error
            if let error {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
