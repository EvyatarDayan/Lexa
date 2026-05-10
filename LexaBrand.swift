//
//  LexaBrand.swift
//  Lexa
//

import SwiftUI

enum LexaBrand {
    /// Multicolor “Lexa” wordmark gradient used in the header and welcome states.
    static let wordmarkGradient = LinearGradient(
        colors: [
            Color(red: 0.26, green: 0.52, blue: 0.96),
            Color(red: 0.92, green: 0.25, blue: 0.21),
            Color(red: 0.98, green: 0.75, blue: 0.18),
            Color(red: 0.20, green: 0.66, blue: 0.33),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
