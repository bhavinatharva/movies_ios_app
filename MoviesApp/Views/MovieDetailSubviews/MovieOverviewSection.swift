import SwiftUI

struct MovieOverviewSection: View {
    let movie: MovieDetailModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tagline = movie.tagline, !tagline.isEmpty {
                Text(tagline)
                    .font(.headline)
                    .italic()
                    .foregroundColor(.white.opacity(0.9))
            }
            
            if let overview = movie.overview, !overview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(overview)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(6)
                        .lineLimit(isExpanded ? nil : 4)
                        .animation(.easeInOut, value: isExpanded)
                    
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "Show Less" : "Read More")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text("No overview available.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
    }
}
