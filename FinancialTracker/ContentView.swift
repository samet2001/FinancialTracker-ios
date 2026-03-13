//
//  ContentView.swift
//  FinancialTracker
//
//  Created by SAMET FIRINCI on 13.02.2026.
//

import SwiftUI
import SwiftData

/// Ana ekran sarmalayıcısı (Wrapper). 
/// Eski ContentView yapısının çökmesini engellemek için doğrudan MainTabView çağırılıyor.
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        // Geliştirme sürecinde preview için ana bellek container'ı sağlanıyor
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
