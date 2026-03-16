//
//  Extensions.swift
//  FinancialTracker
//

import Foundation
import SwiftUI

// MARK: - Double Formatter (Sayısal Formatlayıcılar)
/// Extensions that make monetary and numerical (quantity etc.) decimal numbers readable in the UI
/// Parasal ve rakamsal (adet vb.) ondalık sayıları UI'de okunur hale getiren eklentiler
extension Double {
    /// Used to format currency as Turkish Lira (e.g., ₺2.300,50)
    /// Para birimini Türk Lirası olarak (₺2.300,50 vb.) formatlamak için kullanılır
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY" // Always use Turkish Lira / Her zaman Türk Lirası birimini kullan
        formatter.currencySymbol = "₺"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2 // At least 2 decimal places / En az 2 kuruş hanesi
        formatter.maximumFractionDigits = 2 // At most 2 decimal places / En fazla 2 kuruş hanesi
        
        return formatter.string(from: NSNumber(value: self)) ?? "₺0,00"
    }
    
    /// A simple format adjusted according to how much it will extend after the comma (e.g., Gold gr calculations)
    /// Sayfa içinde virgülden sonra ne kadar uzayacağına göre ayarlanan basit bir format (Örn: Altın gr hesapları)
    var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4 // For precision (Crypto, Gram, etc.) / Has hassasiyeti için (Kripto, Gram vs.)
        
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

// MARK: - Date Formatter (Tarih Formatlayıcılar)
/// Date operations and time extensions
/// Tarih işlemleri ve zaman eklentileri
extension Date {
    /// To find the 1st day of the transaction's own month (very necessary for monthly total reports etc.)
    /// İşlemin kendi ayının 1. gününü bulmak için (Aylık toplam raporlar vb. için çok gerekli)
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Displays Turkish month/year names like "Ocak 2025" for list grouping on screen
    /// Ekranda liste gruplandırması "Ocak 2025" gibi Türkçe ay/yıl isimlerini gösterir
    var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    /// Short versions of specific transactions like "20 Eyl 2025"
    /// Belirli işlemlerin "20 Eyl 2025" şeklindeki kısa halleri
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    /// To show when the exchange rate API was updated in hour:minute format
    /// Döviz kuru API'sinin ne zaman yenilendiğini saat:dakika şeklinde göstermek için
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
}

// MARK: - Color System (Renk Sistemi)
/// Color catalog defined for consistency throughout the interface
/// Arayüz genelinde tutarlılık olması için tanımlanan renk kataloğu
extension Color {
    // Basic red-green tones used in money direction and charts
    // Para yönü ve grafiklerde kullanılan temel kırmızı-yeşil tonları
    static let incomeGreen = Color(red: 0.20, green: 0.78, blue: 0.35) // Income, Profit / Gelir, Kar
    static let expenseRed = Color(red: 1.0, green: 0.23, blue: 0.19)   // Expense, Loss / Gider, Zarar
    static let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)   // Gold / Altın
    
    // Application concept color (e.g., Menu bars)
    // Uygulama konsept rengi (Örn. Menü barları)
    static let accentGradientStart = Color(red: 0.20, green: 0.40, blue: 0.90)
    static let accentGradientEnd = Color(red: 0.40, green: 0.60, blue: 0.95)
    
    // Encoder from category color name (`systemGreen` etc.) coming from database to SwiftUI Color
    // Veritabanından gelen kategori renk ismini (`systemGreen` vb.) SwiftUI Color'a kodlayıcı
    static func categoryColor(_ name: String) -> Color {
        switch name {
        case "systemGreen": return .green
        case "systemOrange": return .orange
        case "systemBlue": return .blue
        case "systemYellow": return .yellow
        case "systemPurple": return .purple
        case "systemRed": return .red
        case "systemPink": return .pink
        case "systemTeal": return .teal
        case "systemIndigo": return .indigo
        case "systemMint": return .mint
        case "systemCyan": return .cyan
        case "systemGray": return .gray
        default: return .gray
        }
    }
}

// MARK: - View Modifiers (Bileşen Araçları - SwiftUI Custom UI)
/// Box-shaped card views with shadows around (Especially Dashboard and Investment List)
/// Kutu şeklinde etrafta gölgeli kart görünümleri (Özellikle Dashboard ve Yatırım Listesi)
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

/// Main polished gradient color (Net Asset / Total Portfolio) vision cards
/// Ana parlatılmış renk geçişli (Net Varlık / Toplam Portföy) vizyon kartları
struct GradientCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.accentGradientStart, Color.accentGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.accentGradientStart.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

extension View {
    /// Facilitator to apply standard white/black shadowed card view (.cardStyle() extension)
    /// Standart beyaz/siyah gölgeli kart görünümünü uygulamak için kolaylaştırıcı(.cardStyle() eklentisi)
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    /// Facilitator to apply large gradient card view (.gradientCard() extension)
    /// Büyük renk geçişli degrade kart görünümünü uygulamak için (.gradientCard() eklentisi)
    func gradientCard() -> some View {
        modifier(GradientCardModifier())
    }
}
