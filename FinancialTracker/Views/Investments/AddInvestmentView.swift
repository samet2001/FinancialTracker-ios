//
//  AddInvestmentView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Alım-Satım (Yatırım/Döviz/Altın) Fişi veya Hareketi kaydedebilmek için form menüsü.
struct AddInvestmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Popup sayfanın kapatılmasını tetikler
    @Query private var assets: [InvestmentAsset] // Tüm cüzdanları belleğe alıyoruz (Kontrol için)
    @Bindable var viewModel: InvestmentViewModel // Arkaplan kontrolü için (Ağırlıklı Ortalama Maliyet - WAC) ViewModel
    
    // Sayfanın bağımsız şekilde CANLI KUR TAHMİNİ gösterebilmesi için Servis
    var exchangeService: ExchangeRateService
    
    var body: some View {
        NavigationStack {
            Form {
                // İşlem Türü (Alış veya Satış)
                Section {
                    Picker("İşlem Türü", selection: $viewModel.selectedTransactionType) {
                        ForEach(InvestmentTransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type) // Örn: Mavi Arka plan üzerine beyaz buton oluşturur segmentte
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Varlık Türü (Dolar / Euro / Altın) Seçici
                Section("Varlık Türü") {
                    Picker("Varlık", selection: $viewModel.selectedAssetType) {
                        ForEach(AssetType.allCases) { assetType in
                            HStack {
                                Text(assetType.symbol)
                                Text(assetType.displayName)
                            }
                            .tag(assetType)
                        }
                    }
                    .pickerStyle(.menu) // Açılır standart sistem menüsü stili (Tıklanıp aşağı sarkar)
                }
                
                // Adet & Kur Bilgi Sistemi (Fiyat Tutar Alanları)
                Section("Miktar ve Fiyat") {
                    // Adet (Satın Alınan Miktar: 1.5 gibi)
                    HStack {
                        Text("Miktar")
                        Spacer()
                        TextField("0", text: $viewModel.quantityText)
                            // Türkçe için nokta/virgül karmaşasını engellemek adına ondalık sistem klavyesi açılır
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        // Kılavuz Birim (Sondayı örn: USD ise -> $)
                        Text(viewModel.selectedAssetType.unit)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Alım Kur'u / Birim Fiyat (Olay yeri için anlık) TL Tarafı
                    HStack {
                        Text("Birim Fiyat (₺)")
                        Spacer()
                        TextField("0", text: $viewModel.unitPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // İşlemi Hızlandırıcı Kısayol: Eğer kullanıcı fiyat bilmiyorsa, tıklanabilir bir şekilde 
                    // internetten çektiğimiz canlı kura hızlı bağlayan uyarı çıkarılır.
                    let currentPrice = exchangeService.currentPrice(for: viewModel.selectedAssetType)
                    if currentPrice > 0 {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("Güncel piyasa fiyatı:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            // Bu alt butona basılırsa o anki kur hızlıca form'daki UnitPrice kısmına işlenir
                            Button(currentPrice.formattedCurrency) {
                                viewModel.unitPriceText = String(format: "%.2f", currentPrice)
                            }
                            .font(.caption.bold())
                        }
                    }
                    
                    // İşlemi eskiye dönük oluşturmak için sistem tarih seçici bileşeni
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR")) // Cihaz formatını Türkçe'ye ayarlarız
                }
                
                // Varlık miktar × Birim fiyat sonucunu canli sekilde "Toplam Ciro" alanında hesaplayarak çıkar ve ön izleme sağlar
                if viewModel.quantity > 0 && viewModel.unitPrice > 0 {
                    Section("Toplam") {
                        HStack {
                            Text("Toplam Tutar")
                                .bold()
                            Spacer()
                            Text((viewModel.quantity * viewModel.unitPrice).formattedCurrency)
                                .font(.headline)
                                .foregroundStyle(Color.accentGradientStart) // Temel konsept mavi renk
                        }
                    }
                }
                
                // İsteğe bağlı not paneli
                Section("Not (Opsiyonel)") {
                    TextField("Açıklama ekleyin...", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Yeni Yatırım")
            .navigationBarTitleDisplayMode(.inline) // Alanı küçültür geniş boşluklar oluşmaz
            .toolbar {
                // Formu iptal etmek / çıkış
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                // Formu Kaydetmek ve işlemek / onay
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        // İş mantığını SwiftData ortamıyla beraber execute ettirir ve form kapatılır
                        viewModel.addInvestmentTransaction(context: modelContext, assets: assets)
                        dismiss()
                    }
                    // Miktar ve kur gibi zorunlu alanlar bos oldugu surece sisteme hatali giris yapilmasini engllemek icin
                    .disabled(!viewModel.isFormValid)
                    .bold()
                }
            }
        }
    }
}

#Preview {
    AddInvestmentView(viewModel: InvestmentViewModel(), exchangeService: ExchangeRateService())
        .modelContainer(for: [InvestmentAsset.self, InvestmentTransaction.self], inMemory: true)
}
