//
//  DashboardView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// The application's main summary screen. It brings together cash, investment, recent transactions, and market data.
/// Uygulamanın ana özet ekranı. Nakit, yatırım, son işlemler ve piyasa verisini bir araya getirir.
struct DashboardView: View {
    // Database operations / Veritabanı işlemleri
    @Environment(\.modelContext) private var modelContext
    // Query transactions from newest to oldest / İşlemleri yeniden eskiye sorgula
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    // Query investment wallets / Yatırım cüzdanlarını sorgula
    @Query private var assets: [InvestmentAsset]
    
    // Definitions of view models and service class via State
    // View modelleri ve servis sınıfının State üzerinden tanımlanmaları
    @State private var viewModel = DashboardViewModel()
    @State private var exchangeService = ExchangeRateService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Showing vertical components in order downwards
                // Aşağı doğru dikey bileşenleri sırayla gösteriyoruz
                VStack(spacing: 16) {
                    netWorthCard              // Total Asset Area / Toplam Varlık Alanı
                    marketPricesSection       // Live Market Rates / Canlı Piyasa Kurları
                    monthlySummarySection     // Summary of Current Month / İçinde Bulunan Ayın Özeti
                    quickStatsRow             // Total Income and Expense Statistics / Toplam Gelir ve Gider İstatislikleri
                    recentTransactionsSection // Last 5 Transactions Performed / En Son Yapılan 5 İşlem
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Finans Asistanı") // Home page main title / Ana sayfa üst başlığı
            .refreshable {
                // Update live rates when pulled down on screen
                // Ekranda aşağı çekildiğinde canlı kurları güncelle
                await exchangeService.fetchRates()
            }
            .task {
                // Fetch rates on first page load
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
                .foregroundStyle(.white.opacity(0.8)) // For readability with semi-transparent white / Yarı saydam beyaz okunurluk için
            
            // Shows the total calculated net cash and investments of the user via ViewModel
            // ViewModel üstünden hesaplanmış toplam kullanıcının nakti ve yatırımlarını gösterir
            Text(viewModel.totalNetWorth(
                transactions: transactions,
                assets: assets,
                exchangeService: exchangeService
            ).formattedCurrency)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Bottom part: Cash Balance, Investment, Profit-Loss divisions
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
                
                // Vertical divider line / Ayırıcı dikey çizgi
                Divider()
                    .frame(height: 30)
                    .background(.white.opacity(0.3))
                
                // 2. Only the live value of investments / Sadece Yatırımların canlı değeri
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
                
                // 3. Profit/Loss Indicator / Kar/Zarar Göstergesi
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
        .gradientCard() // Gradient card view defined from extensions / Eklentilerden tanımlanan degrade geçişli kart görünümü
    }
    
    // MARK: - Market Prices (Canlı Kurlar Kartı)
    private var marketPricesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and last refresh time / Başlık ve son yenilenme saati
            HStack {
                Text("Anlık Piyasa")
                    .font(.headline)
                Spacer()
                if exchangeService.isLoading { // Spinning circle if request is ongoing / İstek sürüyorsa dönen çember
                    ProgressView()
                        .scaleEffect(0.8)
                } else { // Show last updated date if request finished / İstek bittiyse en son güncellenme tarihini göster
                    Text(exchangeService.marketPrices.lastUpdated.formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Exchange rate types arrangement in a horizontal row
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
            
            // API error message coming from server if internet is disconnected etc.
            // Eğer internet koparsa vb. sunucudan gelen API hata mesajı
            if let error = exchangeService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .cardStyle()
    }
    
    /// Reusable UI component that sets the exchange rate box as a template
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
                .minimumScaleFactor(0.7) // Shrinks the text by up to 30% if it doesn't fit on screen / Ekrana sığmazsa metni %30 kadar küçültür
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        // Creating a nice theme by filling the background color of the card with 10% transparency of the icon color
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
                // Monthly overall profit / Ayın genel karı
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
                
                // Monthly overall loss / Ayın genel zararı
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
    
    /// Template function for quick overview
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
            
            // Only the last 5 transactions are taken from inside the ViewModel
            // ViewModel içerisinden sadece en son 5 işlem alınır
            let recent = viewModel.recentTransactions(transactions: transactions)
            
            if recent.isEmpty {
                // Empty area if no transactions / İşlem yoksa boş alan
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
                    transactionRow(transaction) // Add transaction cell / İşlem hücresini ekle
                    // Separator line between them: don't draw on last transaction / Aralarındaki ayırıcı çizgi: son işlemde çizilmesin
                    if transaction.id != recent.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }
    
    /// UI (User Interface) component to show a single expense movement with category icon
    /// Kategori ikonlu tek bir harcama hareketi göstermek için UI (Kullanıcı Arayüzü) bileşeni
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundStyle(Color.categoryColor(transaction.category.color))
                .frame(width: 36, height: 36)
                // Icon background is 15% transparent version of category color / İkon arka planı kategori renginin %15 şeffaf hali
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
                    // Green if income, red if expense / Gelirse yeşil giderse kırmızı renk
                    .foregroundStyle(transaction.type == .income ? Color.incomeGreen : Color.expenseRed)
                Text(transaction.date.formattedShort) // Add which date it is / Hangi tarihte olduğunu ekle
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
