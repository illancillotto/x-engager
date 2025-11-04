# Quick Start Guide

## Prerequisites

- Flutter SDK installed and configured
- Android device/emulator (or iOS device/simulator)
- API Key from OpenAI or DeepSeek

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Hive Adapters

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App

```bash
# On Android
flutter run

# Or build APK
flutter build apk
```

### 4. Configure API Key

Once the app is running:

1. Navigate to **Settings** tab (bottom navigation)
2. Choose your LLM provider:
   - **OpenAI** (default): gpt-4o-mini
   - **DeepSeek**: deepseek-chat
3. Enter your API key
4. Click **Save**
5. Test with **Test API** button

### 5. Create Your First Post

1. Go to **Compose** tab
2. Enter a topic (e.g., "AI trends")
3. Select tone (ironico, professionale, meme, etc.)
4. Choose a template
5. Click **Genera**
6. Edit if needed
7. Click **Pubblica su X** to share

## Features Overview

### Home Screen
- Dashboard with metrics (Posts, Likes, Retweets, Replies)
- Activity chart (last 14 days)
- Actions by type chart
- Recent actions list

### Composer Screen
- AI-powered content generation
- Multiple tones and templates
- Character counter
- Post to X
- Reply, Retweet, and Like actions

### Log Screen
- Full action history
- Filter by action type
- Swipe to delete
- Clear all option

### Settings Screen
- LLM provider selection (OpenAI/DeepSeek)
- API key configuration
- Test API connection
- Default preferences (tone, hashtags)

## Templates

1. **short_post**: Brief ironic/brilliant post (220 chars, 2 hashtags)
2. **reply_helpful**: Helpful and courteous reply (200 chars)
3. **thread_3**: 3-part thread with hook and question (230 chars per part)
4. **meme_style**: Fun meme-style post (180 chars, 2 emojis)
5. **professional**: Professional informative post (240 chars, 3 hashtags)

## Notes

- All data is stored locally on your device
- API keys are saved in local Hive database
- No data is sent to third parties except your chosen LLM provider
- The app uses web intents to interact with X (Twitter)

## Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### API Connection Issues
- Check your internet connection
- Verify API key is correct
- Check provider URL in Settings

### Missing Dependencies
```bash
flutter doctor
```

## Support

For issues, please check:
- Flutter version: `flutter --version`
- Run: `flutter doctor`
- Check the README.md for detailed documentation
