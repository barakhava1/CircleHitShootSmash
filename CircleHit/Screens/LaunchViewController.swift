import UIKit
import StoreKit

final class LaunchViewController: UIViewController {
    
    weak var window: UIWindow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        runLaunchFlow()
    }
    
    private func runLaunchFlow() {
        let storage = StorageService.shared
        let hadTokenAtLaunch = storage.token != nil
        
        if storage.token != nil, let location = storage.savedLocation, !location.isEmpty {
            showEmbeddedBrowser(location: location, hadTokenAtLaunch: hadTokenAtLaunch)
            return
        }
        
        Task { @MainActor in
            do {
                let response = try await NetworkService.shared.fetchLaunchPayload()
                if response.hasSeparator, let token = response.token, let location = response.location, !location.isEmpty {
                    storage.saveTokenAndLocation(token: token, location: location)
                    showEmbeddedBrowser(location: location, hadTokenAtLaunch: false)
                } else {
                    showTabBar()
                }
            } catch {
                showTabBar()
            }
        }
    }
    
    private func showEmbeddedBrowser(location: String, hadTokenAtLaunch: Bool) {
        let browser = EmbeddedBrowserViewController()
        browser.loadAddress = location
        let nav = UINavigationController(rootViewController: browser)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        if hadTokenAtLaunch, !StorageService.shared.hasRequestedReviewForTokenLaunch,
           let scene = window?.windowScene {
            StorageService.shared.hasRequestedReviewForTokenLaunch = true
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func showTabBar() {
        let tabBar = GameTabBarController()
        window?.rootViewController = tabBar
        window?.makeKeyAndVisible()
    }
}
