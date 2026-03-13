<div align="center">

# वाणीमित्र · VANIMITRA

### *Voice Friend — Fully Offline Multilingual Voice Assistant for Android*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-13%20(API%2033)-3DDC84?logo=android)](https://developer.android.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Operational Cost](https://img.shields.io/badge/Operational%20Cost-%240%2Fuser%2Fmonth-brightgreen)](/)

**Hindi · Tamil · English · Zero Internet · Zero Cost**

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
                    ACTION EXECUTOR (Dev 3)
                    Executes Android action
                    TTS before + after every action
                              │
                              ▼
                    PERSONALISATION LOOP
                    SQLite cache · usage logging
                    Nightly on-device fine-tune trigger
```

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

*Android 13 restriction — direct toggle not permitted by OS.

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x + Dart 3 |
| Wake Word | Porcupine (`porcupine_flutter`) — keyword: "Vaani" |
| STT | Android Native (`speech_to_text`) |
| LLM | Qwen2.5-0.5B-Instruct Q4_K_M GGUF via `llama_sdk` |
| LLM Training | LoRA fine-tune on AWS SageMaker (ml.g4dn.xlarge) |
| TTS | Android System TTS (`flutter_tts`) — hi-IN, ta-IN, en-IN |
| Cache / DB | SQLite via `sqflite` |
| Contacts | `contacts_service` |
| Actions | `torch_light`, `volume_controller`, `url_launcher`, `android_intent_plus` |
| Target Device | Infinix Hot 40i · Unisoc T606 · Android 13 |

---

## Repository Structure

```
vanimitra/
├── lib/
│   ├── main.dart                        ← entry point only
│   ├── app/
│   │   ├── app.dart                     ← VanimitraApp MaterialApp
│   │   ├── constants.dart               ← ALL magic values
│   │   └── secrets.dart.example         ← Picovoice key template
│   ├── models/                          ← shared contracts (read-only)
│   │   ├── v_intent.dart                ← VIntent enum
│   │   ├── parsed_command.dart          ← Dev2→Dev3 contract
│   │   ├── action_result.dart           ← Dev3→Dev2 contract
│   │   └── cache_entry.dart
│   ├── core/                            ← Dev 2 owns
│   │   ├── wake_word/
│   │   ├── stt/
│   │   ├── llm/
│   │   ├── cache/
│   │   ├── dialogue/
│   │   ├── analytics/
│   │   └── personalisation/
│   ├── features/                        ← Dev 3 owns
│   │   ├── tts/
│   │   │   ├── tts_service.dart         ← System TTS wrapper
│   │   │   └── tts_strings.dart         ← all spoken strings × 3 languages
│   │   └── actions/
│   │       ├── action_executor.dart     ← 15 intent handlers
│   │       └── app_registry.dart        ← app name → package ID
│   └── ui/                              ← Dev 3 owns
│       ├── home/
│       │   ├── home_screen.dart
│       │   ├── home_controller.dart
│       │   └── widgets/
│       ├── dialogs/
│       │   ├── analytics_dialog.dart    ← triple-tap live telemetry
│       │   └── mapping_proposal_sheet.dart
│       └── theme/
│           └── app_theme.dart
├── assets/
│   ├── wake_word/
│   │   └── vaani_android.ppn            ← gitignored — download per-device
│   └── earcon/
│       └── chime.mp3                    ← wake word feedback chime
├── ml/                                  ← Dev 1 owns
│   ├── data/
│   │   ├── dataset_gen.py
│   │   └── vanimitra_test.json          ← 60 evaluation cases
│   ├── training/
│   │   ├── train.py                     ← SageMaker LoRA fine-tune
│   │   ├── sagemaker_launch.py
│   │   └── merge_lora.py
│   └── evaluation/
│       ├── accuracy_test.py
│       ├── latency_test.py
│       └── cost_model.py
├── pubspec.yaml
└── DEVLOG.md                            ← each dev logs blockers + completions
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Android NDK 28.0.12433566
- CMake 3.31.0
- A Picovoice account (free tier) for the wake word engine
- Android device running API 24+ (Android 7+)


## Privacy

- **No audio ever leaves the device** — not during setup, not during use
- The wake word engine runs locally via Porcupine (after one-time key activation)
- STT is Android's native on-device engine
- The LLM is a GGUF file stored in the app's private data directory
- Contact names are stored in a local SQLite database — never synced
- Analytics are in-memory only — cleared on app restart



<div align="center">

*Built in one night for people who deserve better technology.*

**"My grandmother in Chennai. 74 years old. Cannot read. Cannot type. Speaks Tamil.
Every existing voice assistant fails her. Vanimitra works for her — in her language,
without internet, without an account, without anyone's data leaving her phone."**

</div>