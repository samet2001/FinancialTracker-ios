//
//  MainTabView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Manages the main menu (tab bar) at the very bottom of the application.
/// Uygulamanın en altındaki ana menüyü (sekme barını) yönetir.
/// Provides navigation between pages for the user.
/// Kullanıcının sayfalar arası geçişini sağlar.
struct MainTabView: View {
    // A state variable to keep track of which tab we are on
    // Hangi sekmede olduğumuzu takip etmek için bir durum değişkeni
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Summary / Dashboard Tab / Özet / Dashboard Sekmesi
            DashboardView()
                .tabItem {
                    Label("Özet", systemImage: "house.fill")
                }
                .tag(0)
            
            // Transactions / Income and Expenses Tab / İşlemler / Gider ve Gelirler Sekmesi
            TransactionListView()
                .tabItem {
                    Label("İşlemler", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)
            
            // Investments / Portfolio Tab / Yatırımlar / Portföy Sekmesi
            InvestmentPortfolioView()
                .tabItem {
                    Label("Yatırımlar", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            // Reports and Charts Tab / Raporlar ve Grafikler Sekmesi
            ReportsView()
                .tabItem {
                    Label("Raporlar", systemImage: "chart.pie.fill")
                }
                .tag(3)
        }
        // The color tone of the selected tab is matched with the global accent color
        // Seçili sekmenin renk tonu, global aksan rengiyle eşleştiriliyor
        .tint(.accentGradientStart)
    }
}

#Preview {
    MainTabView()
        // We add an in-memory model container so as not to get an error in the preview environment
        // Preview ortamında hata çıkmaması için in-memory bir model container ekliyoruz
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
