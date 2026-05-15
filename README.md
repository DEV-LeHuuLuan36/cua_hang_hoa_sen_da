# 🌵 Succulent Store - E-Commerce Mobile App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

A Flutter-based mobile e-commerce application focused on responsive UI design, local data persistence, and scalable state management.

---

## ✨ Features

- Product browsing and shopping cart management
- Wishlist and user session handling
- Google Maps integration for delivery address selection
- Dynamic Dark/Light theme switching
- Responsive mobile UI across multiple screen sizes
- Simple admin interface for inventory and order management
- Offline local data persistence using SQLite

---

## 💡 Motivation

This project was built to strengthen my understanding of Flutter state management, local database architecture, and responsive mobile UI development through a practical, real-world e-commerce scenario.

---

## 🎥 Demo Video

<img width="400" height="888" alt="demo" src="https://github.com/user-attachments/assets/cefa2467-06ac-4e96-a25a-ca5e93252e9f" />
---

## 🛠 Architecture & Technologies

This project is structured with maintainability and clean code principles in mind:

- **Design Pattern:** Implemented the **DAO (Data Access Object) & Repository Pattern** to separate business logic from data access, improving maintainability and separation of concerns.
- **State Management:** Utilized `Provider` to manage application state efficiently across multiple screens.
- **Local Storage:** Built on top of **SQLite** (`sqflite`) for local offline data persistence.
- **Responsive UI:** Designed reusable widgets and adaptive layouts for consistent rendering across devices.

---

## 📦 Main Dependencies

- `provider` — State management
- `sqflite` — SQLite database wrapper
- `Maps_flutter` — Google Maps integration
- `shared_preferences` — Local key-value storage
- `shimmer` — Skeleton loading effects

---

## 🧠 Technical Challenges & Solutions

### State Management Optimization
Optimized `Provider` state updates to minimize unnecessary widget rebuilds, especially within shopping cart and checkout flows.

### Component Reusability
Structured reusable widgets such as custom product cards, shimmer loaders, and buttons to reduce code duplication and improve maintainability.

### Data Persistence
Implemented SQLite-based local persistence for offline cart management, wishlist handling, and user session storage.

### UI/UX Implementation
Implemented responsive layouts with Google Maps integration, dynamic theme switching, and adaptive rendering across different screen sizes.

---

## 📱 Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/cdad0ec7-682d-4c47-bf7a-f1382c0640ab" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/7fff9680-744a-4e9e-916a-b73c116f308f" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/3c929f28-6811-4234-810d-79a330632b56" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/1cefab58-d3a6-450b-a1e4-5ae6fb905b35" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/357fe654-9634-473b-b131-ec3e7fffb02d" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/f8d79d3d-7042-428f-b3f9-0b289c23010f" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/f40a1388-c63a-4da2-9435-adb89cca2e3b" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/1bba7236-9a8e-4e4d-bc6a-2a97efecfee3" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/e5f8476a-ba3d-4c98-bfd4-7e939cd94ec4" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/1d8f2e59-7633-442e-95c2-93911d31dffa" width="200" style="margin: 5px;" />
  <img src="https://github.com/user-attachments/assets/96bd435a-7171-4aee-9597-90e66ae58277" width="200" style="margin: 5px;" />
</p>

---

## 🚀 Getting Started

Run the following commands to set up the project locally:

    git clone [https://github.com/DEV-LeHuuLuan36/cua_hang_hoa_sen_da.git](https://github.com/DEV-LeHuuLuan36/cua_hang_hoa_sen_da.git)
    cd cua_hang_hoa_sen_da
    flutter pub get
    flutter run

---

## 📂 Folder Structure

    lib/
    ├── database/
    │   ├── contracts/       # Database table schemas
    │   ├── daos/            # Raw SQLite query handlers
    │   └── repositories/    # Data abstraction layer
    ├── models/              # Data models and enums
    ├── providers/           # State management logic
    ├── routes/              # Application navigation
    ├── screens/             # UI screens (Customer/Admin/Auth)
    ├── services/            # External services and integrations
    ├── theme/               # Theme and typography configuration
    ├── utils/               # Constants and helper functions
    └── widgets/             # Reusable UI components

---

## 🧪 Future Technical Improvements

This project is continuously evolving. Planned future enhancements include:

* Implementing a remote API layer using Dio/http
* Introducing BLoC or Riverpod for scalable state management
* Adding unit tests and widget tests
* Integrating Firebase Authentication
* Adding push notifications for order updates
* Implementing payment gateway support

---

## 👨‍💻 Author

**Le Huu Luan**

* GitHub: [https://github.com/DEV-LeHuuLuan36](https://github.com/DEV-LeHuuLuan36)
