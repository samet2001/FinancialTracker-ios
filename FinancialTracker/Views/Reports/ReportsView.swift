//
//  ReportsView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Chart Data Models
/// Pasta grafiğinde göstereceğimiz kategori verileri için taşıyıcı yapı
struct CategoryChartData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let color: Color
}

/// Çizgi grafikte göstereceğimiz aylık gelir-gider verileri için taşıyıcı yapı
struct MonthlyChartData: Identifiable {
    let id = UUID()
    let month: String
    let income: Double
    let expense: Double
}

/// Raporlar ekranı, Swift Charts ile kullanıcının verilerini görselleştirir
struct ReportsView: View {
    // İşlemleri yeniden eskiye sorgulama
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    // View Model
    @State private var viewModel = TransactionViewModel()
    
    // Hangi grafik türünün (0: Pasta kategori, 1: Çizgi aylık) gösterileceğini tutar
    @State private var selectedChartType = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Grafik tipi seçimi (Segmented Control)
                    Picker("Grafik Türü", selection: $selectedChartType) {
                        Text("Harcama Dağılımı").tag(0)
                        Text("Aylık Trend").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // İşlem yoksa boş state gösteririz
                    if transactions.isEmpty {
                        emptyState
                    } else {
                        // Seçime göre ilgili grafik ve alt detay alanını göster
                        if selectedChartType == 0 {
                            expensePieChart
                            expenseLegend
                        } else {
                            monthlyLineChart
                            monthlyDetails
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Raporlar")
        }
    }
    
    // MARK: - Expense Pie Chart (Gider Pasta Grafiği)
    private var expensePieChart: some View {
        // ViewModel aracılığıyla giderleri kategorize ediyoruz
        let data = viewModel.expensesByCategory(transactions: transactions)
        
        let chartData = data.map { item in
            CategoryChartData(
                category: item.category.displayName,
                amount: item.total,
                color: Color.categoryColor(item.category.color)
            )
        }
        
        let totalExpense = data.reduce(0) { $0 + $1.total }
        
        return VStack(spacing: 12) {
            Text("Harcama Dağılımı")
                .font(.headline)
            
            // Gider kaydı yoksa uyarı çıkart
            if chartData.isEmpty {
                Text("Henüz gider kaydı yok")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            } else {
                // Pasta grafik çizimi (Swift Charts)
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Tutar", item.amount),
                        innerRadius: .ratio(0.6), // Ortasını boş bırakan donut stili
                        angularInset: 2 // Pasta dilimleri arası küçük boşluk payı
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                    .annotation(position: .overlay) {
                        // Yüzdelik hesaplama ve gösterim
                        let percent = totalExpense > 0 ? (item.amount / totalExpense * 100) : 0
                        // Sadece %5'ten büyük dilimlerde değeri yazıp karışıklığı engelliyoruz
                        if percent > 5 {
                            Text(String(format: "%.0f%%", percent))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 250)
                // Grafiğin tam ortasına toplam tutarı yazdıran background bileşeni
                .chartBackground { _ in
                    VStack {
                        Text("Toplam")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(totalExpense.formattedCurrency)
                            .font(.headline.bold())
                    }
                }
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Expense Legend (Gider Kategorileri Detayı)
    private var expenseLegend: some View {
        let data = viewModel.expensesByCategory(transactions: transactions)
        let totalExpense = data.reduce(0) { $0 + $1.total }
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Kategori Detayları")
                .font(.headline)
            
            ForEach(data, id: \.category) { item in
                HStack {
                    Circle()
                        .fill(Color.categoryColor(item.category.color))
                        .frame(width: 10, height: 10)
                    
                    Text(item.category.displayName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(item.total.formattedCurrency)
                        .font(.subheadline.bold())
                    
                    let percent = totalExpense > 0 ? (item.total / totalExpense * 100) : 0
                    Text(String(format: "(%.1f%%)", percent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 55, alignment: .trailing)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Monthly Line Chart (Aylık Çizgi Grafik)
    private var monthlyLineChart: some View {
        let data = viewModel.monthlyTotals(transactions: transactions)
        let chartData = data.map { item in
            MonthlyChartData(month: item.month, income: item.income, expense: item.expense)
        }
        
        return VStack(spacing: 12) {
            Text("Aylık Gelir-Gider Trendi")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("Yeterli veri yok")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(chartData) { item in
                        // Gelir çizgisi
                        LineMark(
                            x: .value("Ay", item.month),
                            y: .value("Tutar", item.income)
                        )
                        .foregroundStyle(Color.incomeGreen)
                        .symbol(Circle())
                        .interpolationMethod(.catmullRom) // Eğimi yumuşatır
                        
                        // Gelir çizgi altı dolgusu (AreaMark)
                        AreaMark(
                            x: .value("Ay", item.month),
                            y: .value("Tutar", item.income)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.incomeGreen.opacity(0.3), Color.incomeGreen.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        // Gider çizgisi
                        LineMark(
                            x: .value("Ay", item.month),
                            y: .value("Tutar", item.expense)
                        )
                        .foregroundStyle(Color.expenseRed)
                        .symbol(Circle())
                        .interpolationMethod(.catmullRom)
                        
                        // Gider çizgi altı dolgusu (AreaMark)
                        AreaMark(
                            x: .value("Ay", item.month),
                            y: .value("Tutar", item.expense)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.expenseRed.opacity(0.3), Color.expenseRed.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 250)
                // Y-eksenindeki değerlerin gösterimi (formatlı para birimi)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(doubleValue.formattedCurrency)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            
            // Çizgi Grafiği Açıklama Satırı (Legend)
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.incomeGreen)
                        .frame(width: 8, height: 8)
                    Text("Gelir")
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.expenseRed)
                        .frame(width: 8, height: 8)
                    Text("Gider")
                        .font(.caption)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Monthly Details (Aylık İstatistik Listesi)
    private var monthlyDetails: some View {
        let data = viewModel.monthlyTotals(transactions: transactions)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Aylık Özet")
                .font(.headline)
            
            // Ayları en azından yeniden eskiye çevirerek liste altına bas
            ForEach(Array(data.reversed()), id: \.month) { item in
                HStack {
                    Text(item.month)
                        .font(.subheadline.bold())
                        .frame(width: 40, alignment: .leading)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("+\(item.income.formattedCurrency)")
                            .font(.caption)
                            .foregroundStyle(Color.incomeGreen)
                        Text("-\(item.expense.formattedCurrency)")
                            .font(.caption)
                            .foregroundStyle(Color.expenseRed)
                    }
                    
                    let net = item.income - item.expense
                    Text(net.formattedCurrency)
                        .font(.subheadline.bold())
                        .foregroundStyle(net >= 0 ? Color.incomeGreen : Color.expenseRed)
                        .frame(width: 100, alignment: .trailing)
                }
                
                if item.month != data.first?.month {
                    Divider()
                }
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Rapor oluşturmak için veri gerekli")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            
            Text("İşlemler sekmesinden gelir ve gider ekledikten sonra\ngrafikleriniz burada görünecektir")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 80)
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
