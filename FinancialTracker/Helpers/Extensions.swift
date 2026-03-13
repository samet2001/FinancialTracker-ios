//
//  Extensions.swift
//  FinancialTracker
//

import Foundation
import SwiftUI

// MARK: - Double Formatter (Sayısal Formatlayıcılar)
/// Parasal ve rakamsal (adet vb.) ondalık sayıları UI'de okunur hale getiren eklentiler
extension Double {
    /// Para birimini Türk Lirası olarak (₺2.300,50 vb.) formatlamak için kullanılır
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY" // Her zaman Türk Lirası birimini kullan
        formatter.currencySymbol = "₺"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2 // En az 2 kuruş hanesi
        formatter.maximumFractionDigits = 2 // En fazla 2 kuruş hanesi
        
        return formatter.string(from: NSNumber(value: self)) ?? "₺0,00"
    }
    
    /// Sayfa içinde virgülden sonra ne kadar uzayacağına göre ayarlanan basit bir format (Örn: Altın gr hesapları)
    var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4 // Has hassasiyeti için (Kripto, Gram vs.)
        
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

// MARK: - Date Formatter (Tarih Formatlayıcılar)
/// Tarih işlemleri ve zaman eklentileri
extension Date {
    /// İşlemin kendi ayının 1. gününü bulmak için (Aylık toplam raporlar vb. için çok gerekli)
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Ekranda liste gruplandırması "Ocak 2025" gibi Türkçe ay/yıl isimlerini gösterir
    var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    /// Belirli işlemlerin "20 Eyl 2025" şeklindeki kısa halleri
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
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
/// Arayüz genelinde tutarlılık olması için tanımlanan renk kataloğu
extension Color {
    // Para yönü ve grafiklerde kullanılan temel kırmızı-yeşil tonları
    static let incomeGreen = Color(red: 0.20, green: 0.78, blue: 0.35) // Gelir, Kar
    static let expenseRed = Color(red: 1.0, green: 0.23, blue: 0.19)   // Gider, Zarar
    static let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)   // Altın
    
    // Uygulama konsept rengi (Örn. Menü barları)
    static let accentGradientStart = Color(red: 0.20, green: 0.40, blue: 0.90)
    static let accentGradientEnd = Color(red: 0.40, green: 0.60, blue: 0.95)
    
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
    /// Standart beyaz/siyah gölgeli kart görünümünü uygulamak için kolaylaştırıcı(.cardStyle() eklentisi)
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    /// Büyük renk geçişli degrade kart görünümünü uygulamak için (.gradientCard() eklentisi)
    func gradientCard() -> some View {
        modifier(GradientCardModifier())
    }
}
