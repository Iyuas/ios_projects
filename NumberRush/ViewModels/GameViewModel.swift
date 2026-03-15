//
//  GameViewModel.swift
//  NumberRush
//
//  Created by Serdaly Muhammed on 12.03.2026.
//

import Foundation
import Combine

final class GameViewModel {
    @Published private(set) var timeText: String = "Time: 00.00"
    @Published private(set) var nextText: String = "Next: 1"
    @Published private(set) var numbers: [Int] = []
    @Published private(set) var isGridEnabled: Bool = false
    @Published private(set) var winTimeText: String?
    @Published private(set) var validationMessage: String?

    private var currentTarget: Int = 1 {
        didSet { nextText = "Next: \(currentTarget)" }
    }

    private var timeMs: Int = 0 {
        didSet { timeText = "Time: \(formatTime(ms: timeMs))" }
    }

    private var startDate: Date?
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    private let api: LeaderboardAPI

    init(api: LeaderboardAPI) {
        self.api = api
        resetGame()
    }

    func startGame() {
        numbers = Array(1...9).shuffled()
        currentTarget = 1
        timeMs = 0
        isGridEnabled = true
        winTimeText = nil
        validationMessage = nil
        startTimer()
    }

    func resetGame() {
        stopTimer()
        numbers = Array(1...9)
        currentTarget = 1
        timeMs = 0
        isGridEnabled = false
        winTimeText = nil
        validationMessage = nil
    }

    func handleTap(number: Int) -> Bool {
        guard isGridEnabled, number == currentTarget else { return false }
        if number == 9 { finishGame(); return true }
        currentTarget += 1
        return true
    }


    func clearWin() {
        winTimeText = nil
    }

    func validationError(for name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Name cannot be empty." }
        if trimmed.count < 2 { return "Name must be at least 2 characters." }
        return nil
    }

    func saveWin(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        validationMessage = nil

        api.createWin(name: trimmed, timeMs: timeMs)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion { self?.validationMessage = "Save failed." }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func finishGame() {
        stopTimer()
        isGridEnabled = false
        winTimeText = formatTime(ms: timeMs)
    }

    private func startTimer() {
        stopTimer()
        startDate = Date()

        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                let elapsed = Date().timeIntervalSince(start)
                self.timeMs = max(0, Int(elapsed * 1000))
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        startDate = nil
    }

    private func formatTime(ms: Int) -> String {
        let seconds = Double(ms) / 1000.0
        return String(format: "%.2f", seconds)
    }
}
