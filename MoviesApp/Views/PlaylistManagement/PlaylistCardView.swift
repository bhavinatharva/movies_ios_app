import SwiftUI

struct PlaylistCardView: View {
    let playlist: Playlist
    let isActive: Bool
    
    // Actions
    var onActivate: () -> Void
    var onDelete: () -> Void
    var onRefresh: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Provider Logo Placeholder / Initials
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.accentColor.opacity(0.6), Color.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Text(String(playlist.name.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(playlist.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if isActive {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                    }
                }
                
                Text(playlist.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("— Movies", systemImage: "film")
                    Label("— Series", systemImage: "tv")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            }
            
            
            Spacer()
            
            Menu {
                Button {
                    onActivate()
                } label: {
                    Label("Activate Playlist", systemImage: "play.circle")
                }
                
                Button {
                    onRefresh()
                } label: {
                    Label("Force Refresh Data", systemImage: "arrow.clockwise")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Playlist", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .padding(16)
        .liquidGlass()
        .pressLiftEffect()
    }
}
