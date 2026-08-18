# Elostaz Travel 🚌

A modern Flutter-based transportation management application designed to
help travel and transportation companies manage their buses, drivers,
trips, notifications, and financial operations from one place.

The application focuses on simplifying day-to-day fleet operations
through a clean, responsive, and easy-to-use mobile interface.

------------------------------------------------------------------------

## 📱 Project Overview

**Elostaz Travel** is a transportation management system built with
**Flutter and Dart**.

The application allows authorized users to:

-   Manage buses and their complete vehicle information.
-   Manage drivers and their personal/work information.
-   Add and manage trips.
-   Track trip revenue and financial data.
-   View financial summaries and reports.
-   Monitor vehicle-related notifications.
-   Receive important alerts such as vehicle license-expiration
    reminders.
-   View detailed information about buses, drivers, trips, and financial
    activity.
-   Refresh application data from the server.
-   Upload and manage vehicle images using the device camera or gallery.

The project is built with scalability, maintainability, responsive UI,
and clean separation of responsibilities in mind.

------------------------------------------------------------------------

## ✨ Main Features

### 🔐 Authentication

-   Secure user authentication.
-   Login flow with validation.
-   Persistent authenticated state.
-   Protected application flow after authentication.

### 🚌 Bus Management

Complete fleet management functionality, including:

-   Add a new bus.
-   Edit bus information.
-   View detailed bus information.
-   Vehicle brand and model year.
-   Plate number.
-   Engine number.
-   Chassis number.
-   Passenger capacity.
-   Vehicle type.
-   Insurance information.
-   Special conditions.
-   Vehicle images.
-   Local image caching.
-   Camera and gallery image selection.

### 👨‍✈️ Driver Management

Driver management functionality includes:

-   Add drivers.
-   View all drivers.
-   View driver details.
-   Edit driver information.
-   Connect drivers with their operational trips.
-   Display driver-related trip information.

### 🛣️ Trip Management

The trip management system allows users to:

-   Add new trips.
-   Associate trips with buses and drivers.
-   Store trip details.
-   Track trip revenue.
-   View previous trips.
-   View trips associated with a specific bus.
-   View trips associated with a specific driver.

### 💰 Financial Management

The financial section provides:

-   Financial summary.
-   Company-level totals.
-   Bus/group-based financial breakdown.
-   Trip-level revenue information.
-   Subtotals and organized financial data.
-   Financial summary reports.

### 🔔 Notifications

The application includes operational notifications for important events.

Examples include:

-   Vehicle license-expiration alerts.
-   Ongoing notifications.
-   Notification history.
-   Dedicated notifications screen.

The notification system is designed to help prevent important vehicle
documents from being overlooked.

### 🔄 Pull-to-Refresh

Relevant application screens support pull-to-refresh so users can
manually reload the latest data.

Refresh functionality is integrated with the existing Riverpod
notifiers/providers rather than creating duplicate data-loading
mechanisms.

### 📸 Image Management

Vehicle images can be selected through:

-   📷 Camera
-   🖼️ Gallery

The existing image preview and local caching flow are preserved after
image selection.

------------------------------------------------------------------------

# 🧱 Architecture

The project follows a **Clean Architecture** approach to keep the
codebase organized and maintainable.

The application is separated into logical layers such as:

``` text
Presentation
    ↓
Domain
    ↓
Data
    ↓
External Services / Firebase / APIs
```

### Presentation Layer

Responsible for:

-   Screens
-   Widgets
-   Bottom sheets
-   UI state
-   Riverpod providers/notifiers
-   User interactions

### Domain Layer

Contains the application business logic, entities, repositories, and use
cases where applicable.

### Data Layer

Responsible for:

-   Models
-   Remote data sources
-   Local data sources
-   Repository implementations
-   Firebase/API communication
-   Local image caching

This separation makes the application easier to test, maintain, and
extend.

------------------------------------------------------------------------

# 🧠 State Management

The application uses **Riverpod** for state management.

Riverpod is used to manage:

-   Bus state
-   Driver state
-   Trip state
-   Financial summary state
-   Notification state
-   Selected/navigation-related state
-   Loading and error states
-   Refresh operations

The project avoids unnecessary global mutable state and keeps
feature-specific state close to the feature that owns it.

------------------------------------------------------------------------

# 🛠️ Technology Stack

  Technology                     Usage
  ------------------------------ ----------------------------------------
  **Flutter**                    Cross-platform application development
  **Dart**                       Programming language
  **Riverpod**                   State management
  **Firebase**                   Backend/application services
  **Cloud Firestore**            Cloud data storage
  **Firebase Cloud Messaging**   Push notification infrastructure
  **REST APIs**                  API communication where required
  **Image Picker**               Camera/gallery image selection
  **Local Image Service**        Vehicle image caching
  **Clean Architecture**         Application architecture
  **Git / GitHub**               Version control

------------------------------------------------------------------------

# 📂 Project Structure

A simplified view of the project organization:

