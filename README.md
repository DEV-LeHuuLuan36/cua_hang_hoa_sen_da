# 🌵 Succulent Store - Hybrid Cloud E-Commerce Mobile App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=Firebase&logoColor=white)

A production-ready Flutter mobile e-commerce application engineered with a **Hybrid Cloud Architecture** (Offline-First local storage seamlessly synced with real-time cloud infrastructure) and high-fidelity UI/UX interactions.

---

## ✨ Core Features

- **Hybrid Synchronization:** Instantly records orders to SQLite for ultra-low latency and fires asynchronous real-time background syncs to Cloud Firestore.
- **Advanced Identity Management:** Complete Firebase Authentication integration featuring secure Email/Password registration and seamless Google Sign-In.
- **Premium Choreographed UI:** Custom Skeleton Shimmer loading screens across core pages, context-aware `EmptyStateWidget` handlers, and smooth `Hero` asset animations.
- **Production-Level Android Stability:** Custom operating-system-level event interceptors protecting the application state from accidental route-popping.
- **Dynamic Session & Personalization:** Local key-value state monitoring using SharedPreferences supporting unified theme state switches.

---

## 🎥 Demo Video

<img width="400" height="888" alt="demo" src="https://github.com/user-attachments/assets/cefa2467-06ac-4e96-a25a-ca5e93252e9f" />

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

## 💡 Architecture & Design Patterns

This ecosystem enforces clean code guidelines and decoupling mechanisms designed for enterprise scaling:
- **Data Access Separation:** Utilizes the **DAO (Data Access Object) & Repository Pattern** to separate data access contracts from execution semantics.
- **State Topology:** Managed globally through `Provider` listeners scoped efficiently to isolate rendering clusters and reduce widget paint footprints.
- **Local Persistence layer:** Built upon structured relational **SQLite** schema contracts for secure offline resilience.

---

## 📦 Core Dependencies

- `firebase_core` & `firebase_auth` — Enterprise Cloud Identity Layer
- `cloud_firestore` — Cloud Data Streaming & Backend Sync Engine
- `google_sign_in` — OAuth2 Ecosystem Integration
- `provider` — Reactive App State Architecture
- `sqflite` — Local Relational Embedded Cache Storage
- `shimmer` — High-Fidelity Motion Loading Layout States
- `flutter_native_splash` & `flutter_launcher_icons` — Native Hardware Assets Compilation

---

## 🧠 Technical Case Studies & Solutions

### 1. Hybrid Offline-First Sync & Cost Optimization (Firebase $0 Budget)
* **Challenge:** Direct reliance on real-time cloud databases spikes operation transaction costs and causes network latency dependencies during checkouts.
* **Solution:** Engineered a background hybrid sync flow. When an order is created, it is written immediately to local SQLite databases. If a valid network connection exists, the application fires a non-blocking asynchronous payload push to Cloud Firestore, enabling offline reliability and minimizing continuous billing reads/writes.

### 2. Guarding Ecosystem Routing from Fragmented Android Pops
* **Challenge:** Pressing the device hardware/virtual Back gesture on initial authentication layers triggered empty route stacks, creating app vulnerabilities or blank screen traps.
* **Solution:** Integrated a specialized hardware-level navigation guard using Flutter’s modern `PopScope`. It intercept background pops, evaluates continuous trigger timings, prompts a custom Toast notice ("Nhấn lần nữa để thoát"), and safe-exits the app process through OS-level `SystemNavigator.pop` calls upon double-tap.

### 3. Native Splash Scaling & Layout Fluidity Fixes
* **Challenge:** Default Android splash setups distorted application vector art into massive, pixelated over-stretched image maps.
* **Solution:** Re-configured the underlying Android res compilation assets engine via `pubspec.yaml`, injecting native hardware `gravity: center` parameters onto an explicit white `#FFFFFF` backdrop to enforce strict, un-stretched minimalist branding ratios scaling natively across device resolutions.

---

## 📂 Folder Structure

```text
lib/
├── database/
│   ├── contracts/       # Relational SQLite schema constraints
│   ├── daos/            # Low-level SQLite database access executors
│   └── repositories/    # Hybrid data abstraction layer & cloud syncer
├── models/              # Immutable data objects, serialization & maps
├── providers/           # Reactive state lifecycle controllers
├── routes/              # Central declarative app navigation router
├── screens/             # UI Layer screens (Customer/Admin/Auth matrices)
├── services/            # System services & background network integrations
├── theme/               # Visual design tokens & color configurations
├── utils/               # Static global constants & cross-cutting tools
└── widgets/             # Granular atomic & reusable layout blocks
