//
//  DashboardViewModel.swift
//  FinancialTracker
//

import Foundation
import SwiftData
import SwiftUI
import Observation

/// Dashboard (Özet Ekranı) için gerekli hesaplamaları ve mantığı içeren sınıf
@Observable
class DashboardViewModel {
    
    /// Filtrelenen işlemler arasından sadece gelir olanların toplamını (TL) hesaplar
    func totalIncome(transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Filtrelenen işlemler arasından sadece gider olanların toplamını (TL) hesaplar
    func totalExpense(transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Gündelik net cash bakiye (Gelirler eksi Giderler)
    func netBalance(transactions: [Transaction]) -> Double {
        totalIncome(transactions: transactions) - totalExpense(transactions: transactions)
    }
    
    /// Tüm yatırımların (Dolar, Altın vb.) "Canlı Kurlara (api'den gelen fiyatlara) Göre" güncel TRY değeri
    func totalInvestmentValue(assets: [InvestmentAsset], exchangeService: ExchangeRateService) -> Double {
        assets.reduce(0) { total, asset in
            // Varlığın türüne göre canlı kuru al
            let price = exchangeService.currentPrice(for: asset.assetType)
            // Toplam değerin üstüne ekle (Miktar x Güncel Kur)
            return total + asset.currentValue(currentPriceTRY: price)
        }
    }
    
    /// Gerçekleşmemiş Toplam Kâr/Zarar (Güncel Değer Eksi Maaliyet tabanlı)
    func totalUnrealizedPL(assets: [InvestmentAsset], exchangeService: ExchangeRateService) -> Double {
        assets.reduce(0) { total, asset in
            let price = exchangeService.currentPrice(for: asset.assetType)
            return total + asset.unrealizedPL(currentPriceTRY: price)
        }
    }
    
    /// Kullanıcının Toplam Varlığı = (Net Nakit Bakiye) + (Yatırımların Canlı Değeri)
    func totalNetWorth(transactions: [Transaction], assets: [InvestmentAsset], exchangeService: ExchangeRateService) -> Double {
        netBalance(transactions: transactions) + totalInvestmentValue(assets: assets, exchangeService: exchangeService)
    }
    
    /// Özet ekranında gösterilecek son 5 harcama/gelir
    func recentTransactions(transactions: [Transaction]) -> [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }
    
    /// Sadece içinde bulunduğumuz ay için aylık toplam gelir
    func currentMonthIncome(transactions: [Transaction]) -> Double {
        let startOfMonth = Date().startOfMonth
        return transactions
            .filter { $0.type == .income && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Sadece içinde bulunduğumuz ay için aylık toplam harcama
    func currentMonthExpense(transactions: [Transaction]) -> Double {
        let startOfMonth = Date().startOfMonth
        return transactions
            .filter { $0.type == .expense && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
}
