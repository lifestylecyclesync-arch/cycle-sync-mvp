# Cycle Syncing MVP

## Overview
The Cycle Syncing app is designed to help users track their menstrual cycles, understand their health better, and optimize their fitness and nutrition based on their cycle phases. This MVP focuses on essential features such as cycle tracking, onboarding, a dashboard for insights, and basic fitness and nutrition information.

## Features
- **Cycle Tracking**: Users can log their cycle data and view insights about their cycle phases.
- **Onboarding**: A guided setup process to help users input their initial data and understand the app's functionalities.
- **Dashboard**: A summary screen that provides insights into the user's cycle and health metrics.
- **Fitness and Nutrition Basics**: Information and tips on fitness and nutrition tailored to different phases of the menstrual cycle.

## Project Structure
```
cycle-sync-mvp
├── android
├── ios
├── lib
│   ├── main.dart
│   └── src
│       ├── app.dart
│       ├── routes.dart
│       ├── core
│       │   ├── models
│       │   │   ├── cycle.dart
│       │   │   ├── user.dart
│       │   │   └── nutrition_plan.dart
│       │   ├── services
│       │   │   ├── storage_service.dart
│       │   │   └── health_service.dart
│       │   └── utils
│       │       └── constants.dart
│       ├── features
│       │   ├── onboarding
│       │   │   ├── onboarding_screen.dart
│       │   │   └── onboarding_view_model.dart
│       │   ├── tracking
│       │   │   ├── tracking_screen.dart
│       │   │   ├── cycle_repository.dart
│       │   │   └── cycle_event.dart
│       │   ├── dashboard
│       │   │   ├── dashboard_screen.dart
│       │   │   └── widgets
│       │   │       └── cycle_summary_card.dart
│       │   └── wellness
│       │       ├── fitness_screen.dart
│       │       └── nutrition_screen.dart
│       └── widgets
│           ├── common_app_bar.dart
│           └── loading_indicator.dart
├── test
│   └── widget_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Getting Started
To run the Cycle Syncing app locally, follow these steps:

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd cycle-sync-mvp
   ```

2. **Install dependencies**:
   ```
   flutter pub get
   ```

3. **Run the app**:
   ```
   flutter run
   ```

## Future Enhancements
- Integration with wearable devices for health tracking.
- Advanced analytics for cycle predictions and health insights.
- Community features for users to share experiences and tips.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.