# PenAI

A production-ready MVP iOS app for speech-to-text transcription and AI-powered text polishing.

## Requirements

- **iOS**: 17.0 or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

## Features

- **Speech Recognition**: On-device speech-to-text using Apple's Speech framework
- **AI Text Polishing**: Sends transcripts to a configurable LLM endpoint for rewriting
- **Local Storage**: All data stored on-device using SwiftData (no cloud sync)
- **Privacy-First**: No audio is ever stored - only transcribed and polished text

## Setup

### 1. Configure API Endpoint

The app requires an API endpoint to polish transcribed text. You can configure this in one of three ways:

#### Option A: Info.plist via Xcode (Recommended)

1. Select the `penme` project in the navigator
2. Select the `penme` target
3. Go to the **Info** tab
4. Under **Custom iOS Target Properties**, click the **+** button to add new keys:
   - Add `API_BASE_URL` (type: String) = `https://your-api-endpoint.com`
   - Add `API_KEY` (type: String) = `your-api-key-here`

#### Option B: Environment Variables

Set environment variables in Xcode's scheme:

1. Product → Scheme → Edit Scheme...
2. Run → Arguments → Environment Variables
3. Add:
   - `API_BASE_URL` = `https://your-api-endpoint.com`
   - `API_KEY` = `your-api-key-here`

#### Option C: Code

Modify `PolishService` initializer in `Services/PolishService.swift` to pass values directly.

### 2. API Contract

Your API endpoint must accept the following:

**Endpoint**: `POST {API_BASE_URL}/rewrite`

**Headers**:
- `Content-Type: application/json`
- `Authorization: Bearer {API_KEY}` (if API_KEY is provided)

**Request Body**:
```json
{
  "transcript": "raw speech transcription",
  "locale": "en-US",
  "format": "title_and_polished_text"
}
```

**Response Body**:
```json
{
  "title": "Short Title Here",
  "polished_text": "Well-formatted, grammatically correct text with proper paragraphs..."
}
```

**Response Requirements**:
- Status code: 200-299
- `title`: 2-5 words
- `polished_text`: Well-structured text (paragraphs, optional bullets)

### 3. Configure Permissions

The app requests two permissions that must be added to Info.plist:

1. **Microphone** (`NSMicrophoneUsageDescription`): Required for recording speech
2. **Speech Recognition** (`NSSpeechRecognitionUsageDescription`): Required for on-device transcription

**To add these in Xcode:**

1. Select the `penme` project in the navigator
2. Select the `penme` target
3. Go to the **Info** tab
4. Under **Custom iOS Target Properties**, click the **+** button to add:
   - **Privacy - Microphone Usage Description** (`NSMicrophoneUsageDescription`)
     - Value: `PenAI needs access to your microphone to record speech and convert it to text. No audio is stored - only the transcribed text is saved.`
   - **Privacy - Speech Recognition Usage Description** (`NSSpeechRecognitionUsageDescription`)
     - Value: `PenAI uses speech recognition to transcribe your voice into text on your device. The transcription is then polished and saved as text - no audio is ever stored.`

If permissions are denied, the app will:
- Show an alert explaining why permissions are needed
- Provide a button to open iOS Settings
- Continue to work in "library mode" (viewing existing results)

### 4. Build and Run

1. Open `penme.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Connect an iOS 17+ device or simulator
4. Build and run (⌘R)

## Architecture

### File Structure

```
penme/
├── App/
│   └── penmeApp.swift          # App entry point
├── Models/
│   └── RecordingResult.swift   # SwiftData model
├── Services/
│   └── PolishService.swift     # LLM API client
├── Speech/
│   └── SpeechRecognizerService.swift  # Speech recognition
├── Views/
│   ├── LibraryView.swift       # Main list view
│   └── DetailsView.swift       # Detail/edit view
└── ViewModels/
    ├── LibraryViewModel.swift  # (Reserved for future use)
    └── DetailsViewModel.swift  # (Reserved for future use)
```

### Design Patterns

- **MVVM-Light**: Views communicate directly with services and models
- **SwiftData**: Persistent storage for `RecordingResult` entities
- **Async/Await**: All network calls use modern Swift concurrency
- **MainActor**: UI updates guaranteed on main thread

## Usage

1. **Record**: Tap the large blue "Record" button at the bottom
2. **Speak**: The app will transcribe your speech in real-time
3. **Stop**: Tap the red "Stop" button when finished
4. **Review**: The app automatically navigates to the polished result
5. **Edit**: Modify title and polished text as needed
6. **Share**: Use Copy or Share buttons in the detail view
7. **Delete**: Remove unwanted recordings from the detail view

## Privacy

- **No Audio Storage**: Audio is processed in real-time and discarded immediately
- **On-Device Transcription**: Speech recognition runs on-device when possible
- **Local-Only Data**: All saved data (transcripts, titles, polished text) is stored locally using SwiftData
- **No Cloud Sync**: No data is synced to iCloud or any cloud service
- **No Analytics**: No tracking or analytics are implemented

## Limitations (MVP Scope)

The following features are **intentionally excluded** from this MVP:

- Settings screen
- Onboarding flow
- Paywalls or subscriptions
- Analytics
- Account/login
- Cloud sync
- Widgets
- Progress screens (beyond minimal recording indicator)

## Troubleshooting

### Speech Recognition Not Working

- Ensure permissions are granted in Settings → PenAI
- Check that device/simulator supports speech recognition
- Verify audio session is not being used by another app

### API Calls Failing

- Verify `API_BASE_URL` is correctly set
- Check network connectivity
- Ensure API endpoint returns the expected JSON format
- Review console logs for error details

### Data Not Persisting

- Ensure SwiftData model container is properly configured
- Check device storage availability
- Verify `RecordingResult` model matches schema

## License

This project is provided as-is for MVP purposes.
