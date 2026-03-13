//
//  FinancialTrackerApp.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Uygulamanın ana başlangıç noktası (Entry Point). 
/// SwiftUI'a uygulamanın nasıl başlayacağını söyler ve veri mimarasini en üste takar.
@main
struct FinancialTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            // İlk açıldığında görüntülenecek ön ekran
            ContentView()
        }
        // SwiftData veri tablolarını (modelleri) uygulamaya tanıtır
        // 'modelContainer', uygulamanın cihaz belleğine ve SQLite tabanına kalıcı olarak bu verileri kaydetmesi gerektiğini ayarlar
        .modelContainer(for: [
            Transaction.self,
            InvestmentAsset.self,
            InvestmentTransaction.self
        ])
    }
}
