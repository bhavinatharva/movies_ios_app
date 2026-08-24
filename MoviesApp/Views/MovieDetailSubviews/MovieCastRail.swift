import SwiftUI

struct MovieCastRail: View {
    let castString: String?
    let directorString: String?
    
    private var combinedList: [CastMember] {
        var list: [CastMember] = []
        
        if let director = directorString, !director.isEmpty {
            list.append(contentsOf: director.parseCastMembers(role: "Director"))
        }
        
        if let cast = castString, !cast.isEmpty {
            list.append(contentsOf: cast.parseCastMembers(role: "Actor"))
        }
        
        return list
    }
    
    var body: some View {
        if let _ = castString, !combinedList.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cast & Crew")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(combinedList) { person in
                            VStack(spacing: 8) {
                                if let imageUrl = person.imageUrl {
                                    AsyncImage(url: imageUrl) { phase in
                                        switch phase {
                                        case .empty:
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 80, height: 80)
                                                .shimmer()
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                        case .failure:
                                            initialsCircle(for: person.name)
                                        @unknown default:
                                            initialsCircle(for: person.name)
                                        }
                                    }
                                } else {
                                    initialsCircle(for: person.name)
                                }
                                
                                Text(person.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 80)
                                
                                Text(person.role)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(1)
                                    .frame(width: 80)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    private func initialsCircle(for name: String) -> some View {
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined()
        
        let colors: [Color] = [.indigo, .purple, .teal, .orange, .pink, .blue]
        let colorIndex = abs(name.hashValue) % colors.count
        
        return Circle()
            .fill(colors[colorIndex].opacity(0.7))
            .frame(width: 80, height: 80)
            .overlay(
                Text(initials.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}
