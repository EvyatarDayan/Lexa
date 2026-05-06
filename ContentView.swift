//
//  ContentView.swift
//  Lexa
//
//  Created by EVYATAR DAYAN on 2026-05-05.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        SearchView()
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
