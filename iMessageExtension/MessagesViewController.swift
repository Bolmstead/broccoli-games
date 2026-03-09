import Combine
import Messages
import SwiftUI

final class MessagesViewController: MSMessagesAppViewController {
    private let coordinator = MessagesCoordinator()
    private var hostingController: UIHostingController<ArcadeRootView>?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        embedRootView()
        bindPresentationBehavior()
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        coordinator.setConversation(conversation)
        coordinator.ingest(message: conversation.selectedMessage)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        coordinator.setConversation(conversation)
        coordinator.ingest(message: message)
    }

    private func bindPresentationBehavior() {
        coordinator.$envelope
            .receive(on: RunLoop.main)
            .sink { [weak self] envelope in
                guard let self else { return }
                guard envelope != nil else { return }
                if self.presentationStyle == .compact {
                    self.requestPresentationStyle(.expanded)
                }
            }
            .store(in: &cancellables)
    }

    private func embedRootView() {
        let root = ArcadeRootView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: root)

        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)

        self.hostingController = hosting
    }
}
