Airline Admin Panel

My term paper project

A comprehensive Flutter-based administration panel for airline management, designed to streamline operations for staff and administrators.

![overview](https://github.com/user-attachments/assets/2c55a48a-e4e6-4b36-970f-7500267b88d8)

API code:
![GitHub](https://github.com/NickSishchuck/airlinesAPI)

Features

Authentication System: Secure login with role-based access control
Dashboard: Real-time overview of flight statistics and recent flights
Flight Management: Create, edit, delete, and search flights
Ticket Management: Book tickets, manage seat assignments, and process payments
Crew Management: Organize flight crews and assign crew members to flights
Pricing Management: Configure pricing across different routes and seat classes
Reports & Analytics: Generate ticket sales reports and export as PDF or CSV

Technology Stack

Frontend: Flutter (Dart)
State Management: Provider
UI Components: Data Tables, Cards, Material Design
Data Visualization: Charts for analytics
PDF Generation: PDF rendering for tickets and reports
API Integration: REST API connection to backend services

Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/airline-admin-panel.git
cd airline-admin-panel
```
2. Install dependencies
```bash
flutter pub get
```
3. Configure API endpoint
Open lib/services/api_service.dart and update the baseUrl variable to point to your backend server:
```dart
static const String baseUrl = 'http://your-api-endpoint.com/api';
```
4. Run the application
```bash
flutter run -d chrome  # For web
# Or
flutter run             # For mobile/desktop
```

Usage Guide
Authentication
The system supports different roles:

Admin: Complete access to all features
Staff: Limited access to operational features

Navigation
The sidebar menu provides access to all main sections:

Dashboard
Flights Management
Tickets Management
Crew Management
Pricing Management
Reports & Analytics

Flight Management

View all scheduled flights
Create new flights with route, aircraft, and crew information
Initialize and manage seat maps
Update flight status (scheduled, delayed, boarding, etc.)

Ticket Management

Book new tickets for passengers
Search for tickets by various criteria
Print boarding passes
Update payment status
Cancel or modify bookings

Crew Management

Organize flight crews
Add and manage crew members (captains, pilots, flight attendants)
Assign crew members to specific flights
Track licensing and experience information

Pricing Management

Set base prices for routes
Configure multipliers for different seat classes
Apply special pricing rules

Reports

Generate ticket sales reports
Analyze revenue by flight, route, or seat class
Export reports in PDF format

Project Structure
```markdown
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── crew.dart
│   ├── flight.dart
│   ├── report.dart
│   ├── seat_map.dart
│   ├── ticket.dart
│   └── user.dart
├── providers/                   # State management
│   └── auth_provider.dart
├── screens/                     # UI screens
│   ├── dashboard_screen.dart
│   ├── flights_screen.dart
│   ├── tickets_screen.dart
│   └── ...
├── services/                    # API and business logic
│   ├── api_service.dart
│   ├── pdf_service.dart
│   └── ...
└── utils/                       # Utilities and constants
    └── constants.dart
```

Configuration
The application connects to a RESTful API backend. You can configure the API endpoint in the api_service.dart file.
Requirements

Flutter SDK: 2.0.0 or higher
Dart: 2.12.0 or higher
Dependencies as listed in pubspec.yaml
