<div align="center">

# वाणीमित्र · VaaniMitra

### *Voice Friend — Fully Offline Multilingual Voice Assistant for Android*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-13%20(API%2033)-3DDC84?logo=android)](https://developer.android.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Operational Cost](https://img.shields.io/badge/Operational%20Cost-%240%2Fuser%2Fmonth-brightgreen)](/)

**Hindi · English · Zero Internet · Zero Cost**

*Built for the 2.5 billion people that existing voice assistants fail.*

</div>

---

## The Problem

Over **2.5 billion people** globally cannot effectively use smartphone voice assistants. The reasons:

- No internet access
- Unsupported language (Hindi, Tamil, and hundreds more)
- Inability to read or type
- Visual impairment
- Age

Existing assistants (Google Assistant, Siri, Alexa) require internet, support limited Indian languages, cannot handle code-switching between Hindi/Tamil/English, and send all audio to remote servers.

---

## Our Solution

Vanimitra is a **fully offline** Android voice assistant that:

- 🎙️ **Wakes on keyword "Vaani"** — no button press needed
- 🌐 **Understands Hindi, Tamil, English, and code-switched speech**
- ⚡ **Executes 15 device actions** using a two-tier AI pipeline (rule engine + local LLM)
- 🔁 **Responds in the same language the user spoke**
- 🧠 **Learns user vocabulary** (contact names, place aliases) over time
- ✈️ **Works in airplane mode** — zero internet after setup
- 💰 **Costs $0/user/month** — 100% on-device, zero cloud infrastructure

---

## Target Users

| User | Why Vanimitra |
|------|--------------|
| Visually impaired | Cannot see screen — voice is the only interface |
| Elderly | Unfamiliar with touchscreens, prefer speaking |
| Low-literacy | Cannot read or type — voice commands in native language |
| Rural | No reliable internet — offline-first is mandatory |
| Hindi/Tamil speakers | No good offline assistant exists for their language |

---

## Architecture

### Two-Tier AI Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│              PORCUPINE WAKE WORD — "Vaani"                      │
│              Always-on · <50ms · <1% battery                    │
└─────────────────────────────┬───────────────────────────────────┘
                              │ wake word detected
                              ▼
              Earcon chime + HapticFeedback + WakeWord stops
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              SPEECH-TO-TEXT (Android Native)                    │
│              Max 8s recording · 2s pause threshold              │
│              Output: Devanagari / Tamil / English text          │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
            RULE ENGINE            LANGUAGE DETECT
           (fast path)             hi / ta / en
           <50ms, no model
                    │ HIT (~80%)    MISS
                    │               ▼
                    │         QWEN 0.5B GGUF
                    │         Q4_K_M · 397MB
                    │         nCtx=512 · temp=0.1
                    │         ~3-6s on Unisoc T606
                    └──────────────┘
                              │
                              ▼
                    INTENT WHITELIST GUARD
                    15 intents · malformed → UNKNOWN
                              │
                              ▼
                    DIALOGUE STATE MACHINE
                    Clarification if params missing
                    Max 2 attempts · 8s timeout
                              │
                              ▼
                    ACTION EXECUTOR 
                    Executes Android action
                    TTS before + after every action
                              │
                              ▼
                    PERSONALISATION LOOP
                    SQLite cache · usage logging
                    Nightly on-device fine-tune trigger
```

Minimum Version Requirement : Android 7

### Supported Intents

| Intent | Action | Params |
|--------|--------|--------|
| `FLASHLIGHT_ON` | Turn on torch | — |
| `FLASHLIGHT_OFF` | Turn off torch | — |
| `VOLUME_UP` | +15% volume | — |
| `VOLUME_DOWN` | -15% volume | — |
| `CALL_CONTACT` | Open dialer | `contact` |
| `SET_ALARM` | Set alarm | `time` (HH:MM) |
| `SEND_WHATSAPP` | Open WhatsApp chat | `contact`, `message` |
| `OPEN_APP` | Launch app | `app` |
| `NAVIGATE` | Open Google Maps | `destination` |
| `TOGGLE_WIFI` | Open WiFi settings* | `state` |
| `TOGGLE_BLUETOOTH` | Open BT settings* | `state` |
| `GO_HOME` | Home screen | — |
| `GO_BACK` | Navigate back | — |
| `LOCK_SCREEN` | Open security settings* | — |
| `TAKE_SCREENSHOT` | Graceful decline (v2) | — |


---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x + Dart 3 |
| STT | Indic Whisper (`speech_to_text`) |
| LLM | Qwen2.5-0.5B-Instruct Q4_K_M GGUF via `llama_sdk` |
| LLM Training | LoRA fine-tune on AWS SageMaker (ml.g4dn.xlarge) |
| TTS | Android System TTS (`flutter_tts`) — hi-IN, en-IN |
| Cache / DB | SQLite via `sqflite` |
| Contacts | `contacts_service` |
| Target Device | Infinix Hot 40i · Unisoc T606 · Android 13 |

---

## Privacy

- **No audio ever leaves the device** — not during setup, not during use
- STT runs locally, in an offline mode
- The LLM is a GGUF file stored in the app's private data directory
- Contact names are stored in a local SQLite database — never synced
- Analytics are in-memory only — cleared on app restart



<div align="center">

*Built in one night - for people who deserve better technology.*


</div>
