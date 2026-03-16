//
//  FinancialTrackerApp.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// The main entry point of the application.
/// Uygulamanın ana başlangıç noktası (Entry Point).
/// Tells SwiftUI how the app starts and attaches the data architecture at the top level.
/// SwiftUI'a uygulamanın nasıl başlayacağını söyler ve veri mimarasini en üste takar.
@main
struct FinancialTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            // The initial screen displayed when the app is first opened
            // İlk açıldığında görüntülenecek ön ekran
            ContentView()
        }
        // Registers the SwiftData tables (models) with the application
        // SwiftData veri tablolarını (modelleri) uygulamaya tanıtır
        // 'modelContainer' configures the app to persist this data permanently in device memory and SQLite
        // 'modelContainer', uygulamanın cihaz belleğine ve SQLite tabanına kalıcı olarak bu verileri kaydetmesi gerektiğini ayarlar
        .modelContainer(for: [
            Transaction.self,
            InvestmentAsset.self,
            InvestmentTransaction.self
        ])
    }
}
