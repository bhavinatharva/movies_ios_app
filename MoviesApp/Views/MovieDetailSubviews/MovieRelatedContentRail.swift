import SwiftUI

struct MovieRelatedContentRail: View {
    let title: String
    let items: [TrendingModel]
    let onSelect: (TrendingModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items, id: \.self) { item in
                        Button(action: {
                            onSelect(item)
                        }) {
                            AsyncImage(url: URL(string: Constants.ImageConstants.posterPathStart + (item.posterPath ?? ""))) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .shimmer()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 140, height: 210)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
