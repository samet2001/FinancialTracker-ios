//
//  InvestmentTransaction.swift
//  FinancialTracker
//

import Foundation
import SwiftData

// MARK: - Investment Transaction Type (İşlem Yönü)
/// Yatırım için alım mı yoksa satım mı yapıldığını belirten tür
enum InvestmentTransactionType: String, Codable, CaseIterable {
    case buy = "buy"
    case sell = "sell"
    
    /// Arayüzde gösterilecek Türkçe metin
    var displayName: String {
        switch self {
        case .buy: return "Alış"
        case .sell: return "Satış"
        }
    }
}

// MARK: - Investment Transaction Model (Yatırım İşlem/Hareket Modeli)
/// SwiftData tablosu: Kullanıcının varlık için gerçekleştirdiği her bir geçmiş işlemi (receipt) tutar
@Model
final class InvestmentTransaction {
    var id: UUID // İşlemin benzersiz kimliği
    var asset: InvestmentAsset? // İlgili olduğu yatırım varlığı (Parent ilişkisi)
    var typeRaw: String // İşlemin yönü (alım/satım) veritabanı tutucusu
    var quantity: Double // Ne kadar birim işlem yapıldığı
    var unitPriceTRY: Double // O anki Türk Lirası karşılığı alış/satış birim fiyatı
    var date: Date // İşlemin yapıldığı tarih
    var note: String // İsteğe bağlı açıklama satırı
    
    /// Veritabanındaki string değeri enum şekline dönüştürür
    var type: InvestmentTransactionType {
        get { InvestmentTransactionType(rawValue: typeRaw) ?? .buy }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Bu spesifik işlemin toplam TL maliyeti / değeri (Birim fiyat x Çokluk)
    var totalValue: Double {
        quantity * unitPriceTRY
    }
    
    init(
        asset: InvestmentAsset? = nil,
        type: InvestmentTransactionType,
        quantity: Double,
        unitPriceTRY: Double,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = UUID()
        self.asset = asset
        self.typeRaw = type.rawValue
        self.quantity = quantity
        self.unitPriceTRY = unitPriceTRY
        self.date = date
        self.note = note
    }
}
