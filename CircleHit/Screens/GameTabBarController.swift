import UIKit

final class GameTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
    }
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.5, alpha: 1)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(white: 0.5, alpha: 1)]
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
    
    private func setupViewControllers() {
        let menuVC = MainMenuViewController()
        menuVC.tabBarItem = UITabBarItem(title: "Menu", image: UIImage(systemName: "house.fill"), tag: 0)
        
        let statsVC = StatsViewController()
        statsVC.tabBarItem = UITabBarItem(title: "Stats", image: UIImage(systemName: "chart.bar.fill"), tag: 1)
        
        viewControllers = [menuVC, statsVC]
        selectedIndex = 0
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
}
