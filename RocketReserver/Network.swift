//
//  Network.swift
//  RocketReserver
//
//  Created by Patrick Ma on 3/6/24.
//

import Apollo
import Foundation

class Network {
    static let shared = Network()

    private(set) lazy var apollo =
        ApolloClient(url: URL(string: "https://apollo-fullstack-tutorial.herokuapp.com/graphql")!)
}
