import SwiftUI

struct PlaylistCardView: View {
    let playlist: Playlist
    let isActive: Bool
    
    // Actions
    var onActivate: () -> Void
    var onDelete: () -> Void
    var onRefresh: () -> Void
    
    var body: some View {
        #if os(tvOS)
        Button(action: {
            onActivate()
        }) {
            cardContent
        }
        .buttonStyle(.card)
        .contextMenu {
            Button { onRefresh() } label: { Label("Force Refresh Data", systemImage: "arrow.clockwise") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete Playlist", systemImage: "trash") }
        }
        #else
        cardContent
        #endif
    }
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            // Provider Logo Placeholder / Initials
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.accentColor.opacity(0.6), Color.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    #if os(tvOS)
                    .frame(width: 100, height: 100)
                    #else
                    .frame(width: 50, height: 50)
                    #endif
                
                Text(String(playlist.name.prefix(1)).uppercased())
                    #if os(tvOS)
                    .font(.system(size: 40, weight: .bold))
                    #else
                    .font(.title2)
                    .fontWeight(.bold)
                    #endif
                    .foregroundColor(.white)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(playlist.name)
                        #if os(tvOS)
                        .font(.system(size: 32, weight: .bold))
                        #else
                        .font(.headline)
                        .fontWeight(.bold)
                        #endif
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if isActive {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.accentColor)
                            #if os(tvOS)
                            .font(.system(size: 28))
                            #else
                            .font(.subheadline)
                            #endif
                    }
                }
                
                Text(playlist.url)
                    #if os(tvOS)
                    .font(.system(size: 24))
                    #else
                    .font(.caption)
                    #endif
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                let syncStatus = IPTVSyncManager.shared.status(for: playlist.id)
                switch syncStatus {
                case .syncing(let progress):
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Syncing \(Int(progress * 100))%...")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 2)
                case .error(let message):
                    Text("Sync error: \(message)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .padding(.top, 2)
                default:
                    HStack(spacing: 12) {
                        Label("— Movies", systemImage: "film")
                        Label("— Series", systemImage: "tv")
                    }
                    #if os(tvOS)
                    .font(.system(size: 20))
                    #else
                    .font(.caption2)
                    #endif
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }
            }
            
            
            Spacer()
            
            #if !os(tvOS)
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
            #endif
        }
        .padding(16)
        #if os(tvOS)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        #else
        .liquidGlass()
        .pressLiftEffect()
        #endif
    }
}

