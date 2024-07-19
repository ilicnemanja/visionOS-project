//import FirebaseFirestore
//import Combine

struct ScoreEntry: Identifiable {
    let id: String
    let email: String
    let score: Int
}

class LeaderboardService {
//    private let db = Firestore.firestore()
    // @Published var leaderboard: [ScoreEntry] = []

    func addScore(email: String, score: Int, completion: @escaping (Error?) -> Void) {
        let newScore = ["email": email, "score": score] as [String : Any]
        print("New Score: ", newScore)
//        db.collection("leaderboard").addDocument(data: newScore, completion: completion)
    }

//    func fetchLeaderboard() {
//        db.collection("leaderboard").order(by: "score", descending: true).limit(to: 10).addSnapshotListener { snapshot, error in
//            if let error = error {
//                print("Error fetching leaderboard: \(error)")
//            } else {
//                self.leaderboard = snapshot?.documents.compactMap { doc -> ScoreEntry? in
//                    let data = doc.data()
//                    let id = doc.documentID
//                    let email = data["email"] as? String ?? ""
//                    let score = data["score"] as? Int ?? 0
//                    return ScoreEntry(id: id, email: email, score: score)
//                } ?? []
//            }
//        }
//    }
}
