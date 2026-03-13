//
//  TransactionListView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// İşlemler listesi ekranı, kullanıcının gelir ve giderlerini aylık olarak gruplanmış şekilde gösterir.
struct TransactionListView: View {
    // Veritabanı (SwiftData) bağlamı (context) üzerinden CRUD işlemleri yapılır.
    @Environment(\.modelContext) private var modelContext
    
    // İşlemleri tarihe göre yeniden eskiye doğru sıralı çekeriz.
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    // View'in iş mantığını yöneten ViewModel (@Observable mimarisi ile)
    @State private var viewModel = TransactionViewModel()
    
    // Yeni işlem ekleme sayfasını açıp kapamak için state
    @State private var showingAddSheet = false
    
    // Kullanıcının listeyi tümü/gelir/gider olarak filtrelemesi için tutulan filtre tipi
    @State private var filterType: TransactionType? = nil
    
    // Seçilen filtreye göre ekranda gösterilecek olan işlemler
    var filteredTransactions: [Transaction] {
        if let filter = filterType {
            return transactions.filter { $0.type == filter }
        }
        return Array(transactions)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtreleme Seçici (Segmented Picker)
                Picker("Filtre", selection: $filterType) {
                    Text("Tümü").tag(TransactionType?.none)
                    Text("Gelirler").tag(TransactionType?.some(.income))
                    Text("Giderler").tag(TransactionType?.some(.expense))
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Eğer filtrelenmiş hiç işlem yoksa, kullanıcıya boş state ekranı gösteriyoruz
                if filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Henüz işlem bulunmuyor")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Yeni işlem eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                } else {
                    // İşlemler varsa aylara göre gruplanıp List ile gösteriliyor
                    List {
                        let grouped = viewModel.groupedByMonth(transactions: filteredTransactions)
                        
                        ForEach(grouped, id: \.0) { month, monthTransactions in
                            // Her bir ay için Section (Kısım) oluşturuyoruz
                            Section {
                                ForEach(monthTransactions, id: \.id) { transaction in
                                    // Tekil işlem satırı
                                    TransactionRowView(transaction: transaction)
                                        // Sağa kaydırma ile silme işlemi yeteneği (swipe to delete)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                // İşlemi veritabanından kalıcı olarak sil
                                                viewModel.deleteTransaction(transaction, context: modelContext)
                                            } label: {
                                                Label("Sil", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                // Section Başlığı (Ay adı ve o ayın toplam net bakiyesi)
                                HStack {
                                    Text(month)
                                        .font(.headline)
                                    Spacer()
                                    // Ayın net bakiyesi hesabı (Gelirlerden giderleri çıkarma)
                                    let total = monthTransactions.reduce(0.0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
                                    Text(total.formattedCurrency)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(total >= 0 ? Color.incomeGreen : Color.expenseRed)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("İşlemler")
            .toolbar {
                // Yeni işlem (gelir/gider) ekleme butonu
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            // AddTransactionView ekranını modal olarak çağırma
            .sheet(isPresented: $showingAddSheet) {
                AddTransactionView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Transaction Row View
/// Listede tek bir işlemi (gelir/gider kaydını) gösteren alt bileşen
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Sol tarafta kategorinin ikonu
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundStyle(Color.categoryColor(transaction.category.color))
                .frame(width: 40, height: 40)
                .background(Color.categoryColor(transaction.category.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // İşlem başlığı, kategori adı ve tarih
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.body.bold())
                HStack(spacing: 4) {
                    Text(transaction.category.displayName)
                    Text("•")
                    Text(transaction.date.formattedShort)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Sağ tarafta miktar (gelirse +, giderse -)
            Text("\(transaction.type == .income ? "+" : "-")\(transaction.amount.formattedCurrency)")
                .font(.body.bold())
                .foregroundStyle(transaction.type == .income ? Color.incomeGreen : Color.expenseRed)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Transaction.self, InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
