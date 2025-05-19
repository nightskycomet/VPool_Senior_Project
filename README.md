# VPool - Ride Sharing App

VPool is a comprehensive ride sharing application built with Flutter and Firebase that enables users to offer and join rides, communicate with each other, and manage their transportation needs efficiently.

## Features
- User authentication (registration, login) with role-based access
- Role-based UI for riders, drivers, and employees
- Ride creation and management
- Ride requests and approvals
- In-app messaging and group chats
- Interactive maps with Google Maps integration
- User profiles and ratings
- AI-powered price suggestions for gas contributions
- Administrative dashboard for employees

## Installation

### Clone the repository
```bash
git clone https://github.com/nightskycomet/VPool_Senior_Project
cd vpool
```

### Install dependencies
```bash
flutter pub get
```

### Configure Firebase
1. Create a Firebase project in the Firebase Console
2. Add Android & iOS apps to your Firebase project
3. Download and add the necessary configuration files
4. Enable Authentication, Realtime Database, and Storage

### Run the app
```bash
flutter run
```

## System Requirements
- Flutter SDK: 3.6.1 or higher
- Dart: 3.0.0 or higher
- Google Maps API key with enabled APIs:
  - Maps SDK for Android/iOS
  - Places API
  - Distance Matrix API
- Firebase project with Realtime Database
- Android SDK 21+ or iOS 12+ for deployment

## Usage

### Web Application (Employee Access)
The web application is designed for employees to monitor and manage the platform. Employees can:
- View and manage all rides
- Handle user reports
- Process user verifications
- Generate statistics and reports

#### Employee Test Accounts
| Email | Password | Role |
|-------|----------|------|
| employee1@gmail.com | 123456 | Employee |

### Mobile Application (User Access)
The mobile version is designed for end users and offers different functionalities based on user roles:

#### Rider Role
Users who want to join rides offered by drivers.
| Email | Password | Role |
|-------|----------|------|
| rider@gmail.com | rider123 | Rider |

#### Driver Role
Users who want to offer rides to others.
| Email | Password | Role |
|-------|----------|------|
| driver@gmail.com | driver123 | Driver |

#### Combined Role
Users who want both driver and rider capabilities.
| Email | Password | Role |
|-------|----------|------|
| both@gmail.com | both123 | Both |

## AI Features
### Smart Price Suggestion
The app includes an AI-powered price suggestion feature that helps drivers set appropriate gas contribution amounts. This feature:
- Calculates route distances using Google Maps API
- Considers time of day for pricing adjustments
- Recommends fair pricing based on distance and other factors
- Provides both USD pricing options

## File Structure Overview
```
lib/
├── firebase/ - Firebase service integrations
├── screens/
│   ├── Employee Pages/ - Admin dashboard screens
│   └── User Pages/ - End user screens
├── Main Pages/ - Primary user interface screens
├── Miscellanous Pages/ - Supporting screens
├── services/ - Business logic services
├── widgets/ - Reusable UI components
└── pages/ - Map and location-based pages
```

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Known Issues
- Maps occasionally may not load correctly on web due to CORS issues
- Profile pictures might not upload in certain network conditions
- Group chat notifications may be delayed on some devices

## Future Enhancements
- Ride scheduling for future dates
- Payment integration for in-app transactions
- Enhanced route optimization
- Rating system improvements
- Dark mode support

## License
This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgements
- Google Maps Platform for location services
- Firebase for backend services
- Flutter team for the incredible framework