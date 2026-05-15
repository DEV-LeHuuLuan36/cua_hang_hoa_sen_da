# 🌵 Succulent Store - E-Commerce Mobile App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

A Flutter-based mobile e-commerce application focused on responsive UI design, local data persistence, and scalable state management.

## 💡 Motivation
This project was built to strengthen my understanding of Flutter state management, local database architecture, and responsive mobile UI development through a practical, real-world e-commerce scenario.

## 🎥 Demo Video
*(Chèn link ảnh GIF 30s hoặc link YouTube không công khai demo các luồng: Cuộn trang chủ -> Thêm giỏ hàng -> Check bản đồ -> Chuyển Dark Mode)*

## 🛠 Architecture & Technologies
This project is structured with maintainability and clean code principles in mind:
* **Design Pattern:** Implemented the **DAO (Data Access Object) & Repository Pattern** to separate business logic from data access, ensuring better separation of concerns and maintainability.
* **State Management:** Utilized `Provider` to manage app state efficiently across multiple screens.
* **Local Storage:** Built on top of **SQLite** (`sqflite`) for local offline data persistence.

## 📦 Main Dependencies
* `provider` - State management
* `sqflite` - SQLite database wrapper
* `Maps_flutter` - Maps integration
* `shared_preferences` - Simple key-value storage
* `shimmer` - Loading effects

## 🧠 Technical Challenges & Solutions
* **State Management Optimization:** Optimized `Provider` state updates to minimize unnecessary widget rebuilds, specifically within the shopping cart and checkout flows.
* **Component Reusability:** Structured reusable widgets (custom cards, buttons, shimmer effects) to maintain consistent UI behavior and reduce code duplication across screens.
* **Data Persistence:** Implemented SQLite data persistence for offline cart, wishlist, and user session handling.
* **UI/UX Implementation:** Managed complex UI layouts, including Google Maps integration, dynamic theme switching (Dark/Light mode), and responsive rendering across different screen sizes.

## 📱 Screenshots

<p align="center">
  <img src="screenshots/home.png" width="200" style="margin: 10px;">
  <img src="screenshots/detail.png" width="200" style="margin: 10px;">
  <img src="screenshots/cart.png" width="200" style="margin: 10px;">
  <img src="screenshots/maps.png" width="200" style="margin: 10px;">
</p>

## 🚀 Getting Started

To run this project locally, execute the following commands:

```bash
git clone [https://github.com/DEV-LeHuuLuan36/cua_hang_hoa_sen_da.git](https://github.com/DEV-LeHuuLuan36/cua_hang_hoa_sen_da.git)
cd cua_hang_hoa_sen_da
flutter pub get
flutter run
📂 Folder Structure
The source code is modularized by feature and responsibility:

Plaintext
lib/
├── database/
│   ├── contracts/    # Database table schemas
│   ├── daos/         # Data Access Objects (Raw SQL queries)
│   └── repositories/ # Abstraction layer for data handling
├── models/           # Data classes and enums
├── providers/        # State management classes
├── routes/           # Application routing logic
├── screens/          # UI Screens (Customer, Admin, Auth)
├── services/         # External services (e.g., Notifications)
├── theme/            # App colors and typography
├── utils/            # Constants and helper functions
└── widgets/          # Reusable UI components
🧪 Future Technical Improvements
This project is continuously evolving. The roadmap for upcoming technical enhancements includes:

Implement remote API layer with Dio / http.

Introduce BLoC or Riverpod architecture for complex state scaling.

Add unit and widget testing to ensure core business logic stability.

Integrate Firebase Authentication for secure user identity management.