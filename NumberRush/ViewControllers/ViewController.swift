//
//  ViewController.swift
//  NumberRush
//
//  Created by Serdaly Muhammed on 12.03.2026.
//

import UIKit
import Combine

final class ViewController: UIViewController {
    private let viewModel: GameViewModel
    private let api: LeaderboardAPI
    private var cancellables = Set<AnyCancellable>()

    private let timeLabel = UILabel()
    private let nextLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let leaderboardButton = UIButton(type: .system)

    private let headerStack = UIStackView()
    private let buttonsStack = UIStackView()
    private let gridStack = UIStackView()

    private var gridButtons: [UIButton] = []

    init(viewModel: GameViewModel, api: LeaderboardAPI) {
        self.viewModel = viewModel
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "NumberRush"
        view.backgroundColor = .systemBackground

        configureUI()
        bindViewModel()
    }

    private func configureUI() {
        timeLabel.textAlignment = .center
        timeLabel.font = .systemFont(ofSize: 20, weight: .bold)
        timeLabel.text = "Time: 00.00"

        nextLabel.textAlignment = .center
        nextLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nextLabel.text = "Next: 1"

        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        resetButton.setTitle("Reset", for: .normal)
        resetButton.backgroundColor = .systemBlue
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        leaderboardButton.setTitle("Leaderboard", for: .normal)
        leaderboardButton.backgroundColor = .systemBlue
        leaderboardButton.setTitleColor(.white, for: .normal)
        leaderboardButton.layer.cornerRadius = 10
        leaderboardButton.addTarget(self, action: #selector(showLeaderboard), for: .touchUpInside)

        headerStack.axis = .vertical
        headerStack.spacing = 10
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(timeLabel)
        headerStack.addArrangedSubview(nextLabel)

        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 10
        buttonsStack.alignment = .center
        buttonsStack.addArrangedSubview(startButton)
        buttonsStack.addArrangedSubview(resetButton)
        buttonsStack.addArrangedSubview(leaderboardButton)
        headerStack.addArrangedSubview(buttonsStack)

        gridStack.axis = .vertical
        gridStack.spacing = 10
        gridStack.distribution = .fillEqually
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        buildGridButtons()

        view.addSubview(headerStack)
        view.addSubview(gridStack)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            headerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            gridStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gridStack.widthAnchor.constraint(equalToConstant: 300),
            gridStack.heightAnchor.constraint(equalToConstant: 300)
        ])

        navigationItem.rightBarButtonItem = nil
    }

    private func buildGridButtons() {
        gridButtons = (0..<9).map { index in
            let button = UIButton(type: .system)
            button.tag = index
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 24)
            button.layer.cornerRadius = 10
            button.addTarget(self, action: #selector(numberTapped(_:)), for: .touchUpInside)
            return button
        }

        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            let start = row * 3
            let end = start + 3
            for index in start..<end {
                rowStack.addArrangedSubview(gridButtons[index])
            }

            gridStack.addArrangedSubview(rowStack)
        }
    }

    private func bindViewModel() {
        viewModel.$timeText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.timeLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$nextText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.nextLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$numbers
            .receive(on: RunLoop.main)
            .sink { [weak self] numbers in
                self?.updateGrid(numbers: numbers)
            }
            .store(in: &cancellables)

        viewModel.$isGridEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.gridButtons.forEach { button in
                    button.isEnabled = enabled
                    button.alpha = enabled ? 1.0 : 0.5
                }
            }
            .store(in: &cancellables)

        viewModel.$winTimeText
            .receive(on: RunLoop.main)
            .sink { [weak self] timeText in
                guard let self, let timeText else { return }
                self.presentWinAlert(timeText: timeText)
                self.viewModel.clearWin()
            }
            .store(in: &cancellables)

        viewModel.$validationMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let message else { return }
                self?.presentMessage(title: "Message", message: message)
            }
            .store(in: &cancellables)
    }

    private func updateGrid(numbers: [Int]) {
        for (index, button) in gridButtons.enumerated() {
            if index < numbers.count {
                button.setTitle("\(numbers[index])", for: .normal)
            } else {
                button.setTitle("", for: .normal)
            }
            button.backgroundColor = .systemBlue
            button.isEnabled = viewModel.isGridEnabled
        }
    }

    private func presentWinAlert(timeText: String, prefill: String? = nil) {
        let alert = UIAlertController(
            title: "You win!",
            message: "Time: \(timeText)s",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Enter your name"
            textField.text = prefill
        }

        let save = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text ?? ""
            if let error = self?.viewModel.validationError(for: name) {
                self?.presentMessage(title: "Invalid Name", message: error)
                self?.presentWinAlert(timeText: timeText, prefill: name)
                return
            }
            self?.viewModel.saveWin(name: name)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(save)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

    private func presentMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func startTapped() {
        viewModel.startGame()
    }

    @objc private func resetTapped() {
        viewModel.resetGame()
    }

    @objc private func numberTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let number = Int(title) else { return }
//        viewModel.handleTap(number: number)
        if viewModel.handleTap(number: number) {
            sender.backgroundColor = .systemGreen
            sender.isEnabled = false
        }

    }

    @objc private func showLeaderboard() {
        let vm = WinListViewModel(api: api)
        let vc = WinListViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
}
