import UIKit

final class MainMenuViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let backgroundGradient = CAGradientLayer()
    private var floatingCircles: [UIView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupFloatingCircles()
        setupUI()
        startAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    private func setupBackground() {
        backgroundGradient.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1).cgColor,
            UIColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 1).cgColor,
            UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1).cgColor
        ]
        backgroundGradient.locations = [0, 0.5, 1]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    private func setupFloatingCircles() {
        for i in 0..<8 {
            let size = CGFloat.random(in: 40...100)
            let circle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            circle.layer.cornerRadius = size / 2
            circle.alpha = 0.15
            let colors: [UIColor] = [
                UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1),
                UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1),
                UIColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 1),
                UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 1)
            ]
            circle.backgroundColor = colors[i % colors.count]
            circle.center = CGPoint(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            )
            view.addSubview(circle)
            floatingCircles.append(circle)
        }
    }
    
    private func startAnimations() {
        for (index, circle) in floatingCircles.enumerated() {
            animateCircle(circle, delay: Double(index) * 0.3)
        }
    }
    
    private func animateCircle(_ circle: UIView, delay: Double) {
        let randomX = CGFloat.random(in: -50...50)
        let randomY = CGFloat.random(in: -80...80)
        let duration = Double.random(in: 4...7)
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            circle.center = CGPoint(
                x: circle.center.x + randomX,
                y: circle.center.y + randomY
            )
            circle.alpha = CGFloat.random(in: 0.1...0.25)
        }) { _ in
            self.animateCircle(circle, delay: 0)
        }
    }
    
    private func setupUI() {
        titleLabel.text = "CIRCLE HIT"
        titleLabel.font = UIFont.systemFont(ofSize: 48, weight: .black)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.layer.shadowColor = UIColor(red: 0.3, green: 0.7, blue: 1, alpha: 1).cgColor
        titleLabel.layer.shadowOffset = .zero
        titleLabel.layer.shadowRadius = 20
        titleLabel.layer.shadowOpacity = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Bounce & Destroy"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = UIColor(white: 1, alpha: 0.7)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        playButton.setTitle("PLAY", for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        playButton.setTitleColor(.white, for: .normal)
        playButton.backgroundColor = UIColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        playButton.layer.cornerRadius = 30
        playButton.layer.shadowColor = UIColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1).cgColor
        playButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        playButton.layer.shadowRadius = 15
        playButton.layer.shadowOpacity = 0.6
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        view.addSubview(playButton)
        
        let ballIcon = UIView()
        ballIcon.backgroundColor = UIColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        ballIcon.layer.cornerRadius = 40
        ballIcon.layer.shadowColor = UIColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1).cgColor
        ballIcon.layer.shadowOffset = .zero
        ballIcon.layer.shadowRadius = 25
        ballIcon.layer.shadowOpacity = 0.8
        ballIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ballIcon)
        
        let targetIcon = UIView()
        targetIcon.backgroundColor = UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1)
        targetIcon.layer.cornerRadius = 30
        targetIcon.layer.shadowColor = UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1).cgColor
        targetIcon.layer.shadowOffset = .zero
        targetIcon.layer.shadowRadius = 20
        targetIcon.layer.shadowOpacity = 0.7
        targetIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(targetIcon)
        
        NSLayoutConstraint.activate([
            ballIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            ballIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
            ballIcon.widthAnchor.constraint(equalToConstant: 80),
            ballIcon.heightAnchor.constraint(equalToConstant: 80),
            
            targetIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 70),
            targetIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            targetIcon.widthAnchor.constraint(equalToConstant: 60),
            targetIcon.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        animateIcons(ballIcon: ballIcon, targetIcon: targetIcon)
    }
    
    private func animateIcons(ballIcon: UIView, targetIcon: UIView) {
        UIView.animate(withDuration: 2, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            ballIcon.transform = CGAffineTransform(translationX: 0, y: -15)
        }
        UIView.animate(withDuration: 2.5, delay: 0.5, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            targetIcon.transform = CGAffineTransform(translationX: 0, y: -20)
        }
    }
    
    @objc private func playTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.playButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playButton.transform = .identity
            } completion: { _ in
                let levelSelectVC = LevelSelectViewController()
                levelSelectVC.modalPresentationStyle = .fullScreen
                levelSelectVC.modalTransitionStyle = .crossDissolve
                self.present(levelSelectVC, animated: true)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}
