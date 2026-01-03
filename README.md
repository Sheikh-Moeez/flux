# Flux 💸

> **Master your money flow.**
> A modern, intuitive personal finance application built with Flutter that helps you track expenses, manage debts, and stay on top of your bills with a simple, elegant interface.

---

## 📱 About

**Flux** is designed to make personal finance management effortless. With a focus on user experience and visual appeal, Flux offers a comprehensive suite of tools to handle your daily financial activities. Whether it's logging a quick expense, tracking who owes you money, or getting reminded about an upcoming bill, Flux has you covered—all wrapped in a stunning glassmorphic UI.

## ✨ Features

*   **📊 Smart Dashboard**: Get a real-time overview of your financial health with Total Balance, Income, and Expense tracking.
*   **💸 Transaction Logging**: Easily record income and expenses with categorized entries.
*   **🤝 Debt Tracking**: Keep track of "I Owe" vs "They Owe" to manage personal loans and debts effectively.
*   **🔔 Bill Reminders**: Set up due dates for bills and receive local notifications so you never miss a payment.
*   **☁️ Cloud Sync**: Seamlessly sync your data across devices using **Firebase Firestore**.
*   **🔐 Secure Authentication**: Sign in securely with Google or Email/Password via **Firebase Auth**.
*   **📂 Data Export**: Export your transaction history to CSV for external analysis.
*   **🎨 Modern UI**: Enjoy a sleek, dark-themed interface featuring glassmorphism and smooth animations.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/)
*   **Language**: [Dart](https://dart.dev/)
*   **State Management**: [Provider](https://pub.dev/packages/provider)
*   **Backend**: [Firebase](https://firebase.google.com/)
    *   Authentication
    *   Cloud Firestore
*   **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
*   **UI Components**:
    *   [Flutter Animate](https://pub.dev/packages/flutter_animate) for animations.
    *   [Phosphor Icons](https://pub.dev/packages/phosphor_flutter) for a consistent icon set.
    *   [Glassmorphism](https://pub.dev/packages/glass_kit) design elements.
*   **Utilities**:
    *   [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
    *   [CSV](https://pub.dev/packages/csv) & [Share Plus](https://pub.dev/packages/share_plus) for exporting data.

## 🚀 Getting Started

Follow these steps to get a local copy running.

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
*   A Firebase project set up.

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Sheikh-Moeez/flux.git
    cd flux
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    *   Create a project in the [Firebase Console](https://console.firebase.google.com/).
    *   Add an Android/iOS app to your Firebase project.
    *   Download the `google-services.json` (for Android) and put it in `android/app/`.
    *   Download the `GoogleService-Info.plist` (for iOS) and put it in `ios/Runner/`.
    *   Enable **Authentication** (Google & Email/Password).
    *   Enable **Cloud Firestore** database.

4.  **Run the app**
    ```bash
    flutter run
    ```

## 📸 Screenshots

| Dashboard | Login | Transaction History |
|:---:|:---:|:---:|
| <!-- Add screenshot here --> | <!-- Add screenshot here --> | <!-- Add screenshot here --> |

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Built with ❤️ by [Sheikh Moeez](https://github.com/Sheikh-Moeez)*
