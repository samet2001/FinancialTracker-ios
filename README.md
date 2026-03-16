# Financial Tracker

A personal finance management iOS application built with **SwiftUI** and **SwiftData**. Financial Tracker helps you organize your expenses, track your income, monitor investments, and visualize your financial health through detailed reports.

## Features

- **Dashboard:** Get a quick overview of your balances, recent transactions, and key financial metrics at a glance.
- **Transaction Management:** Easily add, edit, or categorize your daily expenses and income.
- **Investments Tracker:** Keep an eye on your investment assets (e.g., stocks, crypto, real estate) and an integrated history of your investment deposits/withdrawals.
- **Interactive Reports:** Visualize your spending habits and financial growth over time with interactive charts.
- **Data Persistence:** Fully offline-capable using Apple's local **SwiftData** framework, ensuring privacy and speed.

## Architecture & Technologies

- **UI Framework:** SwiftUI
- **Database / Local Storage:** SwiftData
- **Design Pattern:** MVVM (Model-View-ViewModel)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+


## Directory Structure

- `Models`: Data structures and SwiftData entities (`Transaction`, `InvestmentAsset`, `InvestmentTransaction`).
- `ViewModels`: Business logic bridging the Models and the UI.
- `Views`: SwiftUI views organized by feature (`Dashboard`, `Transactions`, `Investments`, `Reports`).
- `Services`: Reusable managers and utility classes.
- `Helpers`: Extension methods, custom modifiers, and app-wide constants.


