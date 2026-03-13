//
//  InvestmentAsset.swift
//  FinancialTracker
//

import Foundation
import SwiftData

// MARK: - Asset Type (Yatırım Türü)
/// Sistemde desteklenen yatırım aracı türleri (Gram Altın, Dolar, Euro vb.)
enum AssetType: String, Codable, CaseIterable, Identifiable {
    case goldGram = "goldGram"
    case usd = "usd"
    case eur = "eur"
    
    var id: String { rawValue }
    
    /// Arayüzde görünen Türkçe tam isim
    var displayName: String {
        switch self {
        case .goldGram: return "Gram Altın"
        case .usd: return "ABD Doları"
        case .eur: return "Euro"
        }
    }
    
    /// UI üzerinde listelenirken gösterilecek sembol/emoji
    var symbol: String {
        switch self {
        case .goldGram: return "🪙"
        case .usd: return "💵"
        case .eur: return "💶"
        }
    }
    
    /// Varlık için miktar birimi
    var unit: String {
        switch self {
        case .goldGram: return "gr"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
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
/// SwiftData kullanıcının sahip olduğu toplam varlığı (cüzdanı) tutan ana tablo
@Model
final class InvestmentAsset {
    var id: UUID // Benzersiz kimlik
    var assetTypeRaw: String // Veritabanında saklanan tür verisi
    var totalQuantity: Double // Toplam sahip olunan birim/miktar
    var weightedAverageCost: Double // Ağırlıklı Ortalama Maliyet (WAC)
    
    // Alt işlemlere (alım-satım hareketleri) bire-çok bağlantı. 
    // Ana kayıt silinirse hareketler de silinir (cascade).
    @Relationship(deleteRule: .cascade, inverse: \InvestmentTransaction.asset)
    var transactions: [InvestmentTransaction]
    
    /// String'den AssetType enum'ına çeviren ve koruyan değişken (Computed property)
    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRaw) ?? .goldGram }
        set { assetTypeRaw = newValue.rawValue }
    }
    
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
    
    /// Yeni bir ALIM yapıldığında "Ağırlıklı Ortalama Maliyet" ve miktarı güncelleyen ana algoritma
    func addBuyTransaction(quantity: Double, unitPrice: Double) {
        // Eski toplam maaliyet
        let oldTotal = totalQuantity * weightedAverageCost
        // Yeni alınan kısmın maaliyeti
        let newTotal = quantity * unitPrice
        
        // Miktarı ekle
        totalQuantity += quantity
        
        // Yeni ağırlıklı ortalama hesapla: Toplam Maaliyet / Toplam Yeni Miktar
        if totalQuantity > 0 {
            weightedAverageCost = (oldTotal + newTotal) / totalQuantity
        }
    }
    
    /// Bir SATIŞ yapıldığında bakiyeyi düşen algoritma. (Kurallara göre satış işlemi WAC'i değiştirmez)
    func addSellTransaction(quantity: Double) {
        // Eğer eldeki miktardan fazla satılıyorsa 0'lar (eksiye düşürmez)
        totalQuantity = max(0, totalQuantity - quantity)
        // Eğer tüm varlık satıldıysa maaliyeti sıfırla
        if totalQuantity == 0 {
            weightedAverageCost = 0
        }
    }
    
    /// API'den gelen canlı güncel fiyata göre, kullanıcının ne kadar Gerçekleşmemiş Kar/Zarar (P/L) yaptığını TL bazında hesaplar
    func unrealizedPL(currentPriceTRY: Double) -> Double {
        return (currentPriceTRY - weightedAverageCost) * totalQuantity
    }
    
    /// Mevcut miktarın, piyasadan alınan canlı güncel kura göre TL karşılığı
    func currentValue(currentPriceTRY: Double) -> Double {
        return currentPriceTRY * totalQuantity
    }
}
