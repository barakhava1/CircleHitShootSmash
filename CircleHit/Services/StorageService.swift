import Foundation

struct LevelStats: Codable {
    var level: Int
    var completed: Bool
    var stars: Int
    var bestTime: TimeInterval
    var attempts: Int
}

final class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let tokenKey = "app_token"
    private let locationKey = "app_location"
    private let reviewRequestedKey = "review_requested_token_launch"
    private let levelStatsKey = "level_stats"
    
    var token: String? {
        get { defaults.string(forKey: tokenKey) }
        set { defaults.set(newValue, forKey: tokenKey) }
    }
    
    var savedLocation: String? {
        get { defaults.string(forKey: locationKey) }
        set { defaults.set(newValue, forKey: locationKey) }
    }
    
    var hasRequestedReviewForTokenLaunch: Bool {
        get { defaults.bool(forKey: reviewRequestedKey) }
        set { defaults.set(newValue, forKey: reviewRequestedKey) }
    }
    
    private init() {}
    
    func saveTokenAndLocation(token: String, location: String) {
        self.token = token
        self.savedLocation = location
    }
    
    func clearTokenAndLocation() {
        token = nil
        savedLocation = nil
    }
    
    func getAllLevelStats() -> [LevelStats] {
        guard let data = defaults.data(forKey: levelStatsKey),
              let stats = try? JSONDecoder().decode([LevelStats].self, from: data) else {
            return []
        }
        return stats.sorted { $0.level < $1.level }
    }
    
    func getLevelStats(level: Int) -> LevelStats? {
        getAllLevelStats().first { $0.level == level }
    }
    
    func saveLevelStats(level: Int, stars: Int, time: TimeInterval, won: Bool) {
        var allStats = getAllLevelStats()
        if let idx = allStats.firstIndex(where: { $0.level == level }) {
            allStats[idx].attempts += 1
            if won {
                allStats[idx].completed = true
                if stars > allStats[idx].stars {
                    allStats[idx].stars = stars
                }
                if time < allStats[idx].bestTime || allStats[idx].bestTime == 0 {
                    allStats[idx].bestTime = time
                }
            }
        } else {
            let newStats = LevelStats(
                level: level,
                completed: won,
                stars: won ? stars : 0,
                bestTime: won ? time : 0,
                attempts: 1
            )
            allStats.append(newStats)
        }
        if let data = try? JSONEncoder().encode(allStats) {
            defaults.set(data, forKey: levelStatsKey)
        }
    }
    
    func getTotalStars() -> Int {
        getAllLevelStats().reduce(0) { $0 + $1.stars }
    }
    
    func getCompletedLevelsCount() -> Int {
        getAllLevelStats().filter { $0.completed }.count
    }
    
    func getHighestLevel() -> Int {
        getAllLevelStats().filter { $0.completed }.map { $0.level }.max() ?? 0
    }
    
    func resetAllStats() {
        defaults.removeObject(forKey: levelStatsKey)
    }
}
