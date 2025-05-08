# Flutter MVVM Riverpod Starter

A lightweight Flutter starter template implementing **MVVM architecture** with **Riverpod state management** and **Supabase backend**. Perfect for indie hackers and solo developers looking to quickly bootstrap their projects.

This project was inspired by the [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide) and the [Starter Architecture for Flutter & Firebase](https://github.com/bizz84/starter_architecture_flutter_firebase).

## 🎯 Features

- **MVVM Architecture**: Clean separation of concerns
- **Riverpod State Management**: Efficient and type-safe state management solution
- **Supabase Backend**: Ready-to-use backend infrastructure
- **Dark/Light Theme**: Built-in theme support
- **Localization**: Multi-language support
- **Authentication**: Email & Social login ready
- **Routing**: Declarative routing with go_router
- **In-App Purchases**: RevenueCat integration for subscriptions and purchases

## 📚 Libraries & Tools

| Category             | Library                | Purpose                      |
|----------------------|------------------------|------------------------------|
| **State Management** |
|                      | `flutter_riverpod`     | Reactive state management    |
|                      | `riverpod_annotation`  | Code generation for Riverpod |
| **Backend & Auth**   |
|                      | `supabase_flutter`     | Backend as a service         |
|                      | `google_sign_in`       | Google authentication        |
|                      | `sign_in_with_apple`   | Apple authentication         |
| **Navigation**       |
|                      | `go_router`            | Declarative routing          |
| **Storage**          |
|                      | `shared_preferences`   | Local key-value storage      |
|                      | `sqflite`              | Local database               |
| **Network**          |
|                      | `dio`                  | HTTP client                  |
|                      | `connectivity_plus`    | Network connectivity         |
| **UI/UX**            |
|                      | `google_fonts`         | Custom fonts                 |
|                      | `flutter_svg`          | SVG rendering                |
|                      | `shimmer`              | Loading animations           |
|                      | `lottie`               | Animation files              |
| **Utilities**        |
|                      | `easy_localization`    | Internationalization         |
|                      | `envied`               | Environment variables        |
|                      | `uuid`                 | Unique identifiers           |
| **Analytics**        |
|                      | `firebase_analytics`   | Usage tracking               |
|                      | `firebase_crashlytics` | Crash reporting              |
| **Monetization**     |
|                      | `in_app_purchase`      | In-app purchases             |
|                      | `purchases_flutter`    | RevenueCat integration       |

## 🏗 Project Structure

```
lib/
├── constants/         # App constants and configurations
├── environment/       # Environment variables and config files
├── extensions/        # Extension methods and helpers
├── features/          # Feature modules
│   ├── common/
│   ├── authentication/
│   ├── home/
│   ├── onboarding/
│   ├── profile/
│   ├── premium/
├── routing/           # Route configurations
├── theme/             # Theme configurations
└── utils/             # Utility functions
```

## 🚀 Getting Started

1. Clone this repository
   ```bash
   git clone https://github.com/namanh11611/flutter_mvvm_riverpod.git
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Generate code
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Change the app information
   - To change the app package name, run the following command:
   ```bash
   dart run change_app_package_name:main com.new.package.name
   ```
   - To change the Android app name, open the `android/app/src/main/AndroidManifest.xml` file, change the `android:label="New App Name"`
   - To change the iOS app name, open the `ios/Runner/Info.plist` file, change the `CFBundleDisplayName` to `New App Name`
   - To change the iOS bundle name, open the `ios/Runner/Info.plist` file, change the `CFBundleName` to `new_bundle_name`

5. Run the app
   ```bash
   flutter run
   ```

## 📱 Screenshots

| Light Hero                                | Light Profile                                   | Dark Hero                               | Dark Profile                                  |
|-------------------------------------------|-------------------------------------------------|-----------------------------------------|-----------------------------------------------|
| ![Hero Light](/screenshots/HeroLight.png) | ![Profile Light](/screenshots/ProfileLight.png) | ![Hero Dark](/screenshots/HeroDark.png) | ![Profile Dark](/screenshots/ProfileDark.png) |

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
