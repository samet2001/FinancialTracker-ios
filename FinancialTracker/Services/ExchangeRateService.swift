//
//  ExchangeRateService.swift
//  FinancialTracker
//

import Foundation
import Observation

// MARK: - Exchange Rate Response Models (Döviz Kuru API Yanıt Modelleri)
/// Model to decode JSON data returning from ExchangeRate-API
/// ExchangeRate-API'den dönen JSON verisini çözmek (decode) için model
struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
}

/// Model to decode JSON data returning from Frankfurter API (fallback api)
/// Frankfurter API'den (yedek api) dönen JSON verisini çözmek için model
struct FrankfurterResponse: Codable {
    let rates: [String: Double]
}

// MARK: - Market Prices (Piyasa Fiyatları)
/// Structure holding instant or last cached exchange rates to be used in the application
/// Uygulamada kullanılacak olan anlık veya en son önbelleklenen kurları tutan yapı
struct MarketPrices {
    var usdTry: Double // 1 Dollar -> TRY / 1 Dolar -> TL
    var eurTry: Double // 1 Euro -> TRY / 1 Euro -> TL
    var goldGramTry: Double // 1 Gram Gold -> TRY / 1 Gram Altın -> TL
    var lastUpdated: Date // Date when data was last received / Verinin en son alındığı tarih
    
    /// Initial (placeholder) version to be shown on waiting screens
    /// Bekleme ekranlarında gösterilecek başlangıç (boş) versiyonu
    static let placeholder = MarketPrices(
        usdTry: 0,
        eurTry: 0,
        goldGramTry: 0,
        lastUpdated: Date()
    )
}

// MARK: - Exchange Rate Service (Kur Servisi)
/// Service class that fetches exchange rates from the internet, caches, and provides them throughout the application
/// Uygulama genelinde kurları internetten çeken, önbellekleyen (cache) ve sunan servis sınıfı
/// Defined with @Observable so it can be read and reacted to instantly by Views
/// @Observable ile tanımlandığı için Views tarafından anında okunup tepki verilebilir
@Observable
class ExchangeRateService {
    var marketPrices: MarketPrices = .placeholder
    var isLoading = false
    var errorMessage: String?
    
    // Variables held for caching mechanism
    // Önbellek mekanizması için tutulan değişkenler
    private var cachedPrices: MarketPrices? // Last successful request / Son başarılı istek
    private var lastFetchTime: Date? // Date of last request / Son istek tarihi
    private let cacheInterval: TimeInterval = 900 // Do not make a new request to the API for 15 minutes (to avoid limits) / 15 dakika boyunca API'ye yeni istek atmama (limitlere takılmamak için)
    
    // Gold calculation (via Cross Rate): Gram Gold (TRY) = (Ounce(USD) / 31.1035) * Dollar(TRY)
    // Static approximation value for Ounce gold for now:
    // Altın hesaplaması (Çapraz Kur üzerinden): Gram Altın (TL) = (Ons(USD) / 31.1035) * Dolar(TL)
    // Şimdilik Ons altın için statik yaklaştırma değeri:
    private let goldOunceUSD: Double = 2900.0
    private let gramsPerOunce: Double = 31.1035
    
    /// Fetches exchange rates from API or provides from cache.
    /// Runs on @MainActor async and in the main thread so as not to block the UI
    /// Döviz kurlarını API'den çeker veya önbellekten verir. 
    /// UI'ı bloke etmemesi için async ve @MainActor ile ana thead'de çalışır
    @MainActor
    func fetchRates() async {
        // If there is data in the cache and 15 minutes have not passed yet, do not make a new request (Cache)
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
            // Fetch all exchange rates based on USD from the main API (Primary API)
            // Ana API'den USD bazıyla tüm kurları çek (Primary API)
            let rates = try await fetchFromPrimaryAPI()
            
            // Fetch USD/TRY rate / USD/TRY kurunu çek
            let usdTry = rates["TRY"] ?? 0
            
            // Calculate EUR/TRY rate via EUR/USD cross
            // EUR/TRY kurunu, EUR/USD çaprazı üzerinden hesapla
            let eurUsd = 1.0 / (rates["EUR"] ?? 1.0)
            let eurTry = eurUsd * usdTry
            
            // Calculate gram gold TRY price / Gram altın TL fiyatını hesapla
            let goldGramTry = (goldOunceUSD / gramsPerOunce) * usdTry
            
            let prices = MarketPrices(
                usdTry: usdTry,
                eurTry: eurTry,
                goldGramTry: goldGramTry,
                lastUpdated: Date()
            )
            
            // Update and publish cache if successful
            // Başarılı olursa önbelleği güncelle ve yayınla
            marketPrices = prices
            cachedPrices = prices
            lastFetchTime = Date()
            isLoading = false
        } catch {
            // If the first API gives an error (e.g., limit or server crash), consult the Fallback API
            // İlk API hata verirse (örn: limit veya sunucu çökmesi), Yedek (Fallback) API'ye başvur
            do {
                let rates = try await fetchFromFallbackAPI()
                let usdTry = rates["TRY"] ?? 0
                let goldGramTry = (goldOunceUSD / gramsPerOunce) * usdTry
                
                let prices = MarketPrices(
                    usdTry: usdTry,
                    eurTry: 0, // Frankfurter base is EUR, EUR calculation is different in USD-TRY conversion, so 0 for now / Frankfurter base EUR olduğu için USD-TRY dönüşümünde EUR hesaplaması farklı, bu yüzden şimdilik 0
                    goldGramTry: goldGramTry,
                    lastUpdated: Date()
                )
                
                marketPrices = prices
                cachedPrices = prices
                lastFetchTime = Date()
                isLoading = false
            } catch {
                // Reflect the error on the screen if both APIs fail
                // Her iki API de çökerse hatayı ekrana yansıt
                errorMessage = "Fiyat verileri alınamadı. Lütfen internet bağlantınızı kontrol edin."
                isLoading = false
            }
        }
    }
    
    /// Returns the live market current TRY exchange rate for whichever asset type is sent
    /// Hangi varlık türü gönderilirse, onun canlı piyasa güncel TL kurunu döndürür
    func currentPrice(for assetType: AssetType) -> Double {
        switch assetType {
        case .goldGram: return marketPrices.goldGramTry
        case .usd: return marketPrices.usdTry
        case .eur: return marketPrices.eurTry
        }
    }
    
    // MARK: - Private API Calls (Gizli Yardımcı Fonksiyonlar)
    
    /// HTTP Request via the primary source (ExchangeRate-API)
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
    
    /// HTTP Request via the secondary source (Frankfurter API) (Fallback)
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
