import SwiftUI

struct LeaderboardTable: View {
    let scores: [(nickname: String, score: Int)]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(scores, id: \.nickname) { score in
                HStack {
                    Text(score.nickname)
                    Spacer()
                    Text("\(score.score)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}
