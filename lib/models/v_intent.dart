// STUB — lib/models/v_intent.dart
// Owner: Lead. Replace with production implementation.
// Dev 3 uses this read-only.

enum VIntent {
  flashlightOn,
  flashlightOff,
  volumeUp,
  volumeDown,
  callContact,
  setAlarm,
  sendWhatsapp,
  openApp,
  navigate,
  toggleWifi,
  toggleBluetooth,
  goHome,
  goBack,
  lockScreen,
  takeScreenshot,
  typeText,
  closeApp,
  pickIndex,
  readScreen,
  unknown,
}

extension VIntentX on VIntent {
  static VIntent fromString(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'FLASHLIGHT_ON':    return VIntent.flashlightOn;
      case 'FLASHLIGHT_OFF':   return VIntent.flashlightOff;
      case 'VOLUME_UP':        return VIntent.volumeUp;
      case 'VOLUME_DOWN':      return VIntent.volumeDown;
      case 'CALL_CONTACT':     return VIntent.callContact;
      case 'SET_ALARM':        return VIntent.setAlarm;
      case 'SEND_WHATSAPP':    return VIntent.sendWhatsapp;
      case 'OPEN_APP':         return VIntent.openApp;
      case 'NAVIGATE':         return VIntent.navigate;
      case 'TOGGLE_WIFI':      return VIntent.toggleWifi;
      case 'TOGGLE_BLUETOOTH': return VIntent.toggleBluetooth;
      case 'GO_HOME':          return VIntent.goHome;
      case 'GO_BACK':          return VIntent.goBack;
      case 'LOCK_SCREEN':      return VIntent.lockScreen;
      case 'TAKE_SCREENSHOT':  return VIntent.takeScreenshot;
      case 'TYPE_TEXT':        return VIntent.typeText;
      case 'CLOSE_APP':       return VIntent.closeApp;
      case 'PICK_INDEX':       return VIntent.pickIndex;
      case 'READ_SCREEN':      return VIntent.readScreen;
      default:                 return VIntent.unknown;
    }
  }

  String toJsonKey() {
    switch (this) {
      case VIntent.flashlightOn:    return 'FLASHLIGHT_ON';
      case VIntent.flashlightOff:   return 'FLASHLIGHT_OFF';
      case VIntent.volumeUp:        return 'VOLUME_UP';
      case VIntent.volumeDown:      return 'VOLUME_DOWN';
      case VIntent.callContact:     return 'CALL_CONTACT';
      case VIntent.setAlarm:        return 'SET_ALARM';
      case VIntent.sendWhatsapp:    return 'SEND_WHATSAPP';
      case VIntent.openApp:         return 'OPEN_APP';
      case VIntent.navigate:        return 'NAVIGATE';
      case VIntent.toggleWifi:      return 'TOGGLE_WIFI';
      case VIntent.toggleBluetooth: return 'TOGGLE_BLUETOOTH';
      case VIntent.goHome:          return 'GO_HOME';
      case VIntent.goBack:          return 'GO_BACK';
      case VIntent.lockScreen:      return 'LOCK_SCREEN';
      case VIntent.takeScreenshot:  return 'TAKE_SCREENSHOT';
      case VIntent.typeText:        return 'TYPE_TEXT';
      case VIntent.closeApp:       return 'CLOSE_APP';
      case VIntent.pickIndex:       return 'PICK_INDEX';
      case VIntent.readScreen:      return 'READ_SCREEN';
      case VIntent.unknown:         return 'UNKNOWN';
    }
  }
}
