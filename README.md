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

## Installation

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/your-username/FinancialTracker.git
   ```
2. Open the project in Xcode:
   ```bash
   cd FinancialTracker
   open FinancialTracker.xcodeproj
   ```
3. Wait for Xcode to resolve any Swift Package Manager dependencies (if applicable).
4. Select an iOS Simulator or connected iOS Device (iOS 17.0+) as the run destination.
5. Press `Cmd + R` to build and run the application.

## Directory Structure

- `Models`: Data structures and SwiftData entities (`Transaction`, `InvestmentAsset`, `InvestmentTransaction`).
- `ViewModels`: Business logic bridging the Models and the UI.
- `Views`: SwiftUI views organized by feature (`Dashboard`, `Transactions`, `Investments`, `Reports`).
- `Services`: Reusable managers and utility classes.
- `Helpers`: Extension methods, custom modifiers, and app-wide constants.

## Contributing

Contributions are welcome! If you'd like to improve the app or add new features:
1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## License

Distributed under the MIT License. See `LICENSE` for more information.
