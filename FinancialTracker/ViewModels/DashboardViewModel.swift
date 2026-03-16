//
//  DashboardViewModel.swift
//  FinancialTracker
//

import Foundation
import SwiftData
import SwiftUI
import Observation

/// Class containing the logic and calculations necessary for the Dashboard (Summary Screen)
/// Dashboard (Özet Ekranı) için gerekli hesaplamaları ve mantığı içeren sınıf
@Observable
class DashboardViewModel {
    
    /// Calculates the sum of only those among filtered transactions that are income (TRY)
    /// Filtrelenen işlemler arasından sadece gelir olanların toplamını (TL) hesaplar
    func totalIncome(transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Calculates the sum of only those among filtered transactions that are expenses (TRY)
    /// Filtrelenen işlemler arasından sadece gider olanların toplamını (TL) hesaplar
    func totalExpense(transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Daily net cash balance (Income minus Expenses)
    /// Gündelik net cash bakiye (Gelirler eksi Giderler)
    func netBalance(transactions: [Transaction]) -> Double {
        totalIncome(transactions: transactions) - totalExpense(transactions: transactions)
    }
    
    /// Current TRY value of all investments (Dollar, Gold, etc.) "Based on Live Exchange Rates" (prices coming from api)
    /// Tüm yatırımların (Dolar, Altın vb.) "Canlı Kurlara (api'den gelen fiyatlara) Göre" güncel TRY değeri
    func totalInvestmentValue(assets: [InvestmentAsset], exchangeService: ExchangeRateService) -> Double {
        assets.reduce(0) { total, asset in
            // Get live rate according to type of asset / Varlığın türüne göre canlı kuru al
            let price = exchangeService.currentPrice(for: asset.assetType)
            // Add on top of total value (Quantity x Current Rate) / Toplam değerin üstüne ekle (Miktar x Güncel Kur)
            return total + asset.currentValue(currentPriceTRY: price)
        }
    }
    
    /// Total Unrealized Profit/Loss (based on Current Value Minus Cost)
    /// Gerçekleşmemiş Toplam Kâr/Zarar (Güncel Değer Eksi Maaliyet tabanlı)
    func totalUnrealizedPL(assets: [InvestmentAsset], exchangeService: ExchangeRateService) -> Double {
        assets.reduce(0) { total, asset in
            let price = exchangeService.currentPrice(for: asset.assetType)
            return total + asset.unrealizedPL(currentPriceTRY: price)
        }
    }
    
    /// User's Total Asset = (Net Cash Balance) + (Live Value of Investments)
    /// Kullanıcının Toplam Varlığı = (Net Nakit Bakiye) + (Yatırımların Canlı Değeri)
    func totalNetWorth(transactions: [Transaction], assets: [InvestmentAsset], exchangeService: ExchangeRateService) -> Double {
        netBalance(transactions: transactions) + totalInvestmentValue(assets: assets, exchangeService: exchangeService)
    }
    
    /// Last 5 expenses/incomes to be shown on the summary screen
    /// Özet ekranında gösterilecek son 5 harcama/gelir
    func recentTransactions(transactions: [Transaction]) -> [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }
    
    /// Monthly total income for only the current month
    /// Sadece içinde bulunduğumuz ay için aylık toplam gelir
    func currentMonthIncome(transactions: [Transaction]) -> Double {
        let startOfMonth = Date().startOfMonth
        return transactions
            .filter { $0.type == .income && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Monthly total expense for only the current month
    /// Sadece içinde bulunduğumuz ay için aylık toplam harcama
    func currentMonthExpense(transactions: [Transaction]) -> Double {
        let startOfMonth = Date().startOfMonth
        return transactions
            .filter { $0.type == .expense && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
}
