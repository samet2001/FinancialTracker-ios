//
//  InvestmentAsset.swift
//  FinancialTracker
//

import Foundation
import SwiftData

// MARK: - Asset Type (Yatırım Türü)
/// Types of investment instruments supported in the system (Gram Gold, Dollar, Euro, etc.)
/// Sistemde desteklenen yatırım aracı türleri (Gram Altın, Dolar, Euro vb.)
enum AssetType: String, Codable, CaseIterable, Identifiable {
    case goldGram = "goldGram"
    case usd = "usd"
    case eur = "eur"
    
    var id: String { rawValue }
    
    /// Full Turkish name appearing in the interface
    /// Arayüzde görünen Türkçe tam isim
    var displayName: String {
        switch self {
        case .goldGram: return "Gram Altın"
        case .usd: return "ABD Doları"
        case .eur: return "Euro"
        }
    }
    
    /// Symbol/emoji to be shown when listed on the UI
    /// UI üzerinde listelenirken gösterilecek sembol/emoji
    var symbol: String {
        switch self {
        case .goldGram: return "🪙"
        case .usd: return "💵"
        case .eur: return "💶"
        }
    }
    
    /// Quantity unit for the asset
    /// Varlık için miktar birimi
    var unit: String {
        switch self {
        case .goldGram: return "gr"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    /// SF Symbols icon name
    /// SF Symbols ikon adı
    var icon: String {
        switch self {
        case .goldGram: return "bitcoinsign.circle.fill"
        case .usd: return "dollarsign.circle.fill"
        case .eur: return "eurosign.circle.fill"
        }
    }
}

// MARK: - Investment Asset Model (Yatırım Varlığı Modeli)
/// SwiftData main table holding the total asset (wallet) owned by the user
/// SwiftData kullanıcının sahip olduğu toplam varlığı (cüzdanı) tutan ana tablo
@Model
final class InvestmentAsset {
    var id: UUID // Unique identifier / Benzersiz kimlik
    var assetTypeRaw: String // Type data stored in the database / Veritabanında saklanan tür verisi
    var totalQuantity: Double // Total owned unit/quantity / Toplam sahip olunan birim/miktar
    var weightedAverageCost: Double // Weighted Average Cost (WAC) / Ağırlıklı Ortalama Maliyet (WAC)
    
    // One-to-many connection to sub-transactions (buy-sell movements).
    // If the main record is deleted, movements are also deleted (cascade).
    // Alt işlemlere (alım-satım hareketleri) bire-çok bağlantı. 
    // Ana kayıt silinirse hareketler de silinir (cascade).
    @Relationship(deleteRule: .cascade, inverse: \InvestmentTransaction.asset)
    var transactions: [InvestmentTransaction]
    
    /// Computed property that translates from String to AssetType enum and protects it
    /// String'den AssetType enum'ına çeviren ve koruyan değişken (Computed property)
    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRaw) ?? .goldGram }
        set { assetTypeRaw = newValue.rawValue }
    }
    
    /// Total cost of ownership for the asset (Weighted Average X Quantity)
    /// Sahip olunan varlığın alınan toplam maaliyeti (Ağırlıklı Ortalama X Miktar)
    var totalCost: Double {
        weightedAverageCost * totalQuantity
    }
    
    init(assetType: AssetType) {
        self.id = UUID()
        self.assetTypeRaw = assetType.rawValue
        self.totalQuantity = 0
        self.weightedAverageCost = 0
        self.transactions = []
    }
    
    /// Main algorithm that updates "Weighted Average Cost" and quantity when a new BUY is made
    /// Yeni bir ALIM yapıldığında "Ağırlıklı Ortalama Maliyet" ve miktarı güncelleyen ana algoritma
    func addBuyTransaction(quantity: Double, unitPrice: Double) {
        // Old total cost / Eski toplam maaliyet
        let oldTotal = totalQuantity * weightedAverageCost
        // Cost of the newly purchased part / Yeni alınan kısmın maaliyeti
        let newTotal = quantity * unitPrice
        
        // Add quantity / Miktarı ekle
        totalQuantity += quantity
        
        // Calculate the new weighted average: Total Cost / Total New Quantity
        // Yeni ağırlıklı ortalama hesapla: Toplam Maaliyet / Toplam Yeni Miktar
        if totalQuantity > 0 {
            weightedAverageCost = (oldTotal + newTotal) / totalQuantity
        }
    }
    
    /// Algorithm that reduces the balance when a SALE is made. (According to rules, sale transaction does not change WAC)
    /// Bir SATIŞ yapıldığında bakiyeyi düşen algoritma. (Kurallara göre satış işlemi WAC'i değiştirmez)
    func addSellTransaction(quantity: Double) {
        // Zeros if more is sold than the quantity on hand (does not fall into negative)
        // Eğer eldeki miktardan fazla satılıyorsa 0'lar (eksiye düşürmez)
        totalQuantity = max(0, totalQuantity - quantity)
        // Reset cost if all assets are sold / Eğer tüm varlık satıldıysa maaliyeti sıfırla
        if totalQuantity == 0 {
            weightedAverageCost = 0
        }
    }
    
    /// Calculates how much Unrealized Profit/Loss (P/L) the user has made in TRY based on the live current price from the API
    /// API'den gelen canlı güncel fiyata göre, kullanıcının ne kadar Gerçekleşmemiş Kar/Zarar (P/L) yaptığını TL bazında hesaplar
    func unrealizedPL(currentPriceTRY: Double) -> Double {
        return (currentPriceTRY - weightedAverageCost) * totalQuantity
    }
    
    /// TL equivalent of the current quantity according to the live current exchange rate received from the market
    /// Mevcut miktarın, piyasadan alınan canlı güncel kura göre TL karşılığı
    func currentValue(currentPriceTRY: Double) -> Double {
        return currentPriceTRY * totalQuantity
    }
}
