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
                ).stroke(.buttonBorder,lineWidth: 5)
            }
    }
}
