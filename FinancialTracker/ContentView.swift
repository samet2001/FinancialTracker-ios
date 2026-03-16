//
//  ContentView.swift
//  FinancialTracker
//
//  Created by SAMET FIRINCI on 13.02.2026.
//

import SwiftUI
import SwiftData

/// Main screen wrapper.
/// Ana ekran sarmalayıcısı (Wrapper).
/// Calls MainTabView directly to prevent the old ContentView structure from crashing.
/// Eski ContentView yapısının çökmesini engellemek için doğrudan MainTabView çağırılıyor.
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        // Provides the main in-memory container for preview during development
        // Geliştirme sürecinde preview için ana bellek container'ı sağlanıyor
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
