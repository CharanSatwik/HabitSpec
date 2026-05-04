# HabitSpec

A minimalist, distraction-free Flutter habit tracking application featuring secure Firebase authentication, seamless Google Sign-In, and a premium user experience. HabitSpec helps you focus on building routines with a streamlined UI and reliable cloud synchronization.

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/85cdf096-8bf9-4e1c-8024-83cdeb40da70" width="19%" />
  <img src="https://github.com/user-attachments/assets/80cc5bde-2cb5-411c-b72f-787ccbd51bb0" width="19%" />
  <img src="https://github.com/user-attachments/assets/efce410e-440f-4056-8e1c-8e98841ce122" width="19%" />
  <img src="https://github.com/user-attachments/assets/3605a2ef-cb72-4919-8277-35e9853389d8" width="19%" />
  <img src="https://github.com/user-attachments/assets/3597a79f-40f4-4ede-afb0-00b969550571" width="19%" />
</p>

## Features

-  **Built with Flutter:** Cross-platform support with smooth, premium UI transitions.
-  **Secure Authentication:** Complete Firebase integration with Email/Password verification and Google Sign-In. 
-  **Cloud Synchronization:** Utilizes Cloud Firestore for real-time backend data synchronization.
-  **Modern Architecture:** Clean state management using the `Provider` package.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A Firebase Project (with Authentication and Firestore enabled)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YourUsername/HabitSpec.git
   cd HabitSpec
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Environment Variables:**
   This project uses `flutter_dotenv` to securely manage keys. You must create a `.env` file in the root of the project with your Google Server Client ID:
   ```env
   GOOGLE_SERVER_CLIENT_ID=your_server_client_id_here
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```
