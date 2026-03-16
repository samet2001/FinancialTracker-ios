//
//  InvestmentTransaction.swift
//  FinancialTracker
//

import Foundation
import SwiftData

// MARK: - Investment Transaction Type (İşlem Yönü)
/// Type indicating whether a buy or sell was made for an investment
/// Yatırım için alım mı yoksa satım mı yapıldığını belirten tür
enum InvestmentTransactionType: String, Codable, CaseIterable {
    case buy = "buy"
    case sell = "sell"
    
    /// Turkish text to be shown in the interface
    /// Arayüzde gösterilecek Türkçe metin
    var displayName: String {
        switch self {
        case .buy: return "Alış"
        case .sell: return "Satış"
        }
    }
}

// MARK: - Investment Transaction Model (Yatırım İşlem/Hareket Modeli)
/// SwiftData table: Holds each past transaction (receipt) the user has performed for the asset
/// SwiftData tablosu: Kullanıcının varlık için gerçekleştirdiği her bir geçmiş işlemi (receipt) tutar
@Model
final class InvestmentTransaction {
    var id: UUID // Unique identifier of the transaction / İşlemin benzersiz kimliği
    var asset: InvestmentAsset? // Related investment asset (Parent relationship) / İlgili olduğu yatırım varlığı (Parent ilişkisi)
    var typeRaw: String // Transaction direction (buy/sell) database holder / İşlemin yönü (alım/satım) veritabanı tutucusu
    var quantity: Double // How many units were transacted / Ne kadar birim işlem yapıldığı
    var unitPriceTRY: Double // Buy/sell unit price in Turkish Lira at that moment / O anki Türk Lirası karşılığı alış/satış birim fiyatı
    var date: Date // Date of the transaction / İşlemin yapıldığı tarih
    var note: String // Optional description line / İsteğe bağlı açıklama satırı
    
    /// Converts the string value in the database to enum form
    /// Veritabanındaki string değeri enum şekline dönüştürür
    var type: InvestmentTransactionType {
        get { InvestmentTransactionType(rawValue: typeRaw) ?? .buy }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Total TL cost / value of this specific transaction (Unit price x Quantity)
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
