//
//  AddTransactionView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Yeni bir Gelir veya Gider hareketi kaydedilmesini sağlayan ekran
struct AddTransactionView: View {
    // Veritabanı yönetim erişimi
    @Environment(\.modelContext) private var modelContext
    // Kapatma butonu aksiyonuna erişim
    @Environment(\.dismiss) private var dismiss
    // State özelliği taşıyan ViewModel'a veri bağlama (@Bindable)
    @Bindable var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationStack {
            // Veri girişi için standart Form yapısı
            Form {
                // İşlem Türü Alanı (Gelir / Gider Segmenti)
                Section {
                    Picker("İşlem Türü", selection: $viewModel.selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented) // Yan yana iki buton halinde görünmesini sağlar
                }
                
                // Ana Detaylar
                Section("Detaylar") {
                    // Yapılan hareketin başlığı
                    TextField("Başlık", text: $viewModel.title)
                    
                    // Finansal Büyüklük (Tutar) Alanı
                    HStack {
                        Text("₺")
                            .foregroundStyle(.secondary)
                        TextField("Tutar", text: $viewModel.amountText)
                            // Türkçe formatlı giriş yapılabilmesi için rakamsal virgüllü klavye aç tırırız
                            .keyboardType(.decimalPad)
                    }
                    
                    // Geçmiş dönem bir hareket yapılıyorsa kullanıcı tarihi burdan seçip ayarlayabilir
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR")) // Takvim dilini Türkçe'ye zorlamak 
                }
                
                // Seçilebilir Kategoriler Sistemi
                Section("Kategori") {
                    // İşlem modelinin tipine (Gelir/Gider) göre ekrandaki kategorileri filtrele ve göster
                    let categories: [TransactionCategory] = viewModel.selectedType == .income
                        ? [.salary, .freelance, .investment, .other]
                        : [.grocery, .rent, .bills, .transportation, .food, .entertainment, .health, .education, .other]
                    
                    // Esnek Grid (GridItem) kullanarak kategorileri ekranda 3'lü kolonlar şeklinde listelemek
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Kategorilerin arasında döngü yapmak
                        ForEach(categories) { category in
                            CategoryButton(
                                category: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                // Seçilme anında State'de bunu tut
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Hatırlatma veya ek not yazma alanı
                Section("Not (Opsiyonel)") {
                    TextField("Açıklama ekleyin...", text: $viewModel.note, axis: .vertical) // Aşağı doğru uzayan input
                        .lineLimit(3) // Başlangıç olarak 3 satırlık kutu yüksekliği verir
                }
            }
            .navigationTitle("Yeni İşlem") // Sayfa Form Başlığı
            // Yerin darlığını engellemek için büyük değil Inline, yani ekranın üstüne bitişik küçük başlık stili kullanıyoruz
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Ekranı İptal et - Sol Üst Buton
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        // Çıkarken girilmiş verileri unuttu ki bi dahakine tertemiz ekran gelsin
                        viewModel.resetForm()
                        dismiss() // Ekranı alta kaydırarak kapat
                    }
                }
                
                // Verileri kaydetme (Save) - Sağ üst Buton
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        // İş mantığı ile context'i kullanarak Database'e yazıyoruz
                        viewModel.addTransaction(context: modelContext)
                        dismiss() // Ekranı alta kaydırarak kapat
                    }
                    // Sadece Tutar ve başlık giriliyse aktif etme güvenlik koşulu
                    .disabled(!viewModel.isFormValid)
                    .bold() // Butonu Kalın yazı tipine getirir
                }
            }
        }
    }
}

// MARK: - Category Button (Özel Kategori Seçim Butonu Komponenti)
/// Yeni işlem menüsünde seçenekleri tıklanabilir ikon blokları şekline çeviren özel UI aracı
struct CategoryButton: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title3)
                Text(category.displayName)
                    .font(.caption2)
                    .lineLimit(1) // İsim çok uzunsa bile sadece tek satır göster
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            // Eğer kategori tıklandıysa ve aktifse; arkasına %20 şeffaf kendi renk tonunda seçim halkası atıyoruz. Yoksa klasik gri.
            .background(
                isSelected
                    ? Color.categoryColor(category.color).opacity(0.2)
                    : Color(.systemGray6)
            )
            // İkon rengi de aynı şekilde aktifliğe göre parlak/soluk ayarlanır
            .foregroundStyle(
                isSelected
                    ? Color.categoryColor(category.color)
                    : .secondary
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // Dış çizgi kenarlığı oluşturmak
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.categoryColor(category.color) : .clear,
                        lineWidth: 2 // İki piksellik border
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddTransactionView(viewModel: TransactionViewModel())
        .modelContainer(for: Transaction.self, inMemory: true)
}
