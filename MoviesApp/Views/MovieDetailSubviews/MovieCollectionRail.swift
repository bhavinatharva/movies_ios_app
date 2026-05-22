import SwiftUI

struct MovieCollectionRail: View {
    let collectionName: String?
    
    var body: some View {
        if let name = collectionName, !name.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(0..<3) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 200, height: 112)
                                .cornerRadius(12)
                                .overlay(
                                    Image(systemName: "film")
                                        .foregroundColor(.white.opacity(0.3))
                                        .font(.system(size: 30))
                                )
                                .shimmer()
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}