``` text
lib/
├── core/
│   ├── constants/
│   ├── dimens/
│   ├── theme/
│   ├── routing/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── authentication/
│   ├── home/
│   ├── buses/
│   ├── drivers/
│   ├── trips/
│   ├── notifications/
│   └── financial_summary/
│
├── models/
├── providers/
└── main.dart
```

> The exact folders may vary slightly depending on the current project
> implementation, but the project is organized around feature separation
> and clean responsibilities.

------------------------------------------------------------------------

# 🖥️ Application Screens

The repository contains a complete visual documentation set for the
application.

## Splash Screen

<img src="assets/readme/splash.jpg" width="48%">

------------------------------------------------------------------------

## Authentication

### Login

<img src="assets/readme/login.jpg" width="48%">

------------------------------------------------------------------------

# 🏠 Home

The home dashboard provides a quick overview of the most important
operational information.

<img src="assets/readme/home.jpg" width="48%">

### Home --- Additional View

<img src="assets/readme/rest-of-home.jpg" width="48%">

------------------------------------------------------------------------

# 🚌 Bus Management

### Bus Screen

<img src="assets/readme/bus-screen.jpg" width="48%">

### Add Bus Screen

<img src="assets/readme/add-bus-screen.jpg" width="48%">

### Add Bus --- Additional Section

<img src="assets/readme/rest-of-add-bus.jpg" width="48%">

### Add Bus --- Additional Section 2

<img src="assets/readme/rest-of-add-bus-sec.jpg" width="48%">

### Add Bus Bottom Sheet

<img src="assets/readme/add-bus-bottom-sheet.jpg" width="48%">

### Bus Details

<img src="assets/readme/bus-details.jpg" width="48%">

### Bus Details --- Additional Section

<img src="assets/readme/rest-of-bus-details.jpg" width="48%">

### Bus Details --- Additional Section 2

<img src="assets/readme/rest-of-bus-details-sec.jpg" width="48%">

### Edit Bus Bottom Sheet

<img src="assets/readme/edit-bus-bottom-sheet.jpg" width="48%">

### Add/Edit Bus Image Selection

<img src="assets/readme/add-edit-bus-bottom-sheet.jpg" width="48%">

------------------------------------------------------------------------

# 👨‍✈️ Driver Management

### Drivers Screen

<img src="assets/readme/drivers-screen.jpg" width="48%">

### Add Driver Bottom Sheet

<img src="assets/readme/add-driver-bottom-sheet.jpg" width="48%">

### Driver Details

<img src="assets/readme/driver-details.jpg" width="48%">

------------------------------------------------------------------------

# 🛣️ Trips

### Trips Screen

<img src="assets/readme/trips-screen.jpg" width="48%">

Trip management connects operational records with the selected bus and
driver and provides a history of recorded trips and their financial
values.

------------------------------------------------------------------------

# 🔔 Notifications

### All Notifications

<img src="assets/readme/all-notifications.jpg" width="48%">

### Ongoing Notifications

<img src="assets/readme/ongoing-notifications.jpg" width="48%">

The notification area provides a centralized place to review operational
alerts and important vehicle-related reminders.

------------------------------------------------------------------------

# 💰 Financial Management

### Financial Summary

<img src="assets/readme/financial-summary.jpg" width="48%">

### Financial Summary --- Additional View

<img src="assets/readme/rest-of-financial-summary.jpg" width="48%">

### Financial Summary Report

<img src="assets/readme/financial-summary-report.jpg" width="48%">

The financial module organizes trip revenue into a clear structure,
making it easier to understand the company's financial activity and
compare totals across buses and trips.

------------------------------------------------------------------------

# 🎨 UI & UX

The application is designed with a focus on:

-   Clean and modern interface.
-   Arabic-friendly user experience.
-   Responsive layouts.
-   Reusable custom widgets.
-   Consistent spacing and typography.
-   Clear data hierarchy.
-   Bottom sheets for focused actions.
-   Easy-to-understand operational workflows.
-   Smooth navigation and interaction animations.
-   Responsive touch targets for important controls.
-   Pull-to-refresh on data-driven screens.

------------------------------------------------------------------------

# 📱 Responsive Design

The application uses responsive sizing throughout the UI to support
different device sizes.

Important UI elements are designed to:

-   Adapt to different screen widths.
-   Avoid unnecessary overflow.
-   Handle long text safely.
-   Maintain consistent spacing.
-   Keep interactive controls easy to press.

------------------------------------------------------------------------

# 🔄 Data Refresh

Data-driven screens support pull-to-refresh.

Examples include:

-   Home
-   Buses
-   Drivers
-   Notifications
-   Bus Details
-   Driver Details
-   Bus Trips
-   Financial Summary

Refresh operations reuse the existing providers/notifiers and reload the
appropriate data without introducing duplicate state-management logic.

------------------------------------------------------------------------

# 🖼️ Image Handling

Vehicle images are handled through the existing image-management flow.

When uploading an image, the user can choose:

``` text
Choose Image
    ├── Camera
    └── Gallery
```

The selected image is then returned to the existing form and preview
flow.

Local caching is also used to improve image handling and reduce
unnecessary repeated loading.

------------------------------------------------------------------------

# 🔔 License Expiration Alerts

