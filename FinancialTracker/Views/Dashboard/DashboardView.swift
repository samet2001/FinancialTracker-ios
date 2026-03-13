//
//  DashboardView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Uygulamanın ana özet ekranı. Nakit, yatırım, son işlemler ve piyasa verisini bir araya getirir.
struct DashboardView: View {
    // Veritabanı işlemleri
    @Environment(\.modelContext) private var modelContext
    // İşlemleri yeniden eskiye sorgula
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    // Yatırım cüzdanlarını sorgula
    @Query private var assets: [InvestmentAsset]
    
    // View modelleri ve servis sınıfının State üzerinden tanımlanmaları
    @State private var viewModel = DashboardViewModel()
    @State private var exchangeService = ExchangeRateService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Aşağı doğru dikey bileşenleri sırayla gösteriyoruz
                VStack(spacing: 16) {
                    netWorthCard              // Toplam Varlık Alanı
                    marketPricesSection       // Canlı Piyasa Kurları
                    monthlySummarySection     // İçinde Bulunan Ayın Özeti
                    quickStatsRow             // Toplam Gelir ve Gider İstatislikleri
                    recentTransactionsSection // En Son Yapılan 5 İşlem
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Finans Asistanı") // Ana sayfa üst başlığı
            .refreshable {
                // Ekranda aşağı çekildiğinde canlı kurları güncelle
                await exchangeService.fetchRates()
            }
            .task {
                // İlk sayfa yüklenmesinde kurları çek
                await exchangeService.fetchRates()
            }
        }
    }
    
    // MARK: - Net Worth Card (Net Varlık Gösterge Paneli)
    private var netWorthCard: some View {
        VStack(spacing: 12) {
            Text("Toplam Varlık")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8)) // Yarı saydam beyaz okunurluk için
            
            // ViewModel üstünden hesaplanmış toplam kullanıcının nakti ve yatırımlarını gösterir
            Text(viewModel.totalNetWorth(
                transactions: transactions,
                assets: assets,
                exchangeService: exchangeService
            ).formattedCurrency)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Alt kısım: Nakit Bakiye, Yatırım, Kar-Zarar bölmeleri
            HStack(spacing: 20) {
                // 1. Nakit Bakiye
                VStack(spacing: 4) {
                    Text("Nakit Bakiye")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(viewModel.netBalance(transactions: transactions).formattedCurrency)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                
                // Ayırıcı dikey çizgi
                Divider()
                    .frame(height: 30)
                    .background(.white.opacity(0.3))
                
                // 2. Sadece Yatırımların canlı değeri
                VStack(spacing: 4) {
                    Text("Yatırım Değeri")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(viewModel.totalInvestmentValue(assets: assets, exchangeService: exchangeService).formattedCurrency)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                
                Divider()
                    .frame(height: 30)
                    .background(.white.opacity(0.3))
                
                // 3. Kar/Zarar Göstergesi
                VStack(spacing: 4) {
                    let pl = viewModel.totalUnrealizedPL(assets: assets, exchangeService: exchangeService)
                    Text("Kar/Zarar")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(pl.formattedCurrency)
                        .font(.subheadline.bold())
                        .foregroundStyle(pl >= 0 ? Color.green : Color.red)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .gradientCard() // Eklentilerden tanımlanan degrade geçişli kart görünümü
    }
    
    // MARK: - Market Prices (Canlı Kurlar Kartı)
    private var marketPricesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık ve son yenilenme saati
            HStack {
                Text("Anlık Piyasa")
                    .font(.headline)
                Spacer()
                if exchangeService.isLoading { // İstek sürüyorsa dönen çember
                    ProgressView()
                        .scaleEffect(0.8)
                } else { // İstek bittiyse en son güncellenme tarihini göster
                    Text(exchangeService.marketPrices.lastUpdated.formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Döviz türleri sıralaması yatay bir satırda
            HStack(spacing: 12) {
                marketPriceItem(
                    title: "USD/TRY",
                    value: exchangeService.marketPrices.usdTry,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                marketPriceItem(
                    title: "EUR/TRY",
                    value: exchangeService.marketPrices.eurTry,
                    icon: "eurosign.circle.fill",
                    color: .blue
                )
                
                marketPriceItem(
                    title: "Gram Altın",
                    value: exchangeService.marketPrices.goldGramTry,
                    icon: "bitcoinsign.circle.fill",
                    color: .goldColor
                )
            }
            
            // Eğer internet koparsa vb. sunucudan gelen API hata mesajı
            if let error = exchangeService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .cardStyle()
    }
    
    /// Döviz kurunun kutucuğunu şablon olarak ayarlayan tekrar kullanımlı arayüz bileşeni
    private func marketPriceItem(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value.formattedCurrency)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7) // Ekrana sığmazsa metni %30 kadar küçültür
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        // Kartın zemin rengini ikon renginin %10 şeffaflığıyla doldurarak hoş bir tema yaratıyoruz
        .background(color.opacity(0.1)) 
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Monthly Summary (Bulunulan Ayın Kartı)
    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bu Ay")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Ayın genel karı
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.incomeGreen)
                            .frame(width: 8, height: 8)
                        Text("Gelir")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(viewModel.currentMonthIncome(transactions: transactions).formattedCurrency)
                        .font(.title3.bold())
                        .foregroundStyle(Color.incomeGreen)
                }
                
                Spacer()
                
                // Ayın genel zararı
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Gider")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(Color.expenseRed)
                            .frame(width: 8, height: 8)
                    }
                    Text(viewModel.currentMonthExpense(transactions: transactions).formattedCurrency)
                        .font(.title3.bold())
                        .foregroundStyle(Color.expenseRed)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Quick Stats (Genel Toplamlar)
    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Toplam Gelir",
                value: viewModel.totalIncome(transactions: transactions).formattedCurrency,
                icon: "arrow.down.circle.fill",
                color: Color.incomeGreen
            )
            
            statCard(
                title: "Toplam Gider",
                value: viewModel.totalExpense(transactions: transactions).formattedCurrency,
                icon: "arrow.up.circle.fill",
                color: Color.expenseRed
            )
        }
    }
    
    /// Hızlı genel bakış için şablon fonksiyonu
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    // MARK: - Recent Transactions (Yakın Dönem Hareketler Listesi)
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son İşlemler")
                .font(.headline)
            
            // ViewModel içerisinden sadece en son 5 işlem alınır
            let recent = viewModel.recentTransactions(transactions: transactions)
            
            if recent.isEmpty {
                // İşlem yoksa boş alan
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Henüz işlem yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(recent, id: \.id) { transaction in
                    transactionRow(transaction) // İşlem hücresini ekle
                    // Aralarındaki ayırıcı çizgi: son işlemde çizilmesin
                    if transaction.id != recent.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }
    
    /// Kategori ikonlu tek bir harcama hareketi göstermek için UI (Kullanıcı Arayüzü) bileşeni
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundStyle(Color.categoryColor(transaction.category.color))
                .frame(width: 36, height: 36)
                // İkon arka planı kategori renginin %15 şeffaf hali
                .background(Color.categoryColor(transaction.category.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline.bold())
                Text(transaction.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .income ? "+" : "-")\(transaction.amount.formattedCurrency)")
                    .font(.subheadline.bold())
                    // Gelirse yeşil giderse kırmızı renk
                    .foregroundStyle(transaction.type == .income ? Color.incomeGreen : Color.expenseRed)
                Text(transaction.date.formattedShort) // Hangi tarihte olduğunu ekle
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
