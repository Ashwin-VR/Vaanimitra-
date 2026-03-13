enum VIntent {
  flashlightOn, flashlightOff,
  volumeUp, volumeDown,
  callContact,
  setAlarm,
  sendWhatsapp,
  openApp,
  navigate,
  toggleWifi,
  toggleBluetooth,
  goHome, goBack,
  lockScreen,
  takeScreenshot,
  unknown,
}

extension VIntentX on VIntent {
  static VIntent fromString(String raw) {
    const map = {
      'FLASHLIGHT_ON'   : VIntent.flashlightOn,
      'FLASHLIGHT_OFF'  : VIntent.flashlightOff,
      'VOLUME_UP'       : VIntent.volumeUp,
      'VOLUME_DOWN'     : VIntent.volumeDown,
      'CALL_CONTACT'    : VIntent.callContact,
      'SET_ALARM'       : VIntent.setAlarm,
      'SEND_WHATSAPP'   : VIntent.sendWhatsapp,
      'OPEN_APP'        : VIntent.openApp,
      'NAVIGATE'        : VIntent.navigate,
      'TOGGLE_WIFI'     : VIntent.toggleWifi,
      'TOGGLE_BLUETOOTH': VIntent.toggleBluetooth,
      'GO_HOME'         : VIntent.goHome,
      'GO_BACK'         : VIntent.goBack,
      'LOCK_SCREEN'     : VIntent.lockScreen,
      'TAKE_SCREENSHOT' : VIntent.takeScreenshot,
    };
    return map[raw.toUpperCase()] ?? VIntent.unknown;
  }

  String toJsonKey() {
    const map = {
      VIntent.flashlightOn   : 'FLASHLIGHT_ON',
      VIntent.flashlightOff  : 'FLASHLIGHT_OFF',
      VIntent.volumeUp       : 'VOLUME_UP',
      VIntent.volumeDown     : 'VOLUME_DOWN',
      VIntent.callContact    : 'CALL_CONTACT',
      VIntent.setAlarm       : 'SET_ALARM',
      VIntent.sendWhatsapp   : 'SEND_WHATSAPP',
      VIntent.openApp        : 'OPEN_APP',
      VIntent.navigate       : 'NAVIGATE',
      VIntent.toggleWifi     : 'TOGGLE_WIFI',
      VIntent.toggleBluetooth: 'TOGGLE_BLUETOOTH',
      VIntent.goHome         : 'GO_HOME',
      VIntent.goBack         : 'GO_BACK',
      VIntent.lockScreen     : 'LOCK_SCREEN',
      VIntent.takeScreenshot : 'TAKE_SCREENSHOT',
      VIntent.unknown        : 'UNKNOWN',
    };
    return map[this] ?? 'UNKNOWN';
  }
}
