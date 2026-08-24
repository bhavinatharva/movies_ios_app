//
//  PremiumPaywallView.swift

//

import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeManager = StoreManager.shared
    @State private var selectedPlan: PremiumPlan = .yearly
    @State private var animateHero = false
    @State private var isPurchasing = false
    
    // Smooth scrolling tracking could go here for parallax, but we keep it simple for 60fps
    
    var body: some View {
        ZStack {
            // Dark premium background
            Color.appBackground.ignoresSafeArea()
            
            // Subtle animated background glow
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: animateHero ? 100 : -100, y: animateHero ? -100 : 100)
                .animation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateHero)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // 1. Hero Header Section
                    heroSection
                    
                    // 2. Feature Showcase Section
                    featuresSection
                        .padding(.top, 40)
                    
                    // 3. Premium Benefits Text Section
                    benefitsSection
                        .padding(.top, 40)
                    
                    // 4. Plan Selection Section
                    plansSection
                        .padding(.top, 40)
                        
                    // 5. Trust / Footer Section
                    footerSection
                        .padding(.top, 40)
                        .padding(.bottom, 120) // Space for CTA
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Custom Dismiss Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.6))
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60) // Safe area padding
                }
                Spacer()
            }
        }
        .overlay(alignment: .bottom) {
            // 6. Floating CTA
            ctaSection
        }
        .onAppear {
            animateHero = true
        }
    }
    
    // MARK: - Sections
    
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Cinematic background layer
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.4), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 550)
                
                // Abstract Floating Cards (Simulating modern UI)
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        floatingMockupCard(icon: "tv", color: .pink, delay: 0.0)
                        floatingMockupCard(icon: "film.fill", color: .blue, delay: 0.2)
                        floatingMockupCard(icon: "play.tv.fill", color: .purple, delay: 0.4)
                    }
                    .rotation3DEffect(.degrees(15), axis: (x: 1, y: 0, z: 0))
                    .offset(y: animateHero ? -10 : 10)
                    .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateHero)
                }
                .opacity(0.4)
            }
            
            // Premium Gradient Overlay
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.3),
                    .init(color: .appBackground, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 550)
            
            // Hero Text
            VStack(spacing: 16) {
                // Logo/Badge
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("PRO")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                
                Text("Your Ultimate\nStreaming Experience")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text("Unlock the full power of modern IPTV. All your entertainment, beautifully organized in one premium app.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
            }
            .padding(.bottom, 20)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Premium Features")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    PremiumFeatureCard(icon: "tv.and.mediabox", title: "Live TV", subtitle: "Zero buffering live stream engine", color: .blue)
                    PremiumFeatureCard(icon: "film.stack.fill", title: "Movies & Series", subtitle: "Cinematic native OTT experience", color: .purple)
                    PremiumFeatureCard(icon: "calendar.badge.clock", title: "Smart EPG", subtitle: "Automatic TV guide synchronization", color: .orange)
                    PremiumFeatureCard(icon: "bolt.fill", title: "Fast Zap", subtitle: "Lightning fast channel switching", color: .yellow)
                    PremiumFeatureCard(icon: "list.and.film", title: "Multi Playlist", subtitle: "Add unlimited IPTV sources", color: .pink)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 16) {
            benefitRow(icon: "infinity", text: "Unlimited streaming without restrictions")
            benefitRow(icon: "iphone.and.arrow.forward", text: "Sync seamlessly across your Apple devices")
            benefitRow(icon: "shield.fill", text: "Secure, private, and zero ads forever")
        }
        .padding(.horizontal, 24)
    }
    
    private var plansSection: some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                PricingPlanCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    priceString: PremiumPlan.monthly.displayPrice(from: storeManager.products),
                    action: { selectedPlan = .monthly }
                )
                
                PricingPlanCard(
                    plan: .yearly,
                    isSelected: selectedPlan == .yearly,
                    priceString: PremiumPlan.yearly.displayPrice(from: storeManager.products),
                    action: { selectedPlan = .yearly }
                )
                
                PricingPlanCard(
                    plan: .lifetime,
                    isSelected: selectedPlan == .lifetime,
                    priceString: PremiumPlan.lifetime.displayPrice(from: storeManager.products),
                    action: { selectedPlan = .lifetime }
                )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var ctaSection: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.appBackground.opacity(0.0), .appBackground], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
            
            VStack(spacing: 12) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    Task {
                        isPurchasing = true
                        if let product = storeManager.products.first(where: { $0.id == selectedPlan.productId }) {
                            try? await storeManager.purchase(product)
                            if storeManager.isPurchased {
                                dismiss()
                            }
                        }
                        isPurchasing = false
                    }
                }) {
                    ZStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Start \(selectedPlan.title) Plan")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 10, y: 5)
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(isPurchasing)
                
                Text(selectedPlan.trialText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34) // Safe area approx
            .background(Color.appBackground)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await storeManager.restorePurchases()
                    if storeManager.isPurchased {
                        dismiss()
                    }
                }
            }) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .buttonStyle(PressScaleButtonStyle())
            
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                Text("•")
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption2)
            .foregroundColor(.gray)
        }
    }
    
    // MARK: - Helpers
    
    private func floatingMockupCard(icon: String, color: Color, delay: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 10)
        }
        .glassBackground(cornerRadius: 16)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

// MARK: - Enums
enum PremiumPlan {
    case monthly, yearly, lifetime
    
    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$39.99"
        case .lifetime: return "$89.99"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "per year ($3.33/mo)"
        case .lifetime: return "one-time payment"
        }
    }
    
    var isRecommended: Bool {
        return self == .yearly
    }
    
    var trialText: String {
        switch self {
        case .monthly, .yearly: return "7-Days Free Trial • Cancel Anytime"
        case .lifetime: return "Pay once, stream forever."
        }
    }
    
    var productId: String {
        switch self {
        case .monthly: return "com.moviesapp.premium.monthly"
        case .yearly: return "com.moviesapp.premium.yearly"
        case .lifetime: return "com.moviesapp.premium.lifetime"
        }
    }
    
    func displayPrice(from products: [Product]) -> String {
        if let product = products.first(where: { $0.id == self.productId }) {
            return product.displayPrice
        }
        return self.price
    }
}

// MARK: - Subcomponents

struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(12)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(width: 160, height: 160, alignment: .topLeading)
        .glassBackground(cornerRadius: 16)
    }
}

struct PricingPlanCard: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let priceString: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .gray)
                        
                        if plan.isRecommended {
                            Text("MOST POPULAR")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(priceString)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.appCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.05), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PremiumPaywallView()
}
