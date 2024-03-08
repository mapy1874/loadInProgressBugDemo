import Apollo
import ApolloPagination
import Combine
import RocketReserverAPI
import SwiftUI

class LaunchListViewModel: ObservableObject {
    @Published var launches: [LaunchListQuery.Data.Launches.Launch]

    @Published var isLoading: Bool = false
    @Published var hasMore: Bool = true

    @Published var errorString: String = ""

    private var cancellable: AnyCancellable?
    private let pageSize = 10
    private var pager: AsyncGraphQLQueryPager<PaginationOutput<LaunchListQuery, LaunchListQuery>>?

    init() {
        launches = []
        Task {
            await setUpPaginaiton()
        }
    }

    // MARK: - Launch Loading

    private func setUpPaginaiton() async {
        let initialQueury = LaunchListQuery(
            pageSize: .some(pageSize),
            cursor: .none
        )
        pager = await AsyncGraphQLQueryPager(
            client: Network.shared.apollo,
            initialQuery: initialQueury,
            extractPageInfo: { [weak self] data in
                guard let self else { return CursorBasedPagination.Forward(hasNext: false, endCursor: nil) }
                DispatchQueue.main.async {
                    self.hasMore = data.launches.hasMore
                }
                print("cursor: data.launches: \(data.launches.launches.compactMap { $0?.mission?.name })")
                return CursorBasedPagination.Forward(hasNext: data.launches.hasMore, endCursor: data.launches.cursor)
            },
            pageResolver: { [weak self] page, paginationDirection in
                guard let self else {
                    return nil
                }

                print("cursor: page.endCursor: \(page.endCursor)")

                switch paginationDirection {
                case .next:
                    return LaunchListQuery(pageSize: .some(self.pageSize), cursor: page.endCursor ?? .none)
                case .previous:
                    return nil
                }
            }
        )

        cancellable = pager?.receive(on: DispatchQueue.main).sink { result in
            switch result {
            case let .success(data):
                let (output, source) = data
                let initial = output.initialPage.launches.launches.compactMap { $0 }
                let next = output.nextPages.map { page in
                    page.launches.launches.compactMap { $0 }
                }.flatMap { $0 }

                print("data source is: \(source)")
                self.launches = initial + next

            case let .failure(error):
                print("skipping error: \(error)")
            }
        }
    }

    func reset() async {
        await MainActor.run {
            launches = []
            isLoading = false
            hasMore = true
        }
        await loadMoreLaunchesIfTheyExist()
    }

    func loadMoreLaunchesIfTheyExist() async {
        guard !isLoading, hasMore else {
            return
        }
        await MainActor.run {
            isLoading = true
        }

        if launches.isEmpty {
            await pager?.fetch()
        } else {
            do {
                try await pager?.loadNext()
            } catch {
                await MainActor.run {
                    errorString = error.localizedDescription
                }
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }

    deinit {
        cancellable = nil
    }
}
