//
//  InvestmentViewModel.swift
//  FinancialTracker
//

import Foundation
import SwiftData
import SwiftUI
import Observation

/// Class that triggers investment transaction logic (buy/sell) and manages Weighted Average Cost
/// Yatırım işlemleri mantığını (alım/satım) tetikleyen ve Ağırlıklı Ortalama Maliyeti yöneten sınıf
@Observable
class InvestmentViewModel {
    
    // State variables of the investment addition form
    // Yatırım ekleme formunun durum değişkenleri (State)
    var selectedAssetType: AssetType = .goldGram
    var selectedTransactionType: InvestmentTransactionType = .buy
    var quantityText: String = "" // Unit bought or sold / Alınan ya da satılan birim
    var unitPriceText: String = "" // Price of 1 unit at that moment / O anki 1 birimin fiyatı
    var date: Date = Date()
    var note: String = ""
    
    /// Converter that turns quantity input supporting comma compatible with Turkish into Double
    /// Türkçeye uyumlu virgül destekleyen miktar girdisini Double'a çeviren dönüştürücü
    var quantity: Double {
        Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    /// Converter that turns unit price input supporting comma into Double
    /// Virgül destekleyen birim fiyat girdisini Double'a çeviren dönüştürücü
    var unitPrice: Double {
        Double(unitPriceText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    /// Validity check for the save investment transaction button
    /// Yatırım işlemi kaydet butonu için geçerlilik denetimi
    var isFormValid: Bool {
        quantity > 0 && unitPrice > 0
    }
    
    /// Saves the transaction to the SwiftData database
    /// İşlemi SwiftData veritabanına kaydeder
    func addInvestmentTransaction(context: ModelContext, assets: [InvestmentAsset]) {
        // First, check if the user has an "Investment Wallet (Main Table - Asset)" of the relevant type (e.g., Gram Gold)
        // Öncelikle kullanıcının ilgili türdeki (örn: Gram Altın) "Yatırım Cüzdanı (Ana Tablo - Asset)" var mı kontrol et
        var asset = assets.first(where: { $0.assetType == selectedAssetType })
        
        // If they do not have a wallet of that type, the system creates a new and empty wallet (InvestmentAsset)
        // Eğer o türde cüzdanı yoksa, sistem yeni ve boş bir cüzdan (InvestmentAsset) oluşturur
        if asset == nil {
            let newAsset = InvestmentAsset(assetType: selectedAssetType)
            context.insert(newAsset)
            asset = newAsset
        }
        
        guard let asset = asset else { return }
        
        // Add the transaction (buy/sell receipt) into the specified wallet
        // Belirtilen cüzdanın içine, hareketi (alım/satım fişini) ekle
        let transaction = InvestmentTransaction(
            asset: asset,
            type: selectedTransactionType,
            quantity: quantity,
            unitPriceTRY: unitPrice,
            date: date,
            note: note
        )
        context.insert(transaction) // Add the new transaction to SwiftData / Yeni işlemi SwiftData'ya al
        
        // Calculate the total cost and quantity calculations of the actual asset by calling from relevant model (WAC update)
        // Asıl varlığın toplam maliyet ve miktar hesaplamalarını ilgili modelden çağırarak yap (WAC update)
        switch selectedTransactionType {
        case .buy:
            asset.addBuyTransaction(quantity: quantity, unitPrice: unitPrice)
        case .sell:
            asset.addSellTransaction(quantity: quantity)
        }
        
        // After the relevant update and addition is finished, persist it to disk permanently
        // İlgili güncelleme ve ekleme bittikten sonra tam anlamıyla diske kalıcı kez kaydet
        try? context.save()
        resetForm()
    }
    
    /// Deletes an "Investment Wallet / Asset" table entirely. (Transactions inside are deleted via Cascade)
    /// Bir "Yatırım Cüzdanı / Varlığı" tablosunu tümüyle siler. (İçerisindeki transactionlar Cascade sayesinde silinir)
    func deleteAsset(_ asset: InvestmentAsset, context: ModelContext) {
        context.delete(asset)
        try? context.save()
    }
    
    /// Resets form content to its initial state for the next transaction
    /// Form içeriğini bir sonraki işlem için ilk haline sıfırlar
    func resetForm() {
        quantityText = ""
        unitPriceText = ""
        note = ""
        date = Date()
        selectedTransactionType = .buy
    }
    
    /// Returns the unrealized (Unrealized P/L) profit/loss coefficient of the asset in percentage
    /// Varlığın gerçekleşmemiş (Unrealized P/L) kar zararı katsayısını yüzdelik cinsinden döndürür
    func plPercentage(asset: InvestmentAsset, currentPrice: Double) -> Double {
        // Profit rate cannot be mentioned if there is no weighted average
        // Eğer ağırlıklı ortalama yoksa kar oranından bahsedilemez
        guard asset.weightedAverageCost > 0 else { return 0 }
        
        // (Current - Cost) / Cost x 100 Mathematical operation
        // (Bugünkü - Maliyet) / Maliyet x 100 Matematik işlemi
        return ((currentPrice - asset.weightedAverageCost) / asset.weightedAverageCost) * 100
    }
}
