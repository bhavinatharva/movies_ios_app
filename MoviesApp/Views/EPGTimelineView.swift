import SwiftUI

struct EPGTimelineView: View {
    @StateObject private var viewModel = EPGViewModel()
    
    // Grid configuration
    private let hourWidth: CGFloat = 200
    private let channelColumnWidth: CGFloat = 120
    private let rowHeight: CGFloat = 60
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading TV Guide...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if viewModel.channels.isEmpty {
                ContentUnavailableView("No Live Channels", systemImage: "tv.slash", description: Text("Load an IPTV playlist with live channels to view the guide."))
            } else {
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        Text("TV Guide")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                        Spacer()
                    }
                    .background(Color.appCardBackground)
                    
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Timeline Header (Hours)
                            HStack(spacing: 0) {
                                // Empty corner above channels
                                Color.appCardBackground
                                    .frame(width: channelColumnWidth, height: 40)
                                    .border(Color.white.opacity(0.1), width: 0.5)
                                
                                ForEach(0..<viewModel.hoursToShow, id: \.self) { hourOffset in
                                    let time = Calendar.current.date(byAdding: .hour, value: hourOffset, to: viewModel.startHour) ?? Date()
                                    Text(timeFormatter.string(from: time))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: hourWidth, height: 40)
                                        .background(Color.appCardBackground)
                                        .border(Color.white.opacity(0.1), width: 0.5)
                                }
                            }
                            
                            // Channel Rows
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.channels) { channel in
                                    HStack(spacing: 0) {
                                        // Channel Info Column
                                        HStack {
                                            if let logoUrl = channel.logoUrl {
                                                AsyncImage(url: logoUrl) { image in
                                                    image.resizable().scaledToFit()
                                                } placeholder: {
                                                    Image(systemName: "tv").foregroundColor(.gray)
                                                }
                                                .frame(width: 36, height: 36)
                                            } else {
                                                Image(systemName: "tv").foregroundColor(.gray).frame(width: 36, height: 36)
                                            }
                                            
                                            Text(channel.name)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .frame(width: channelColumnWidth, height: rowHeight)
                                        .background(Color.appCardBackground)
                                        .border(Color.white.opacity(0.1), width: 0.5)
                                        .onTapGesture {
                                            GlobalPlayerManager.shared.play(
                                                url: channel.streamUrl,
                                                title: channel.name,
                                                artwork: channel.logoUrl?.absoluteString,
                                                isLive: true
                                            )
                                        }
                                        
                                        // Programs Timeline
                                        ZStack(alignment: .leading) {
                                            // Empty track background
                                            Color.appBackground
                                                .frame(width: CGFloat(viewModel.hoursToShow) * hourWidth, height: rowHeight)
                                                .border(Color.white.opacity(0.1), width: 0.5)
                                            
                                            if let epgId = channel.epgId, let programs = viewModel.programs[epgId] {
                                                ForEach(programs) { program in
                                                    if let rect = calculateProgramRect(program: program) {
                                                        EPGProgramCard(program: program)
                                                            .frame(width: rect.width, height: rowHeight - 4)
                                                            .padding(.leading, rect.x)
                                                    }
                                                }
                                            } else {
                                                Text("No EPG Data")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 16)
                                            }
                                        }
                                        .frame(width: CGFloat(viewModel.hoursToShow) * hourWidth, height: rowHeight, alignment: .leading)
                                        .clipped()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadEPG()
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        return df
    }()
    
    private func calculateProgramRect(program: EPGProgram) -> (x: CGFloat, width: CGFloat)? {
        let gridEndTime = Calendar.current.date(byAdding: .hour, value: viewModel.hoursToShow, to: viewModel.startHour)!
        
        // Skip if program is entirely outside the viewable window
        if program.stop <= viewModel.startHour || program.start >= gridEndTime {
            return nil
        }
        
        // Clamp start and stop to the viewable window
        let clampedStart = max(program.start, viewModel.startHour)
        let clampedStop = min(program.stop, gridEndTime)
        
        let startOffset = clampedStart.timeIntervalSince(viewModel.startHour)
        let duration = clampedStop.timeIntervalSince(clampedStart)
        
        let pixelsPerSecond = hourWidth / 3600.0
        
        return (
            x: CGFloat(startOffset) * pixelsPerSecond,
            width: CGFloat(duration) * pixelsPerSecond
        )
    }
}

struct EPGProgramCard: View {
    let program: EPGProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(program.title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let desc = program.description {
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
        )
    }
}
