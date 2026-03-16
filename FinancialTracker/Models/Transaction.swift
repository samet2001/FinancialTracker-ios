//
//  Transaction.swift
//  FinancialTracker
//

import Foundation
import SwiftData

// MARK: - Transaction Type (İşlem Türü)
/// Basic component indicating whether it is an income or an expense
/// Gelir mi gider mi olduğunu belirten temel bileşen
enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
    
    /// Turkish name to be shown in the user interface
    /// Kullanıcı arayüzünde gösterilecek Türkçe isim
    var displayName: String {
        switch self {
        case .income: return "Gelir"
        case .expense: return "Gider"
        }
    }
}

// MARK: - Transaction Category (İşlem Kategorisi)
/// Provides more detailed grouping of expenses or incomes
/// Harcama veya gelirlerin daha detaylı gruplandırılmasını sağlar
enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case salary = "salary"
    case rent = "rent"
    case grocery = "grocery"
    case bills = "bills"
    case transportation = "transportation"
    case food = "food"
    case entertainment = "entertainment"
    case health = "health"
    case education = "education"
    case freelance = "freelance"
    case investment = "investment"
    case other = "other"
    
    var id: String { rawValue }
    
    /// Turkish category name to appear in the interface
    /// Arayüzde görünecek olan Türkçe kategori ismi
    var displayName: String {
        switch self {
        case .salary: return "Maaş"
        case .rent: return "Kira"
        case .grocery: return "Market"
        case .bills: return "Fatura"
        case .transportation: return "Ulaşım"
        case .food: return "Yemek"
        case .entertainment: return "Eğlence"
        case .health: return "Sağlık"
        case .education: return "Eğitim"
        case .freelance: return "Serbest Gelir"
        case .investment: return "Yatırım"
        case .other: return "Diğer"
        }
    }
    
    /// Apple SF Symbols icon name for the related category
    /// İlgili kategoriye ait Apple SF Symbols ikon adı
    var icon: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .rent: return "house.fill"
        case .grocery: return "cart.fill"
        case .bills: return "doc.text.fill"
        case .transportation: return "car.fill"
        case .food: return "fork.knife"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    /// System name of the theme color belonging to the related category
    /// İlgili kategoriye ait tema renginin sistem adı
    var color: String {
        switch self {
        case .salary: return "systemGreen"
        case .rent: return "systemOrange"
        case .grocery: return "systemBlue"
        case .bills: return "systemYellow"
        case .transportation: return "systemPurple"
        case .food: return "systemRed"
        case .entertainment: return "systemPink"
        case .health: return "systemTeal"
        case .education: return "systemIndigo"
        case .freelance: return "systemMint"
        case .investment: return "systemCyan"
        case .other: return "systemGray"
        }
    }
}

// MARK: - Transaction Model (İşlem Modeli)
/// Basic income-expense model saved to the database with SwiftData
/// SwiftData ile veritabanına kaydedilen temel gelir-gider modeli
@Model
final class Transaction {
    var id: UUID // Unique identifier number / Benzersiz kimlik numarası
    var title: String // Transaction title (e.g., "A101 Shopping") / İşlem başlığı (örn: "A101 Alışverişi")
    var amount: Double // Amount / Tutar
    var categoryRaw: String // Category value stored in the database / Veritabanında saklanan kategori değeri
    var typeRaw: String // Type (income/expense) value stored in the database / Veritabanında saklanan tür (gelir/gider) değeri
    var date: Date // Transaction date / İşlem tarihi
    var note: String // Optional note / İsteğe bağlı not
    
    /// Converts to enum using the String value in the database
    /// Veritabanındaki String değeri kullanarak enum'a dönüştürür
    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    /// Converts to enum using the String value in the database
    /// Veritabanındaki String değeri kullanarak enum'a dönüştürür
    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
    
    init(
        title: String,
        amount: Double,
        category: TransactionCategory,
        type: TransactionType,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.typeRaw = type.rawValue
        self.date = date
        self.note = note
    }
}
