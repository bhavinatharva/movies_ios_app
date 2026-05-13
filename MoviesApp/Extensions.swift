//
//  Extensions.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import Foundation
import SwiftUI


extension Text {
    func ghostButton() -> some View{
        self
            .foregroundStyle(.buttonText)
            .frame(width: 100,height: 50)
            .bold()
            .background{
                RoundedRectangle(cornerRadius: 20,style: .continuous
                ).stroke(.buttonBorder,lineWidth: 1)
            }
    }
}

extension View {
    func netflixStyleGradient() -> some View {
        self.overlay {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .clear, location: 0.5),
                    Gradient.Stop(color: .black.opacity(0.8), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    func cardStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}
