import SwiftUI

struct MovieTechnicalDetails: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technical Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 32) {
                techItem(title: "Audio", value: "English (Original)")
                techItem(title: "Subtitles", value: "English, CC")
            }
            
            HStack(spacing: 32) {
                techItem(title: "Stream", value: "HLS / MP4")
                techItem(title: "Quality", value: "1080p FHD")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func techItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
