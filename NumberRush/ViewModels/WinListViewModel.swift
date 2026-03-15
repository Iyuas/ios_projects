//
//  WinListViewModel.swift
//  NumberRush
//
//  Created by Serdaly Muhammed on 12.03.2026.
//

import Foundation
import Combine

final class WinListViewModel {
    @Published private(set) var wins: [WinRecord] = []
    @Published private(set) var message: String?

    private let api: LeaderboardAPI
    private var cancellables = Set<AnyCancellable>()

    init(api: LeaderboardAPI) {
        self.api = api
    }

    func load() {
        api.fetchWins()
            .map { wins in
                wins.sorted { $0.timeMs < $1.timeMs }.prefix(10).map { $0 }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion { self?.message = "Load failed." }
            }, receiveValue: { [weak self] wins in
                self?.message = nil
                self?.wins = wins
            })
            .store(in: &cancellables)
    }

    func clearAll() {
        let currentWins = wins
        guard !currentWins.isEmpty else { return }

        let deletions = currentWins.map { api.deleteWin(id: $0.id) }

        Publishers.MergeMany(deletions)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion { self?.message = "Clear failed." }
            }, receiveValue: { [weak self] _ in
                self?.message = nil
                self?.wins = []
            })
            .store(in: &cancellables)
    }

    func timeString(for win: WinRecord) -> String {
        let seconds = Double(win.timeMs) / 1000.0
        return String(format: "%.2f", seconds)
    }
}
