// lib/features/tts/tts_strings.dart

class TtsStrings {
  TtsStrings._();

  static String get(Map<String, String> map, String language) {
    return map[language] ?? map['en'] ?? '';
  }

  static const Map<String, String> ready = {
    'en': 'Ready',
    'hi': 'तैयार हूँ',
    'ta': 'தயாராக இருக்கிறேன்',
  };

  static const Map<String, String> listening = {
    'en': 'Listening',
    'hi': 'सुन रही हूँ',
    'ta': 'கேட்கிறேன்',
  };

  static const Map<String, String> flashOn = {
    'en': 'Flashlight on',
    'hi': 'टॉर्च चालू',
    'ta': 'விளக்கு ஆன்',
  };

  static const Map<String, String> flashOff = {
    'en': 'Flashlight off',
    'hi': 'टॉर्च बंद',
    'ta': 'விளக்கு ஆஃப்',
  };

  static const Map<String, String> volUp = {
    'en': 'Volume increased',
    'hi': 'आवाज़ बढ़ाई',
    'ta': 'ஒலி அதிகரிக்கப்பட்டது',
  };

  static const Map<String, String> volDown = {
    'en': 'Volume decreased',
    'hi': 'आवाज़ कम की',
    'ta': 'ஒலி குறைக்கப்பட்டது',
  };

  static const Map<String, String> calling = {
    'en': 'Calling',
    'hi': 'कॉल कर रही हूँ',
    'ta': 'அழைக்கிறேன்',
  };

  static const Map<String, String> contactNotFound = {
    'en': 'Contact not found',
    'hi': 'संपर्क नहीं मिला',
    'ta': 'தொடர்பு கிடைக்கவில்லை',
  };

  static const Map<String, String> alarmSet = {
    'en': 'Alarm set',
    'hi': 'अलार्म लगाया',
    'ta': 'அலாரம் அமைக்கப்பட்டது',
  };

  static const Map<String, String> msgSent = {
    'en': 'Message sent',
    'hi': 'संदेश भेजा',
    'ta': 'செய்தி அனுப்பப்பட்டது',
  };

  static const Map<String, String> opening = {
    'en': 'Opening',
    'hi': 'खोल रही हूँ',
    'ta': 'திறக்கிறேன்',
  };

  static const Map<String, String> appNotFound = {
    'en': 'App not found',
    'hi': 'ऐप नहीं मिला',
    'ta': 'ஆப் கிடைக்கவில்லை',
  };

  static const Map<String, String> navigating = {
    'en': 'Opening navigation',
    'hi': 'नेविगेशन खोल रही हूँ',
    'ta': 'வழிகாட்டல் திறக்கிறேன்',
  };

  static const Map<String, String> wifiSettings = {
    'en': 'Opening WiFi settings',
    'hi': 'वाईफाई सेटिंग खोल रही हूँ',
    'ta': 'வைஃபை அமைப்புகள் திறக்கிறேன்',
  };

  static const Map<String, String> btSettings = {
    'en': 'Opening Bluetooth settings',
    'hi': 'ब्लूटूथ सेटिंग खोल रही हूँ',
    'ta': 'பிளூடூத் அமைப்புகள் திறக்கிறேன்',
  };

  static const Map<String, String> goingHome = {
    'en': 'Going to home screen',
    'hi': 'होम स्क्रीन पर जा रही हूँ',
    'ta': 'முகப்பு திரைக்கு போகிறேன்',
  };

  static const Map<String, String> goingBack = {
    'en': 'Going back',
    'hi': 'वापस जा रही हूँ',
    'ta': 'திரும்பி போகிறேன்',
  };

  static const Map<String, String> locking = {
    'en': 'Locking screen',
    'hi': 'स्क्रीन लॉक कर रही हूँ',
    'ta': 'திரையை பூட்டுகிறேன்',
  };

  static const Map<String, String> unknown = {
    'en': "Sorry, I didn't understand that",
    'hi': 'माफ़ करना, मैं समझ नहीं पाई',
    'ta': 'மன்னிக்கவும், புரியவில்லை',
  };

  static const Map<String, String> help = {
    'en': 'You can say: torch on, call mom, set alarm, volume up',
    'hi': 'आप कह सकते हैं: टॉर्च चालू, माँ को कॉल करो, अलार्म लगाओ',
    'ta': 'நீங்கள் சொல்லலாம்: விளக்கு ஆன், அம்மாவை கூப்பிடு',
  };

  static const Map<String, String> cancelled = {
    'en': 'Cancelled',
    'hi': 'रद्द किया',
    'ta': 'ரத்து செய்யப்பட்டது',
  };

  static const Map<String, String> askTime = {
    'en': 'What time?',
    'hi': 'किस समय के लिए?',
    'ta': 'என்ன நேரத்திற்கு?',
  };

  static const Map<String, String> askContact = {
    'en': 'Which contact?',
    'hi': 'किसे कॉल करूँ?',
    'ta': 'யாரை அழைக்கணும்?',
  };

  static const Map<String, String> askMessage = {
    'en': 'What message?',
    'hi': 'क्या संदेश भेजूँ?',
    'ta': 'என்ன செய்தி அனுப்பணும்?',
  };

  static const Map<String, String> askDestination = {
    'en': 'Where to navigate?',
    'hi': 'कहाँ जाना है?',
    'ta': 'எங்கே போகணும்?',
  };

  static const Map<String, String> askApp = {
    'en': 'Which app?',
    'hi': 'कौन सा ऐप खोलूँ?',
    'ta': 'என்ன ஆப் திற?',
  };

  static const Map<String, String> generalError = {
    'en': 'Sorry, something went wrong',
    'hi': 'माफ़ करना, कुछ गड़बड़ हुई',
    'ta': 'மன்னிக்கவும், ஏதோ தவறு நடந்தது',
  };
}