One of the important operational features of Elostaz Travel is helping
users keep track of vehicle documentation.

Vehicle license expiration information can be used to generate timely
alerts so that the responsible user can take action before a license
expires.

This reduces the possibility of missing important renewal dates.

------------------------------------------------------------------------

# 🧩 Reusable Components

The application makes use of reusable components for common UI and
functionality, including:

-   Custom text widgets.
-   Custom SVG icons.
-   Custom app bars.
-   Reusable form fields.
-   Bottom sheets.
-   Responsive dimensions.
-   Shared styling/theme components.
-   Reusable loading/error states.

This helps keep screens consistent and reduces duplicated UI code.

------------------------------------------------------------------------

# 🚀 Getting Started

## Prerequisites

Make sure the following are installed:

-   Flutter SDK
-   Dart SDK
-   Android Studio or another Flutter-compatible IDE
-   Android SDK
-   Git

Check your Flutter installation:

``` bash
flutter doctor
```

------------------------------------------------------------------------

## Installation

Clone the repository:

``` bash
git clone <YOUR_REPOSITORY_URL>
```

Navigate to the project:

``` bash
cd elostaz_travel
```

Install dependencies:

``` bash
flutter pub get
```

Run the application:

``` bash
flutter run
```

------------------------------------------------------------------------

# 🔥 Firebase Configuration

The application uses Firebase services.

Before running the project, make sure the correct Firebase configuration
files are included for the target platform.

For Android, the Firebase configuration should be correctly connected to
the Flutter project.

Never commit private credentials, API keys that should remain secret,
service-account files, or other sensitive configuration to a public
repository.

------------------------------------------------------------------------

# 🧪 Code Quality

The project is continuously checked using Flutter/Dart static analysis.

Run:

``` bash
dart analyze
```

or:

``` bash
flutter analyze
```

Format the project with:

``` bash
dart format .
```

------------------------------------------------------------------------

# 📸 Documentation Screenshots

All screenshots included in this repository are stored inside:

``` text
assets/readme/
```

The documentation intentionally includes all available screenshots
without duplicating the same screenshot.

For long screens, the screenshots are documented as sequential sections
such as:

``` text
Screen
Screen — Additional Section
Screen — Additional Section 2
```

This keeps the README readable while documenting the complete
application flow.

------------------------------------------------------------------------

# 🗺️ Main Application Flow

``` text
Splash
   ↓
Login
   ↓
Home
   ├── Buses
   │    ├── Add Bus
   │    ├── Edit Bus
   │    └── Bus Details
   │          └── Trips
   │
   ├── Drivers
   │    ├── Add Driver
   │    └── Driver Details
   │          └── Trips
   │
   ├── Notifications
   │
   └── Financial Summary
        └── Financial Report
```

------------------------------------------------------------------------

# 📊 Core Data Relationships

``` text
Company
   │
   ├── Buses
   │     │
   │     └── Trips
   │
   ├── Drivers
   │     │
   │     └── Trips
   │
   └── Financial Data
         │
         └── Trip Revenue
```

This structure allows operational information to remain connected across
fleet management, driver management, trips, and financial reporting.

------------------------------------------------------------------------

# 🔒 Data & Security

The application is designed around authenticated access and controlled
application data.

Recommended production practices include:

-   Firebase Security Rules.
-   Proper authentication checks.
-   Least-privilege access.
-   Secure API communication.
-   Never storing secrets directly in the source code.
-   Validating user input before persistence.

------------------------------------------------------------------------

# 🏗️ Future Improvements

Possible future enhancements include:

-   Advanced analytics dashboard.
-   More detailed financial reports.
-   Exporting financial reports.
-   Advanced notification preferences.
-   Automated document renewal workflows.
-   More advanced search and filtering.
-   Role-based access for different employees.
-   Cloud-based vehicle image storage.
-   Additional reporting and operational statistics.

------------------------------------------------------------------------

# 👨‍💻 Developer

**Elostaz Travel** is a Flutter application developed as a
transportation management solution with a focus on clean architecture,
responsive UI, maintainable code, and practical fleet-management
workflows.

### Core Skills Demonstrated

-   Flutter & Dart
-   Clean Architecture
-   SOLID Principles
-   Riverpod
-   Firebase
-   Firestore
-   Firebase Cloud Messaging
-   REST APIs
-   Responsive UI
-   State Management
-   Local Caching
-   Image Handling
-   Notifications
-   Financial Data Management
-   Git & GitHub

------------------------------------------------------------------------

# ⭐ Project Highlights

-   🚍 Complete bus management workflow.
-   👨‍✈️ Driver management.
-   🛣️ Trip management.
-   💰 Financial summaries and reports.
-   🔔 Operational notifications.
-   📅 License expiration tracking.
-   📸 Camera/gallery image selection.
-   🔄 Pull-to-refresh.
-   🧱 Clean Architecture.
-   ⚡ Riverpod state management.
-   📱 Responsive Flutter UI.
-   🧩 Reusable components.
-   🔥 Firebase integration.

------------------------------------------------------------------------

## License

This project is intended for its designated business/project use.

Copyright © Elostaz Travel.
