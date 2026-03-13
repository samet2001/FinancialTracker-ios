//
//  MainTabView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Uygulamanın en altındaki ana menüyü (sekme barını) yönetir.
/// Kullanıcının sayfalar arası geçişini sağlar.
struct MainTabView: View {
    // Hangi sekmede olduğumuzu takip etmek için bir durum değişkeni
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Özet / Dashboard Sekmesi
            DashboardView()
                .tabItem {
                    Label("Özet", systemImage: "house.fill")
                }
                .tag(0)
            
            // İşlemler / Gider ve Gelirler Sekmesi
            TransactionListView()
                .tabItem {
                    Label("İşlemler", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)
            
            // Yatırımlar / Portföy Sekmesi
            InvestmentPortfolioView()
                .tabItem {
                    Label("Yatırımlar", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            // Raporlar ve Grafikler Sekmesi
            ReportsView()
                .tabItem {
                    Label("Raporlar", systemImage: "chart.pie.fill")
                }
                .tag(3)
        }
        // Seçili sekmenin renk tonu, global aksan rengiyle eşleştiriliyor
        .tint(.accentGradientStart)
    }
}

#Preview {
    MainTabView()
        // Preview ortamında hata çıkmaması için in-memory bir model container ekliyoruz
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
