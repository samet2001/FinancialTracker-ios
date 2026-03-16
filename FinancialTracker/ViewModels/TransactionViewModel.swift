//
//  TransactionViewModel.swift
//  FinancialTracker
//

import Foundation
import SwiftData
import SwiftUI
import Observation

/// Class managing the processes of adding, deleting, and listing income and expense transactions
/// Gelir ve Gider işlemlerinin eklenmesi, silinmesi ve listelenmesi süreçlerini yöneten sınıf
@Observable
class TransactionViewModel {
    
    // State values in the new addition (AddTransactionView) form
    // Yeni ekleme (AddTransactionView) formundaki state değerleri
    var selectedType: TransactionType = .expense
    var selectedCategory: TransactionCategory = .grocery
    var title: String = ""
    var amountText: String = "" // Stored as String to allow decimal keyboard input with comma (,) / Klavye ondalık girdi (,) izin versin diye string tutulur
    var note: String = ""
    var date: Date = Date()
    
    /// Computed value that converts the comma-formatted input in the form to the dot required by the Swift system
    /// Formdaki virgüllü formatı Swift sisteminin gereksinimi olan noktaya dönüştüren hesaplanmış değer
    var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    /// Minimum form validation requirement to be able to save (Title not empty, amount > 0)
    /// Kayıt yapabilmek için gerekli minimum form geçerlilik şartı (Başlık dolu, tutar > 0)
    var isFormValid: Bool {
        !title.isEmpty && amount > 0
    }
    
    /// Adds a new income/expense transaction (Transaction) to the database via SwiftData
    /// SwiftData üzerinden veritabanına yeni bir gelir/gider işlemi (Transaction) ekler
    func addTransaction(context: ModelContext) {
        let transaction = Transaction(
            title: title,
            amount: amount,
            category: selectedCategory,
            type: selectedType,
            date: date,
            note: note
        )
        // Add to the in-memory container
        // Bellekteki container'a ekle
        context.insert(transaction)
        // Persist to disk
        // Diske kalıcı olarak kaydet
        try? context.save()
        // Clear the form for the next entry
        // Sonraki işlem için formu boşalt
        resetForm()
    }
    
    /// Permanently deletes the given transaction from the database
    /// Verilen işlemi veritabanından kalıcı olarak siler
    func deleteTransaction(_ transaction: Transaction, context: ModelContext) {
        context.delete(transaction)
        try? context.save()
    }
    
    /// Resets the record form (returns to default values)
    /// Kayıt formunu sıfırlar (Varsayılan değerlere döndürür)
    func resetForm() {
        title = ""
        amountText = ""
        note = ""
        date = Date()
        selectedType = .expense
        selectedCategory = .grocery
    }
    
    /// Groups transactions by "Month and Year" format such as "December 2025".
    /// İşlemleri (Transaction) "Aralık 2025" gibi (Ay ve Yıl) formatına göre gruplar.
    /// Used to display month by month inside a List on the UI side.
    /// UI tarafında List içerisinde ay ay göstermek için kullanılır.
    func groupedByMonth(transactions: [Transaction]) -> [(String, [Transaction])] {
        let sorted = transactions.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { $0.date.formattedMonthYear }
        // Convert to Tuple structure to sort Dictionary's complex indexing order by date
        // Tuple yapısına çevirerek Dictionary'nin karmaşık dizinlenme sırasını tarihe göre dizeriz
        return grouped.sorted { pair1, pair2 in
            guard let d1 = pair1.value.first?.date, let d2 = pair2.value.first?.date else { return false }
            return d1 > d2
        }
    }
    
    /// Summarizes expenses by their categories for the Pie Chart in the Reports section
    /// Raporlar kısmındaki Pasta Grafik (Pie Chart) için giderleri kategorilerine göre özetler
    func expensesByCategory(transactions: [Transaction]) -> [(category: TransactionCategory, total: Double)] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { $0.category } // Each category becomes a key / Her bir kategori key olur
        // Converts Category -> [Expense, Expense] structure to Category -> "Total Amount" structure and assigns to array
        // Kategori -> [Harcama, Harcama] yapısını, Kategori -> "Toplam Tutar" yapısına çevirip diziye atar
        return grouped.map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total } // Sort from highest to lowest spending / En fazla harcanandan en aza doğru sırala
    }
    
    /// Extracts the last "6-month" financial trend for the Line Chart in the Reports section
    /// Raporlar kısmındaki Çizgi Grafiği (Line Chart) için son "6 aylık" finansal eğilim (trend) çıkarır
    func monthlyTotals(transactions: [Transaction]) -> [(month: String, income: Double, expense: Double)] {
        let calendar = Calendar.current
        var results: [(month: String, income: Double, expense: Double)] = []
        
        // Iterate the last 6 months backwards (must be reversed since we'll arrange from oldest to newest)
        // Son 6 ayı geriye doğru dön (Tarihi eski olandan yeniye doğru dizeceğinden i in 0..<6 reversed olmalı)
        for i in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let startOfMonth = monthDate.startOfMonth
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { continue }
            
            // Filter all transactions falling in that month (startOfMonth <= date < endOfMonth)
            // O aya düşen tüm işlemleri süzgeçten geçir (startOfMonth <= tarih < endOfMonth)
            let monthTransactions = transactions.filter { $0.date >= startOfMonth && $0.date < endOfMonth }
            
            // Total income for the month
            // Ayın toplam gelirleri
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            
            // Total expenses for the month
            // Ayın toplam giderleri
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            // Create a short month name to display on screen (Jul, Aug, Sep, etc.)
            // Ekranda gösterilecek kısa ay ismi oluştur (Tem, Ağu, Eyl vb)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            formatter.locale = Locale(identifier: "tr_TR")
            let monthName = formatter.string(from: monthDate)
            
            results.append((month: monthName, income: income, expense: expense))
        }
        
        return results
    }
}
