//
//  ExchangeRateService.swift
//  FinancialTracker
//

import Foundation
import Observation

// MARK: - Exchange Rate Response Models (Döviz Kuru API Yanıt Modelleri)
/// ExchangeRate-API'den dönen JSON verisini çözmek (decode) için model
struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
}

/// Frankfurter API'den (yedek api) dönen JSON verisini çözmek için model
struct FrankfurterResponse: Codable {
    let rates: [String: Double]
}

// MARK: - Market Prices (Piyasa Fiyatları)
/// Uygulamada kullanılacak olan anlık veya en son önbelleklenen kurları tutan yapı
struct MarketPrices {
    var usdTry: Double // 1 Dolar -> TL
    var eurTry: Double // 1 Euro -> TL
    var goldGramTry: Double // 1 Gram Altın -> TL
    var lastUpdated: Date // Verinin en son alındığı tarih
    
    /// Bekleme ekranlarında gösterilecek başlangıç (boş) versiyonu
    static let placeholder = MarketPrices(
        usdTry: 0,
        eurTry: 0,
        goldGramTry: 0,
        lastUpdated: Date()
    )
}

// MARK: - Exchange Rate Service (Kur Servisi)
/// Uygulama genelinde kurları internetten çeken, önbellekleyen (cache) ve sunan servis sınıfı
/// @Observable ile tanımlandığı için Views tarafından anında okunup tepki verilebilir
@Observable
class ExchangeRateService {
    var marketPrices: MarketPrices = .placeholder
    var isLoading = false
    var errorMessage: String?
    
    // Önbellek mekanizması için tutulan değişkenler
    private var cachedPrices: MarketPrices? // Son başarılı istek
    private var lastFetchTime: Date? // Son istek tarihi
    private let cacheInterval: TimeInterval = 900 // 15 dakika boyunca API'ye yeni istek atmama (limitlere takılmamak için)
    
    // Altın hesaplaması (Çapraz Kur üzerinden): Gram Altın (TL) = (Ons(USD) / 31.1035) * Dolar(TL)
    // Şimdilik Ons altın için statik yaklaştırma değeri:
    private let goldOunceUSD: Double = 2900.0
    private let gramsPerOunce: Double = 31.1035
    
    /// Döviz kurlarını API'den çeker veya önbellekten verir. 
    /// UI'ı bloke etmemesi için async ve @MainActor ile ana thead'de çalışır
    @MainActor
    func fetchRates() async {
        // Eğer önbellekte veri varsa ve henüz 15 dakika dolmadıysa, yeni istek atma (Cache)
        if let cached = cachedPrices,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheInterval {
            marketPrices = cached
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Ana API'den USD bazıyla tüm kurları çek (Primary API)
            let rates = try await fetchFromPrimaryAPI()
            
            // USD/TRY kurunu çek
            let usdTry = rates["TRY"] ?? 0
            
            // EUR/TRY kurunu, EUR/USD çaprazı üzerinden hesapla
            let eurUsd = 1.0 / (rates["EUR"] ?? 1.0)
            let eurTry = eurUsd * usdTry
            
            // Gram altın TL fiyatını hesapla
            let goldGramTry = (goldOunceUSD / gramsPerOunce) * usdTry
            
            let prices = MarketPrices(
                usdTry: usdTry,
                eurTry: eurTry,
                goldGramTry: goldGramTry,
                lastUpdated: Date()
            )
            
            // Başarılı olursa önbelleği güncelle ve yayınla
            marketPrices = prices
            cachedPrices = prices
            lastFetchTime = Date()
            isLoading = false
        } catch {
            // İlk API hata verirse (örn: limit veya sunucu çökmesi), Yedek (Fallback) API'ye başvur
            do {
                let rates = try await fetchFromFallbackAPI()
                let usdTry = rates["TRY"] ?? 0
                let goldGramTry = (goldOunceUSD / gramsPerOunce) * usdTry
                
                let prices = MarketPrices(
                    usdTry: usdTry,
                    eurTry: 0, // Frankfurter base EUR olduğu için USD-TRY dönüşümünde EUR hesaplaması farklı, bu yüzden şimdilik 0
                    goldGramTry: goldGramTry,
                    lastUpdated: Date()
                )
                
                marketPrices = prices
                cachedPrices = prices
                lastFetchTime = Date()
                isLoading = false
            } catch {
                // Her iki API de çökerse hatayı ekrana yansıt
                errorMessage = "Fiyat verileri alınamadı. Lütfen internet bağlantınızı kontrol edin."
                isLoading = false
            }
        }
    }
    
    /// Hangi varlık türü gönderilirse, onun canlı piyasa güncel TL kurunu döndürür
    func currentPrice(for assetType: AssetType) -> Double {
        switch assetType {
        case .goldGram: return marketPrices.goldGramTry
        case .usd: return marketPrices.usdTry
        case .eur: return marketPrices.eurTry
        }
    }
    
    // MARK: - Private API Calls (Gizli Yardımcı Fonksiyonlar)
    
    /// Birincil kaynak (ExchangeRate-API) üzerinden HTTP İsteği
    private func fetchFromPrimaryAPI() async throws -> [String: Double] {
        let url = URL(string: "https://api.exchangerate-api.com/v4/latest/USD")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        return decoded.rates
    }
    
    /// İkincil kaynak (Frankfurter API) üzerinden HTTP İsteği (Yedek)
    private func fetchFromFallbackAPI() async throws -> [String: Double] {
        let url = URL(string: "https://api.frankfurter.dev/v1/latest?base=USD&symbols=TRY")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        return decoded.rates
    }
}
