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

*(Chèn link ảnh GIF 30s hoặc link YouTube không công khai demo các luồng: Cuộn trang chủ -> Thêm giỏ hàng -> Check bản đồ -> Chuyển Dark Mode)*

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
  <img src="screenshots/home.png" width="200" style="margin: 10px;" />
  <img src="screenshots/detail.png" width="200" style="margin: 10px;" />
  <img src="screenshots/cart.png" width="200" style="margin: 10px;" />
  <img src="screenshots/maps.png" width="200" style="margin: 10px;" />
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