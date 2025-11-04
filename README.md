# X Engager

A production-ready Flutter app for X (Twitter) engagement with LLM-powered content generation.

## Features

- **AI-Powered Content Generation**: Generate engaging posts using OpenAI or DeepSeek models
- **Multiple Templates**: Choose from various post templates (short posts, replies, threads)
- **X Actions**: Post, Like, Retweet, and Reply to tweets
- **Analytics Dashboard**: Track your engagement with interactive charts
- **Action Log**: View and filter all your actions
- **Customizable Settings**: Configure API keys, LLM providers, and preferences

## Setup

### 1. Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android SDK (for Android development)
- API Key from OpenAI or DeepSeek

### 2. Installation

```bash
# Get dependencies
flutter pub get

# Generate Hive adapters
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. Configuration

Create a `.env` file in the project root (optional):

```env
OPENAI_API_KEY=sk-your-api-key-here
LLM_BASE_URL=https://api.openai.com/v1/chat/completions
MODEL=gpt-4o-mini
```

Alternatively, configure the API key directly in the Settings screen of the app.

### 4. Switching LLM Providers

**OpenAI (Default):**
- LLM_BASE_URL: `https://api.openai.com/v1/chat/completions`
- MODEL: `gpt-4o-mini`

**DeepSeek:**
- LLM_BASE_URL: `https://api.deepseek.com/v1/chat/completions`
- MODEL: `deepseek-chat`

You can switch providers in the Settings screen.

## Running the App

```bash
# Run on connected device
flutter run

# Build APK
flutter build apk

# Build iOS (requires macOS)
flutter build ios
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app_router.dart          # Navigation configuration
├── theme.dart               # App theming
├── data/
│   └── prompts.json        # Post templates
├── models/
│   ├── x_action.dart       # Data models
│   └── x_action.g.dart     # Generated Hive adapters
├── screens/
│   ├── home_screen.dart    # Dashboard
│   ├── composer_screen.dart # Content generation
│   ├── log_screen.dart     # Action history
│   └── settings_screen.dart # Configuration
├── services/
│   ├── llm_service.dart    # LLM API integration
│   ├── x_actions_service.dart # X actions handler
│   └── storage_service.dart # Local storage
└── widgets/
    ├── metric_card.dart    # Metric display
    ├── section_card.dart   # Section container
    ├── prompt_selector.dart # Template selector
    └── charts/
        ├── daily_line_chart.dart # Daily activity chart
        └── by_type_bar_chart.dart # Action type chart
```

## Usage

### 1. Configure API Key

1. Open the app
2. Go to **Settings**
3. Select your LLM provider (OpenAI or DeepSeek)
4. Enter your API key
5. Click **Save**
6. Test the connection with **Test API**

### 2. Generate Content

1. Go to **Compose**
2. Enter a topic
3. Select tone and template
4. Click **Genera**
5. Edit the generated text if needed
6. Click **Pubblica su X** to share

### 3. Other Actions

- **Reply**: Enter Tweet ID and reply text
- **Retweet**: Enter Tweet ID
- **Like**: Enter Tweet ID

### 4. View Analytics

- Check the **Home** screen for metrics and charts
- View detailed action log in the **Log** screen

## Technologies

- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management
- **Go Router**: Navigation
- **Hive**: Local database
- **Dio**: HTTP client
- **FL Chart**: Data visualization
- **Material 3**: Modern UI design

## Security Notes

- API keys are stored locally on your device
- No data is sent to third parties except the LLM provider
- All actions are logged locally only

## License

This project is for educational and personal use.
