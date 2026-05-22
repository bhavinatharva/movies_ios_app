import SwiftUI

struct MovieCastRail: View {
    let castString: String?
    let directorString: String?
    
    var body: some View {
        let combinedList = parseCastAndDirector()
        
        if !combinedList.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cast & Crew")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(combinedList, id: \.name) { person in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .foregroundColor(.white.opacity(0.3))
                                            .padding(10)
                                    )
                                
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
    
    private func parseCastAndDirector() -> [(name: String, role: String)] {
        var list: [(name: String, role: String)] = []
        
        if let director = directorString, !director.isEmpty {
            let directors = director.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            for d in directors {
                list.append((name: d, role: "Director"))
            }
        }
        
        if let cast = castString, !cast.isEmpty {
            let actors = cast.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            for a in actors {
                list.append((name: a, role: "Actor"))
            }
        }
        
        return list
    }
}
