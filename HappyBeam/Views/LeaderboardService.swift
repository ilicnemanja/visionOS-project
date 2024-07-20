import FirebaseFirestore
import Combine

struct ScoreEntry: Identifiable {
    let id: String
    let email: String
    let nickname: String
    let score: Int
}

class LeaderboardService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var leaderboard: [ScoreEntry] = []

    func addScore(email: String, nickname: String, score: Int, completion: @escaping (Error?) -> Void) {
        let newScore = ["email": email, "nickname": nickname, "score": score] as [String : Any]
        print("New Score: ", newScore)
        db.collection("leaderboard").addDocument(data: newScore, completion: completion)
    }

    func fetchLeaderboard() {
        db.collection("leaderboard").order(by: "score", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching leaderboard: \(error)")
            } else {
                self.leaderboard = snapshot?.documents.compactMap { doc -> ScoreEntry? in
                    let data = doc.data()
                    let id = doc.documentID
                    let email = data["email"] as? String ?? ""
                    let nickname = data["nickname"] as? String ?? ""
                    let score = data["score"] as? Int ?? 0
                    return ScoreEntry(id: id, email: email, nickname: nickname, score: score)
                } ?? []
            }
        }
    }
}
