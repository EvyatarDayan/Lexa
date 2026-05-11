//
//  ContentView.swift
//  Lexa
//
//  Created by EVYATAR DAYAN on 2026-05-05.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    /// iPad: use 70% of window width (30% narrower than full-bleed). iPhone: unchanged.
    private static let iPadContentWidthFraction: CGFloat = 0.7

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Group {
            if isPad {
                GeometryReader { proxy in
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            SearchView()
                                .frame(maxWidth: proxy.size.width * Self.iPadContentWidthFraction)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                SearchView()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
