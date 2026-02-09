import UIKit

final class LevelSelectViewController: UIViewController {
    
    private let collectionView: UICollectionView
    private let maxLevels = 50
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        
        let titleLabel = UILabel()
        titleLabel.text = "Select Level"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        let starsLabel = UILabel()
        starsLabel.text = "★ \(StorageService.shared.getTotalStars())"
        starsLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        starsLabel.textColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
        starsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(starsLabel)
        
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LevelCell.self, forCellWithReuseIdentifier: "LevelCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            starsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            starsLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func isLevelUnlocked(_ level: Int) -> Bool {
        if level == 1 { return true }
        let highestCompleted = StorageService.shared.getHighestLevel()
        return level <= highestCompleted + 1
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

extension LevelSelectViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxLevels
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
        let level = indexPath.item + 1
        let stats = StorageService.shared.getLevelStats(level: level)
        let unlocked = isLevelUnlocked(level)
        cell.configure(level: level, stats: stats, unlocked: unlocked)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20 * 2 - 12 * 4) / 5
        return CGSize(width: width, height: width + 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = indexPath.item + 1
        guard isLevelUnlocked(level) else { return }
        let gameVC = GameViewController()
        gameVC.startingLevel = level
        gameVC.modalPresentationStyle = .fullScreen
        gameVC.modalTransitionStyle = .crossDissolve
        present(gameVC, animated: true)
    }
}

final class LevelCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let levelLabel = UILabel()
    private let starsLabel = UILabel()
    private let lockIcon = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        levelLabel.font = .systemFont(ofSize: 20, weight: .bold)
        levelLabel.textAlignment = .center
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(levelLabel)
        
        starsLabel.font = .systemFont(ofSize: 12, weight: .medium)
        starsLabel.textAlignment = .center
        starsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(starsLabel)
        
        lockIcon.text = "🔒"
        lockIcon.font = .systemFont(ofSize: 24)
        lockIcon.textAlignment = .center
        lockIcon.isHidden = true
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(lockIcon)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor),
            
            levelLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -5),
            
            lockIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            starsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            starsLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 4)
        ])
    }
    
    func configure(level: Int, stats: LevelStats?, unlocked: Bool) {
        levelLabel.text = "\(level)"
        
        if !unlocked {
            containerView.backgroundColor = UIColor(white: 0.15, alpha: 1)
            levelLabel.isHidden = true
            lockIcon.isHidden = false
            starsLabel.text = ""
        } else {
            levelLabel.isHidden = false
            lockIcon.isHidden = true
            
            if let stats = stats, stats.completed {
                containerView.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1)
                levelLabel.textColor = .white
                let stars = String(repeating: "★", count: stats.stars) + String(repeating: "☆", count: 3 - stats.stars)
                starsLabel.text = stars
                starsLabel.textColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
            } else {
                containerView.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
                levelLabel.textColor = .white
                starsLabel.text = "☆☆☆"
                starsLabel.textColor = UIColor(white: 0.4, alpha: 1)
            }
        }
    }
}
