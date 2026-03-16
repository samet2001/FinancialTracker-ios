//
//  AddTransactionView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Screen that enables recording a new Income or Expense move
/// Yeni bir Gelir veya Gider hareketi kaydedilmesini sağlayan ekran
struct AddTransactionView: View {
    // Database management access / Veritabanı yönetim erişimi
    @Environment(\.modelContext) private var modelContext
    // Access to closing button action / Kapatma butonu aksiyonuna erişim
    @Environment(\.dismiss) private var dismiss
    // Binding data to @Observable ViewModel / State özelliği taşıyan ViewModel'a veri bağlama (@Bindable)
    @Bindable var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationStack {
            // Standard Form structure for data entry / Veri girişi için standart Form yapısı
            Form {
                // Transaction Type Area (Income / Expense Segment) / İşlem Türü Alanı (Gelir / Gider Segmenti)
                Section {
                    Picker("İşlem Türü", selection: $viewModel.selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented) // Ensures it appears as two buttons side by side / Yan yana iki buton halinde görünmesini sağlar
                }
                
                // Main Details / Ana Detaylar
                Section("Detaylar") {
                    // Title of the move performed / Yapılan hareketin başlığı
                    TextField("Başlık", text: $viewModel.title)
                    
                    // Financial Magnitude (Amount) Field / Finansal Büyüklük (Tutar) Alanı
                    HStack {
                        Text("₺")
                            .foregroundStyle(.secondary)
                        TextField("Tutar", text: $viewModel.amountText)
                            // We open numeric comma keyboard to allow entry in Turkish format / Türkçe formatlı giriş yapılabilmesi için rakamsal virgüllü klavye aç tırırız
                            .keyboardType(.decimalPad)
                    }
                    
                    // User can select and set date from here if making a retroactive move / Geçmiş dönem bir hareket yapılıyorsa kullanıcı tarihi burdan seçip ayarlayabilir
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR")) // To force calendar language to Turkish / Takvim dilini Türkçe'ye zorlamak 
                }
                
                // Selectable Categories System / Seçilebilir Kategoriler Sistemi
                Section("Kategori") {
                    // Filter and show categories on screen according to type of transaction model (Income/Expense)
                    // İşlem modelinin tipine (Gelir/Gider) göre ekrandaki kategorileri filtrele ve göster
                    let categories: [TransactionCategory] = viewModel.selectedType == .income
                        ? [.salary, .freelance, .investment, .other]
                        : [.grocery, .rent, .bills, .transportation, .food, .entertainment, .health, .education, .other]
                    
                    // Listing categories in 3-column rows on the screen using flexible Grid (GridItem)
                    // Esnek Grid (GridItem) kullanarak kategorileri ekranda 3'lü kolonlar şeklinde listelemek
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Loop between categories / Kategorilerin arasında döngü yapmak
                        ForEach(categories) { category in
                            CategoryButton(
                                category: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                // Hold this in State at moment of selection / Seçilme anında State'de bunu tut
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Area for reminder or writing additional notes / Hatırlatma veya ek not yazma alanı
                Section("Not (Opsiyonel)") {
                    TextField("Açıklama ekleyin...", text: $viewModel.note, axis: .vertical) // Input extending downwards / Aşağı doğru uzayan input
                        .lineLimit(3) // Gives a box height of 3 lines as standard / Başlangıç olarak 3 satırlık kutu yüksekliği verir
                }
            }
            .navigationTitle("Yeni İşlem") // Page Form Title / Sayfa Form Başlığı
            // We use standard small title style bit to the top of the screen instead of large to prevent space constraints
            // Yerin darlığını engellemek için büyük değil Inline, yani ekranın üstüne bitişik küçük başlık stili kullanıyoruz
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel Screen - Top Left Button / Ekranı İptal et - Sol Üst Buton
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        // Resets entered data while exiting so that a clean screen comes next time / Çıkarken girilmiş verileri unuttu ki bi dahakine tertemiz ekran gelsin
                        viewModel.resetForm()
                        dismiss() // Close screen by sliding down / Ekranı alta kaydırarak kapat
                    }
                }
                
                // Save data (Save) - Top Right Button / Verileri kaydetme (Save) - Sağ üst Buton
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        // We write to Database using the logic and context / İş mantığı ile context'i kullanarak Database'e yazıyoruz
                        viewModel.addTransaction(context: modelContext)
                        dismiss() // Close screen by sliding down / Ekranı alta kaydırarak kapat
                    }
                    // Security condition to activate only if Amount and title are entered / Sadece Tutar ve başlık giriliyse aktif etme güvenlik koşulu
                    .disabled(!viewModel.isFormValid)
                    .bold() // Makes the button bold font / Butonu Kalın yazı tipine getirir
                }
            }
        }
    }
}

// MARK: - Category Button (Özel Kategori Seçim Butonu Komponenti)
/// Special UI tool turning options in the new transaction menu into clickable icon blocks
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
                    .lineLimit(1) // Show only single line even if name is very long / İsim çok uzunsa bile sadece tek satır göster
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            // If the category is clicked and active; we put a selection circle in its own color tone with 20% transparency behind it. Otherwise classic grey.
            // Eğer kategori tıklandıysa ve aktifse; arkasına %20 şeffaf kendi renk tonunda seçim halkası atıyoruz. Yoksa klasik gri.
            .background(
                isSelected
                    ? Color.categoryColor(category.color).opacity(0.2)
                    : Color(.systemGray6)
            )
            // Icon color is also adjusted as bright/pale according to activity in the same way
            // İkon rengi de aynı şekilde aktifliğe göre parlak/soluk ayarlanır
            .foregroundStyle(
                isSelected
                    ? Color.categoryColor(category.color)
                    : .secondary
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // Creating outer line border / Dış çizgi kenarlığı oluşturmak
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.categoryColor(category.color) : .clear,
                        lineWidth: 2 // Two pixel border / İki piksellik border
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
