import Apollo
import ApolloPagination
import RocketReserverAPI
import SwiftUI

private let pageSize = 10

extension LaunchListQuery.Data.Launches.Launch: Identifiable { }

@Observable final class LaunchListViewModel: ObservableObject {
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
    let initialQuery = LaunchListQuery(pageSize: .some(pageSize), cursor: .none)
    self.pager = GraphQLQueryPager(
      client: client,
      initialQuery: initialQuery,
      extractPageInfo: { data in
        CursorBasedPagination.Forward(hasNext: data.launches.hasMore, endCursor: data.launches.cursor)
      },
      pageResolver: { page, direction in
        LaunchListQuery(pageSize: .some(pageSize), cursor: page.endCursor ?? .none)
      },
      transform: { data in
        data.launches.launches.compactMap { $0 }
      }
    )
    pager.subscribe { result in
      switch result {
      case .success((let launches, _)):
        self.launches = launches
      case .failure(let error):
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
    guard canLoadNext, !showTailSpinner else { return }
    self.showTailSpinner = true
    pager.loadNext() { error in
      self.showTailSpinner = false
      // This is a usage error
      if let error {
        assertionFailure(error.localizedDescription)
      }
    }
  }
}
