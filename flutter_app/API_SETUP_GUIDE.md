# API Setup & Configuration Guide

This document explains how to set up the Groq API key required for the transcription model.

## 1. Get Google Groq API Key
We use the Groq API (running Whisper-large-v3) for fast and accurate Arabic audio transcription.
1. Go to the [GroqCloud Console](https://console.groq.com/).
2. Sign up or log in.
3. Navigate to **API Keys** section.
4. Click on **Create API Key**.
5. Copy the generated API Key. *Keep this key safe and do not share it publicly.*

## 2. In-App Configuration
The app allows users to input their own API key directly from the Settings screen.
- Launch the App.
- Open the Drawer menu and go to **الإعدادات** (Settings).
- Paste your Groq API Key into the designated field.
- The app will securely save the key using `shared_preferences`.

## 3. Rate Limits & Limitations
- **File size**: The Groq API supports files up to 25MB per request. Our app automatically uses FFmpeg to chunk larger files into < 25MB segments.
- **Rate limiting**: Ensure your tier supports concurrent request volumes if multiple large files are uploaded. We have handled API 429 Rate Limits by using adaptive delays and Exponential Backoff.

## 4. Replacing Hardcoded Default (Optional)
If you want to ship a default API key (not recommended for public release unless utilizing a backend proxy):
You can override the default in `lib/providers/settings_provider.dart` or fetch it dynamically from a remote configuration server (e.g., Firebase Remote Config) to ensure security.
