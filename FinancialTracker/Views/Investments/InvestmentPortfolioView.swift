//
//  InvestmentPortfolioView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// The page that lists the investment portfolio (all wallet balances and their statuses)
/// Yatırım portföyünü (Bütün cüzdan bakiyelerini ve durumlarını) listeleyen sayfa
struct InvestmentPortfolioView: View {
    @Environment(\.modelContext) private var modelContext
    // Fetches all assets (Gold, currencies, etc.) from the database
    // Veritabanındaki bütün varlıkları (Altın, döviz vb) çeker
    @Query private var assets: [InvestmentAsset]
    
    // Defining view models
    // View modellerin tanımlanması
    @State private var viewModel = InvestmentViewModel()
    @State private var exchangeService = ExchangeRateService()
    
    // Is the buy/sell transaction modal menu open?
    // Alım-Satım işlem modal menüsü açık mı?
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Main large card: Total Portfolio Value
                    // Ana büyük kart: Toplam Portfoy Değeri
                    portfolioSummaryCard
                    
                    // Warn if there are no assets or the investment tab is completely empty
                    // Eğer hiç varlık yoksa veya yatırım sekmesi bomboşsa uyar
                    if assets.isEmpty || assets.filter({ $0.totalQuantity > 0 }).isEmpty {
                        emptyStateView
                    } else {
                        // List owned assets (those with more than 0 in stock)
                        // Sahip olunan varlıkları (Elinde 0'dan fazla stoğu olanlar) Listele
                        ForEach(assets.filter { $0.totalQuantity > 0 }, id: \.id) { asset in
                            assetCard(asset)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Yatırımlar")
            .toolbar {
                // Top-right button for entering a new investment buy/sell transaction
                // Sağ üst yeni yatırım alım/satım hareketi giriş butonu
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                // Passing the live API rate service to the presented card
                // Çıkan karta mevcut canlı API kuru sevisini gönderiyoruz
                AddInvestmentView(viewModel: viewModel, exchangeService: exchangeService)
            }
            .task {
                // Fetch the latest exchange rates from the Internet (API) when the view loads for the first time
                // Görüntü ilk defa yüklendiğinde güncel kurları İnternetten iste (API)
                await exchangeService.fetchRates()
            }
            .refreshable {
                // When the screen is pulled down to refresh
                // Ekran kaydırılarak yenilendiğinde
                await exchangeService.fetchRates()
            }
        }
    }
    
    // MARK: - Portfolio Summary (Portföy Ana Özeti Kartı)
    private var portfolioSummaryCard: some View {
        VStack(spacing: 12) {
            Text("Portföy Değeri")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            
            // Calculates the overall current market TRY value of holdings (wallet) at current prices
            // Mevcut fiyatlarla eldekinin (Cüzdanın) genel piyasa anlık TRY Değer hesabı
            let totalValue = assets.reduce(0.0) { total, asset in
                let price = exchangeService.currentPrice(for: asset.assetType)
                return total + asset.currentValue(currentPriceTRY: price)
            }
            
            Text(totalValue.formattedCurrency)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Overall unrealized Profit & Loss (P&L) status of wallet investments at current prices
            // Mevcut fiyatlarla cüzdandaki yatırımların genel anlık Kar-Zarar (Gerçekleşmemiş P&L) durumu
            let totalPL = assets.reduce(0.0) { total, asset in
                let price = exchangeService.currentPrice(for: asset.assetType)
                return total + asset.unrealizedPL(currentPriceTRY: price)
            }
            
            HStack(spacing: 4) {
                Image(systemName: totalPL >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(totalPL.formattedCurrency)
                Text("Gerçekleşmemiş K/Z")
                    .opacity(0.7)
            }
            .font(.caption)
            // Display in green if P&L is positive, red if negative
            // K/Z Pozitifse Yeşil Tonda Negatif ise Kırmızı Yaza
            .foregroundStyle(totalPL >= 0 ? Color.green : Color.red)
        }
        .frame(maxWidth: .infinity)
        .gradientCard() // Elegant color gradient style inherited from extensions
        // Eklentilerden devralınan çok şık renk geçiş stili
    }
    
    // MARK: - Asset Card (Spesifik Varlık / Altın Detay Kartı)
    private func assetCard(_ asset: InvestmentAsset) -> some View {
        // Readings from the exchange rate service to feed the card
        // Kartı beslemek için kur servisinden okumalar
        let currentPrice = exchangeService.currentPrice(for: asset.assetType)
        let pl = asset.unrealizedPL(currentPriceTRY: currentPrice)
        let plPercent = viewModel.plPercentage(asset: asset, currentPrice: currentPrice)
        
        return VStack(spacing: 12) {
            // Header: Icon, Quantity and Total Price Information
            // Başlık: İkon, Miktar ve Toplam Fiyat Bilgileri
            HStack {
                Text(asset.assetType.symbol)
                    .font(.largeTitle) // E.g. "🪙" icon size / Örneğin "🪙" İkon büyüklüğü
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.assetType.displayName)
                        .font(.headline)
                    // Quantity on hand and unit, e.g. (18 gr)
                    // Eldeki Miktar ve birimi örnek (18 gr)
                    Text("\(asset.totalQuantity.formattedQuantity) \(asset.assetType.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary) // Semi-grey text style / Yarı-Gri yazı sitili
                }
                
                Spacer()
                
                // Right side: Asset's TRY value and P&L
                // Sağ taraf: Varlığın TL bazlı parası ve K/Z'si (Kürsat)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(asset.currentValue(currentPriceTRY: currentPrice).formattedCurrency)
                        .font(.headline)
                    HStack(spacing: 2) {
                        Image(systemName: pl >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(pl.formattedCurrency)
                    }
                    .font(.caption)
                    .foregroundStyle(pl >= 0 ? Color.incomeGreen : Color.expenseRed)
                }
            }
            
            Divider()
            
            // Card bottom info row: Avg. Cost, Price, P&L% Statistics
            // Kartın Alt Bilgi Satırı: Ort. Maliyet, Fiyat, Kar-Zarar% İstatistikleri
            HStack {
                // 1st Info Column (Avg. Cost)
                // 1. Bilgi Tüneli (Ort Maliyet)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ort. Maliyet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // Value known as Weighted Average Cost (WAC) in the market
                    // Piyasada Ağırlıklı Ortalama Maaliyet olarak adlandırılan değer (WAC)
                    Text(asset.weightedAverageCost.formattedCurrency)
                        .font(.subheadline.bold())
                }
                
                Spacer()
                
                // 2nd Info Column (Today's Instant Market Sell or Buy Price)
                // 2. Bilgi Tüneli (Bugünkü Anlık Piyasa Satış veya Alış Tutarı)
                VStack(alignment: .center, spacing: 2) {
                    Text("Güncel Fiyat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentPrice.formattedCurrency)
                        .font(.subheadline.bold())
                }
                
                Spacer()
                
                // 3rd Info Column (Percentage increase from initial capital)
                // 3. Bilgi Tüneli (Başlangış sermayesinden yüzdelik % bazda artış)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("K/Z %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f%%", plPercent))
                        .font(.subheadline.bold())
                        .foregroundStyle(pl >= 0 ? Color.incomeGreen : Color.expenseRed)
                }
            }
        }
        .cardStyle() // Standard flat card style extension / Standart düz kart stili eklentisi
    }
    
    // MARK: - Empty State (Boş Veri Hatırlaatıcı)
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Henüz yatırım yok")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            
            Text("İlk yatırımınızı eklemek için + butonuna tıklayın")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    InvestmentPortfolioView()
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
