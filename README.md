# 🤖 Multi-Provider Flutter AI Chatbot

A clean, modern, and extensible Chatbot application built with **Flutter**, featuring dynamic multi-provider AI support (**Google Gemini**, **OpenAI**, **Groq**, and **OpenRouter**).

Repository: [https://github.com/rehan-abc/flutter-ai-chatbot](https://github.com/rehan-abc/flutter-ai-chatbot)

---

## ✨ Key Features

- **Multi-Provider & Model Switching**:
  - **Google Gemini**: `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash`
  - **OpenAI**: `gpt-4o-mini`, `gpt-4o`, `gpt-3.5-turbo`
  - **Groq (Ultra-Fast)**: `llama-3.3-70b-versatile`, `llama-3.1-8b-instant`, `mixtral-8x7b-32768`
  - **OpenRouter**: `meta-llama/llama-3.3-70b-instruct:free`, `claude-3.5-sonnet`, `deepseek-chat`
  - **Custom Models**: Type any model ID for any provider directly in Settings.
- **Provider-Aware Settings Dialog**:
  - Switch providers and models with one tap.
  - Remembers and stores separate API keys for each provider in local device storage (`SharedPreferences`).
  - Direct links to key creation dashboards for each provider.
- **Environment & In-App Key Resolution**:
  - Configure via `.env` file or directly inside the app UI.
  - Automatically masks stored keys for privacy.
- **Multi-Turn Chat History**:
  - Formats conversation context properly across both Gemini and OpenAI-compatible endpoints.
- **Modern Chat Interface**:
  - Color-coded chat bubbles with timestamps and avatars.
  - Dynamic App Bar displaying the currently active provider & model.
  - Quick suggested prompts to start conversations instantly.
  - Long-press to copy message text to clipboard.
  - Auto-scrolling and real-time typing indicators.
  - Clear chat action with confirmation modal.
- **Automated Daily Maintenance**:
  - Configured with a scheduled GitHub Actions workflow for 2 weeks of automated daily updates.

---

## 📁 Project Structure

```text
flutter-ai-chatbot/
├── .github/
│   └── workflows/
│       └── daily-commit.yml      # Automated daily updates workflow for 2 weeks
├── .env                          # Environment file for your API keys (git-ignored)
├── .env.example                  # Sample template for environment variables
├── .gitignore                    # Protects your sensitive keys from Git
├── DAILY_UPDATES.md              # 2-week daily update tracker
├── pubspec.yaml                  # Project dependencies (http, flutter_dotenv, shared_preferences)
├── README.md                     # Complete documentation and user guide
│
├── lib/
│   ├── main.dart                 # Application entry point & theme definition
│   │
│   ├── constants/
│   │   ├── api_constants.dart    # Endpoint constants and default storage keys
│   │   └── app_colors.dart       # Centralized color palette
│   │
│   ├── models/
│   │   ├── ai_provider.dart      # AiProvider enum, model lists, and URLs
│   │   └── chat_message.dart     # Message model with Gemini & OpenAI converters
│   │
│   ├── services/
│   │   ├── chat_service.dart     # Universal AI service for Gemini & OpenAI-compatible APIs
│   │   └── storage_service.dart  # Manages provider, model, and key persistence
│   │
│   └── screens/
│       ├── chat_screen.dart      # Main chat view and reactive UI state
│       └── widgets/
│           ├── settings_dialog.dart   # Modal to switch provider, model, and keys
│           ├── chat_bubble.dart       # Individual chat message bubble
│           └── chat_input_field.dart  # Message input bar and send button
│
└── test/
    └── widget_test.dart          # Smoke tests for the app
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev) (`>= 3.0.0`)
- An API key for at least one supported provider:
  - **Google Gemini**: [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
  - **OpenAI**: [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
  - **Groq**: [console.groq.com/keys](https://console.groq.com/keys)
  - **OpenRouter**: [openrouter.ai/keys](https://openrouter.ai/keys)

---

### 2. Configure Your API Key

#### Option A: In the App Settings (Easiest)
1. Run the app (`flutter run -d chrome`).
2. Tap the **Settings icon (tune) ⚙️** in the top-right corner of the app bar.
3. Select your desired **Provider** and **Model**.
4. Paste your API key and tap **Save Settings**.

#### Option B: In the `.env` file
Add your keys to [.env](file:///.env):
```env
GEMINI_API_KEY=your_gemini_key
OPENAI_API_KEY=your_openai_key
GROQ_API_KEY=your_groq_key
OPENROUTER_API_KEY=your_openrouter_key
```

---

### 3. Run the App

```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Or run on Windows desktop / Android / iOS
flutter run
```

---

## ⚙️ How Provider Switching Works

1. **Storage Layer** ([lib/services/storage_service.dart](file:///lib/services/storage_service.dart)):
   - Saves active provider and active model independently in `SharedPreferences`.
   - Each provider maintains its own key (`api_key_gemini`, `api_key_openai`, `api_key_groq`, `api_key_openrouter`), with fallback to `.env`.
2. **Universal Chat Client** ([lib/services/chat_service.dart](file:///lib/services/chat_service.dart)):
   - Inspects the active provider:
     - If **Gemini**: formats messages using `ChatMessage.toGeminiContent()` and sends to Google's REST API.
     - If **OpenAI / Groq / OpenRouter**: formats messages using `ChatMessage.toOpenAiContent()` and sends to the standard OpenAI-compatible `/chat/completions` endpoint with `Authorization: Bearer <key>`.
3. **Settings UI** ([lib/screens/widgets/settings_dialog.dart](file:///lib/screens/widgets/settings_dialog.dart)):
   - Dropdown selection dynamically updates the model choices and displays provider-specific key fields and instructions.
