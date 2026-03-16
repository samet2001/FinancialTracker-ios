//
//  AddInvestmentView.swift
//  FinancialTracker
//

import SwiftUI
import SwiftData

/// Form menu to record Buy-Sell (Investment/Currency/Gold) Receipt or Movement.
/// Alım-Satım (Yatırım/Döviz/Altın) Fişi veya Hareketi kaydedebilmek için form menüsü.
struct AddInvestmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Triggers closing the popup page / Popup sayfanın kapatılmasını tetikler
    @Query private var assets: [InvestmentAsset] // We take all wallets into memory (for control) / Tüm cüzdanları belleğe alıyoruz (Kontrol için)
    @Bindable var viewModel: InvestmentViewModel // ViewModel for background control (Weighted Average Cost - WAC) / Arkaplan kontrolü için (Ağırlıklı Ortalama Maliyet - WAC) ViewModel
    
    // Service for the page to independently display LIVE RATE PREDICTION
    // Sayfanın bağımsız şekilde CANLI KUR TAHMİNİ gösterebilmesi için Servis
    var exchangeService: ExchangeRateService
    
    var body: some View {
        NavigationStack {
            Form {
                // Transaction Type (Buy or Sell) / İşlem Türü (Alış veya Satış)
                Section {
                    Picker("İşlem Türü", selection: $viewModel.selectedTransactionType) {
                        ForEach(InvestmentTransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type) // E.g., creates white button on blue background in segment / Örn: Mavi Arka plan üzerine beyaz buton oluşturur segmentte
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Asset Type (Dollar / Euro / Gold) Selector / Varlık Türü (Dolar / Euro / Altın) Seçici
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
                    .pickerStyle(.menu) // Standard system dropdown menu style (clicks and drops down) / Açılır standart sistem menüsü stili (Tıklanıp aşağı sarkar)
                }
                
                // Quantity & Rate Information System (Price Amount Fields) / Adet & Kur Bilgi Sistemi (Fiyat Tutar Alanları)
                Section("Miktar ve Fiyat") {
                    // Quantity (Amount Purchased: such as 1.5) / Adet (Satın Alınan Miktar: 1.5 gibi)
                    HStack {
                        Text("Miktar")
                        Spacer()
                        TextField("0", text: $viewModel.quantityText)
                            // Decimal system keyboard opens to prevent point/comma confusion for Turkish / Türkçe için nokta/virgül karmaşasını engellemek adına ondalık sistem klavyesi açılır
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        // Guide Unit (Suffix e.g. if USD -> $) / Kılavuz Birim (Sondayı örn: USD ise -> $)
                        Text(viewModel.selectedAssetType.unit)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Purchase Rate / Unit Price (Instant for the scene) TRY side / Alım Kur'u / Birim Fiyat (Olay yeri için anlık) TL Tarafı
                    HStack {
                        Text("Birim Fiyat (₺)")
                        Spacer()
                        TextField("0", text: $viewModel.unitPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // Transaction Accelerator Shortcut: If the user doesn't know the price, an alert is issued that quickly connects to the live rate we pulled from the internet in a clickable way.
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
                            // If this sub-button is pressed, the instantaneous rate is quickly processed into the UnitPrice part in the form
                            // Bu alt butona basılırsa o anki kur hızlıca form'daki UnitPrice kısmına işlenir
                            Button(currentPrice.formattedCurrency) {
                                viewModel.unitPriceText = String(format: "%.2f", currentPrice)
                            }
                            .font(.caption.bold())
                        }
                    }
                    
                    // System date picker component to create the transaction retroactively
                    // İşlemi eskiye dönük oluşturmak için sistem tarih seçici bileşeni
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR")) // We set the device format to Turkish / Cihaz formatını Türkçe'ye ayarlarız
                }
                
                // Provides preview by calculating and displaying the asset quantity × Unit price result live in the "Total Turnover" area
                // Varlık miktar × Birim fiyat sonucunu canli sekilde "Toplam Ciro" alanında hesaplayarak çıkar ve ön izleme sağlar
                if viewModel.quantity > 0 && viewModel.unitPrice > 0 {
                    Section("Toplam") {
                        HStack {
                            Text("Toplam Tutar")
                                .bold()
                            Spacer()
                            Text((viewModel.quantity * viewModel.unitPrice).formattedCurrency)
                                .font(.headline)
                                .foregroundStyle(Color.accentGradientStart) // Basic concept blue color / Temel konsept mavi renk
                        }
                    }
                }
                
                // Optional note panel / İsteğe bağlı not paneli
                Section("Not (Opsiyonel)") {
                    TextField("Açıklama ekleyin...", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Yeni Yatırım")
            .navigationBarTitleDisplayMode(.inline) // Shrinks the area so wide gaps don't form / Alanı küçültür geniş boşluklar oluşmaz
            .toolbar {
                // Cancel form / exit / Formu iptal etmek / çıkış
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                // Save and process form / approval / Formu Kaydetmek ve işlemek / onay
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        // Executes the business logic together with the SwiftData environment and closes the form
                        // İş mantığını SwiftData ortamıyla beraber execute ettirir ve form kapatılır
                        viewModel.addInvestmentTransaction(context: modelContext, assets: assets)
                        dismiss()
                    }
                    // To prevent erroneous entry into the system as long as mandatory fields like Quantity and rate are empty
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
