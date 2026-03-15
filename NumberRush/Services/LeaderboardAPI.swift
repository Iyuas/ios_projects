//
//  LeaderBoardAPI.swift
//  NumberRush
//
//  Created by Serdaly Muhammed on 12.03.2026.
//

import Foundation
import Combine

final class LeaderboardAPI {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchWins() -> AnyPublisher<[WinRecord], Error> {
        let url = baseURL
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [WinRecord].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func createWin(name: String, timeMs: Int) -> AnyPublisher<WinRecord, Error> {
        let url = baseURL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = WinCreateRequest(name: name, timeMs: timeMs)
        request.httpBody = try? JSONEncoder().encode(body)

        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: WinRecord.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func deleteWin(id: String) -> AnyPublisher<Void, Error> {
        let url = baseURL.appendingPathComponent(id)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        return session.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
