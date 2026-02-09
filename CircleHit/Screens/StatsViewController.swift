import UIKit

final class StatsViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let headerView = UIView()
    private var levelStats: [LevelStats] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStats()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        
        setupHeader()
        setupTableView()
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Statistics"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let totalStarsLabel = UILabel()
        totalStarsLabel.tag = 100
        totalStarsLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        totalStarsLabel.textColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
        totalStarsLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(totalStarsLabel)
        
        let completedLabel = UILabel()
        completedLabel.tag = 101
        completedLabel.font = .systemFont(ofSize: 14, weight: .medium)
        completedLabel.textColor = UIColor(white: 0.6, alpha: 1)
        completedLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(completedLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            totalStarsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            totalStarsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            completedLabel.centerYAnchor.constraint(equalTo: totalStarsLabel.centerYAnchor),
            completedLabel.leadingAnchor.constraint(equalTo: totalStarsLabel.trailingAnchor, constant: 20)
        ])
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LevelStatsCell.self, forCellReuseIdentifier: "LevelStatsCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadStats() {
        levelStats = StorageService.shared.getAllLevelStats()
        let totalStars = StorageService.shared.getTotalStars()
        let completed = StorageService.shared.getCompletedLevelsCount()
        
        if let starsLabel = headerView.viewWithTag(100) as? UILabel {
            starsLabel.text = "★ \(totalStars) Total Stars"
        }
        if let completedLabel = headerView.viewWithTag(101) as? UILabel {
            completedLabel.text = "\(completed) levels completed"
        }
        
        tableView.reloadData()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

extension StatsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(levelStats.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LevelStatsCell", for: indexPath) as! LevelStatsCell
        
        if levelStats.isEmpty {
            cell.configureEmpty()
        } else {
            cell.configure(with: levelStats[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return levelStats.isEmpty ? 120 : 90
    }
}

final class LevelStatsCell: UITableViewCell {
    
    private let containerView = UIView()
    private let levelLabel = UILabel()
    private let starsLabel = UILabel()
    private let timeLabel = UILabel()
    private let attemptsLabel = UILabel()
    private let statusIcon = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        levelLabel.font = .systemFont(ofSize: 20, weight: .bold)
        levelLabel.textColor = .white
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(levelLabel)
        
        statusIcon.font = .systemFont(ofSize: 24)
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusIcon)
        
        starsLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        starsLabel.textColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
        starsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(starsLabel)
        
        timeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = UIColor(white: 0.6, alpha: 1)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)
        
        attemptsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        attemptsLabel.textColor = UIColor(white: 0.5, alpha: 1)
        attemptsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(attemptsLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            levelLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            levelLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            statusIcon.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            statusIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            starsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            starsLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 6),
            
            timeLabel.leadingAnchor.constraint(equalTo: starsLabel.trailingAnchor, constant: 20),
            timeLabel.centerYAnchor.constraint(equalTo: starsLabel.centerYAnchor),
            
            attemptsLabel.trailingAnchor.constraint(equalTo: statusIcon.leadingAnchor, constant: -16),
            attemptsLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with stats: LevelStats) {
        levelLabel.text = "Level \(stats.level)"
        
        if stats.completed {
            let starsText = String(repeating: "★", count: stats.stars) + String(repeating: "☆", count: 3 - stats.stars)
            starsLabel.text = starsText
            statusIcon.text = "✓"
            statusIcon.textColor = UIColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1)
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 0.3).cgColor
            
            let mins = Int(stats.bestTime) / 60
            let secs = Int(stats.bestTime) % 60
            timeLabel.text = "Best: \(mins):\(String(format: "%02d", secs))"
        } else {
            starsLabel.text = "☆☆☆"
            starsLabel.textColor = UIColor(white: 0.4, alpha: 1)
            statusIcon.text = "○"
            statusIcon.textColor = UIColor(white: 0.4, alpha: 1)
            containerView.layer.borderWidth = 0
            timeLabel.text = "Not completed"
        }
        
        attemptsLabel.text = "\(stats.attempts) attempt\(stats.attempts == 1 ? "" : "s")"
    }
    
    func configureEmpty() {
        levelLabel.text = "No stats yet"
        levelLabel.textColor = UIColor(white: 0.5, alpha: 1)
        starsLabel.text = ""
        timeLabel.text = "Play some levels to see your statistics here"
        timeLabel.textColor = UIColor(white: 0.4, alpha: 1)
        attemptsLabel.text = ""
        statusIcon.text = ""
        containerView.layer.borderWidth = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        levelLabel.textColor = .white
        starsLabel.textColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
        timeLabel.textColor = UIColor(white: 0.6, alpha: 1)
    }
}
