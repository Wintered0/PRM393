# cafeshop

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# cài đặt dependency
# dependencies (Cập nhật ngày 21/2/2026):
  
  
  # Cài đặt: Firebase packages
  # firebase_core: ^3.0.0
  # cloud_firestore: ^5.0.0
  # crypto: ^3.0.3
  # flutter_dotenv: ^5.2.1
  # mailer: ^6.4.1
  # http: ^1.2.2

  # Icons
  # cupertino_icons: ^1.0.8

# dev_dependencies:
  # flutter_test:sdk: flutter
    
  # flutter_lints: ^6.0.0

# flutter:
  # uses-material-design: true
 # assets: - .env
    
# sau đó chạy lệnh flutter pub get (Thực ra ko cần vì nó tự pub rồi)

# NGOÀI RA: Thêm đường link này vào phần enviroment --> Path --> Add
# C:\Users\HP\AppData\Local\Pub\Cache\bin

# sau đó chạy lệnh
# dart pub global activate flutterfire_cli
# flutterfire configure

# Vì FlutterFire CLI cần Firebase CLI để lấy danh sách project, bạn chạy:
# npm install -g firebase-tools

# Kiểm tra đăng nhập : firebase login và yes hết
# Kiểm tra list project: firebase projects:list

<!-- PS C:\Users\HP\StudioProjects\cafeshop> flutterfire configure
i Found 4 Firebase projects.
✔ Select a Firebase project to configure your Flutter application with · cafeshopmanagement (CafeShopManagement)
✔ Which platforms should your configuration support (use arrow keys & space to select)? · android, ios, macos, web, windows
i Firebase android app com.example.cafeshop is not registered on Firebase project cafeshopmanagement.
i Registered a new Firebase android app on Firebase project cafeshopmanagement.
i Firebase ios app com.example.cafeshop is not registered on Firebase project cafeshopmanagement.
⠸ Registering new Firebase ios app on Firebase project cafeshopmanagement. -->

# Platform  Firebase App Id
# web       1:521233549696:web:5c903b977dea3386fb1965
# android   1:521233549696:android:ef8a310c1bd3cd86fb1965
# ios       1:521233549696:ios:bdbbf74246142e68fb1965
# macos     1:521233549696:ios:bdbbf74246142e68fb1965
# windows   1:521233549696:web:b0eec7ee84728a0afb1965