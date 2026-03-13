import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volume_controller/volume_controller.dart';

import 'package:vanimitra/features/tts/tts_service.dart';
import 'package:vanimitra/features/tts/tts_strings.dart';
import 'package:vanimitra/models/action_result.dart';
import 'package:vanimitra/models/parsed_command.dart';
import 'package:vanimitra/models/v_intent.dart';

import 'app_registry.dart';

class ActionExecutor {
  static final instance = ActionExecutor._internal();
  ActionExecutor._internal();

  late TtsService _tts;
  final VolumeController _volumeController = VolumeController();

  void init(TtsService tts) {
    _tts = tts;
  }

  Future<ActionResult> processIntent(ParsedCommand cmd) async {
    switch (cmd.intent) {
      case VIntent.flashlightOn:       return _flashlightOn(cmd.language);
      case VIntent.flashlightOff:      return _flashlightOff(cmd.language);
      case VIntent.volumeUp:           return _volumeUp(cmd.language);
      case VIntent.volumeDown:         return _volumeDown(cmd.language);
      case VIntent.callContact:        return _callContact(cmd.params, cmd.language);
      case VIntent.setAlarm:           return _setAlarm(cmd.params, cmd.language);
      case VIntent.sendWhatsapp:       return _sendWhatsapp(cmd.params, cmd.language);
      case VIntent.openApp:            return _openApp(cmd.params, cmd.language);
      case VIntent.navigate:           return _navigate(cmd.params, cmd.language);
      case VIntent.toggleWifi:         return _toggleWifi(cmd.params, cmd.language);
      case VIntent.toggleBluetooth:    return _toggleBluetooth(cmd.params, cmd.language);
      case VIntent.goHome:             return _goHome(cmd.language);
      case VIntent.goBack:             return _goBack(cmd.language);
      case VIntent.lockScreen:         return _lockScreen(cmd.language);
      case VIntent.takeScreenshot:     return _takeScreenshot(cmd.language);
      case VIntent.unknown:
      default:
        await _tts.speak(TtsStrings.unknown, cmd.language);
        return ActionResult.fail('unknown_intent');
    }
  }

  // ─── FLASHLIGHT ───────────────────────────────────────────────────────────

  Future<ActionResult> _flashlightOn(String lang) async {
    await _tts.speakEarcon();
    try {
      await TorchLight.enableTorch();
      await _tts.speak(TtsStrings.flashOn, lang);
      return ActionResult.ok(detail: 'flashlight');
    } on PlatformException catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('torch_error: $e');
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('torch_error: $e');
    }
  }

  Future<ActionResult> _flashlightOff(String lang) async {
    await _tts.speakEarcon();
    try {
      await TorchLight.disableTorch();
      await _tts.speak(TtsStrings.flashOff, lang);
      return ActionResult.ok(detail: 'flashlight');
    } on PlatformException catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('torch_error: $e');
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('torch_error: $e');
    }
  }

  // ─── VOLUME ───────────────────────────────────────────────────────────────

  Future<ActionResult> _volumeUp(String lang) async {
    await _tts.speakEarcon();
    try {
      final double v = await _volumeController.getVolume();
      final double nv = (v + 0.15).clamp(0.0, 1.0);
      _volumeController.setVolume(nv, showSystemUI: false);
      await _tts.speak(TtsStrings.volUp, lang);
      return ActionResult.ok(detail: '${(nv * 100).toInt()}%');
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('volume_error');
    }
  }

  Future<ActionResult> _volumeDown(String lang) async {
    await _tts.speakEarcon();
    try {
      final double v = await _volumeController.getVolume();
      final double nv = (v - 0.15).clamp(0.0, 1.0);
      _volumeController.setVolume(nv, showSystemUI: false);
      await _tts.speak(TtsStrings.volDown, lang);
      return ActionResult.ok(detail: '${(nv * 100).toInt()}%');
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('volume_error');
    }
  }

  // ─── CALL ─────────────────────────────────────────────────────────────────
  // FIX #2: Resolve contact name → phone number via flutter_contacts
  // before dialling. Never pass raw text to tel: URI.

  Future<ActionResult> _callContact(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String contactName = params['contact']?.toString().trim() ?? '';
    if (contactName.isEmpty) {
      await _tts.speak(TtsStrings.askContact, lang);
      return ActionResult.fail('no_contact');
    }

    await _tts.speakComposed(TtsStrings.calling, contactName, lang);

    // Check CALL_PHONE permission
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final result = await Permission.phone.request();
      if (!result.isGranted) {
        await _tts.speak(TtsStrings.generalError, lang);
        return ActionResult.fail('permission_denied');
      }
    }

    // Resolve name to phone number
    final String? phoneNumber = await _resolveContactNumber(contactName);

    if (phoneNumber == null || phoneNumber.isEmpty) {
      // Couldn't find in contacts — speak error
      await _tts.speak(TtsStrings.contactNotFound, lang);
      return ActionResult.fail('contact_not_found: $contactName');
    }

    try {
      final Uri uri = Uri.parse('tel:$phoneNumber');
      await launchUrl(uri);
      return ActionResult.ok(detail: contactName);
    } catch (e) {
      await _tts.speak(TtsStrings.contactNotFound, lang);
      return ActionResult.fail('call_failed: $e');
    }
  }

  /// Looks up a contact by name in device contacts.
  /// Returns the best matching phone number or null.
  Future<String?> _resolveContactNumber(String name) async {
    try {
      final permission = await Permission.contacts.status;
      if (!permission.isGranted) {
        await Permission.contacts.request();
      }
      if (!await Permission.contacts.isGranted) return null;

      // flutter_contacts 1.1.9 does not have a query param —
      // fetch all contacts then filter in Dart
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      if (contacts.isEmpty) return null;

      final nameLower = name.toLowerCase();

      // 1. Exact match
      Contact? best;
      for (final c in contacts) {
        if (c.displayName.toLowerCase() == nameLower) { best = c; break; }
      }
      // 2. Starts-with
      if (best == null) {
        for (final c in contacts) {
          if (c.displayName.toLowerCase().startsWith(nameLower)) { best = c; break; }
        }
      }
      // 3. Contains
      if (best == null) {
        for (final c in contacts) {
          if (c.displayName.toLowerCase().contains(nameLower)) { best = c; break; }
        }
      }

      if (best == null || best.phones.isEmpty) return null;

      // Prefer mobile number
      final mobile = best.phones.firstWhere(
        (p) => p.label == PhoneLabel.mobile,
        orElse: () => best!.phones.first,
      );

      // Clean number: remove spaces, dashes, parens — keep + prefix
      return mobile.number.replaceAll(RegExp(r'[\s\-()]'), '');
    } catch (_) {
      return null;
    }
  }

  // ─── ALARM ────────────────────────────────────────────────────────────────

  Future<ActionResult> _setAlarm(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String timeStr = params['time']?.toString().trim() ?? '';
    if (timeStr.isEmpty) {
      await _tts.speak(TtsStrings.askTime, lang);
      return ActionResult.fail('no_time_provided');
    }

    await _tts.speakDynamic('Alarm for $timeStr', lang);

    try {
      final List<String> parts = timeStr.split(':');
      final int hour = int.tryParse(parts[0].trim()) ?? 7;
      final int minute = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      final int safeHour = hour.clamp(0, 23);
      final int safeMinute = minute.clamp(0, 59);

      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': safeHour,
          'android.intent.extra.alarm.MINUTES': safeMinute,
          'android.intent.extra.alarm.SKIP_UI': true,
          'android.intent.extra.alarm.MESSAGE': 'Vanimitra',
        },
      );
      await intent.launch();
      await _tts.speak(TtsStrings.alarmSet, lang);
      return ActionResult.ok(detail: timeStr);
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('alarm_failed: $e');
    }
  }

  // ─── WHATSAPP ─────────────────────────────────────────────────────────────
  // FIX #7: Also try resolving contact name to number for WhatsApp

  Future<ActionResult> _sendWhatsapp(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String contact = params['contact']?.toString().trim() ?? '';
    final String message = params['message']?.toString().trim() ?? '';

    if (contact.isEmpty) {
      await _tts.speak(TtsStrings.askContact, lang);
      return ActionResult.fail('no_contact');
    }

    await _tts.speakComposed(TtsStrings.calling, contact, lang);

    try {
      // Try to get a numeric number — either already numeric or resolve from contacts
      String clean = contact.replaceAll(RegExp(r'[^\d+]'), '');

      if (clean.isEmpty) {
        // Alphabetic name — look up in contacts
        final resolved = await _resolveContactNumber(contact);
        if (resolved != null) {
          clean = resolved.replaceAll(RegExp(r'[^\d+]'), '');
        }
      }

      if (clean.isEmpty) {
        await _tts.speak(TtsStrings.contactNotFound, lang);
        return ActionResult.fail('no_numeric_contact: $contact');
      }

      final String encoded = Uri.encodeComponent(message);
      final Uri uri = Uri.parse('https://wa.me/$clean?text=$encoded');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _tts.speak(TtsStrings.msgSent, lang);
      return ActionResult.ok(detail: contact);
    } catch (e) {
      await _tts.speak(TtsStrings.contactNotFound, lang);
      return ActionResult.fail('whatsapp_failed: $e');
    }
  }

  // ─── OPEN APP ─────────────────────────────────────────────────────────────
  // FIX #4: Use ACTION_MAIN with CATEGORY_LAUNCHER — correct way to launch apps.
  // Do NOT use package + action alone (that opens the app's default activity
  // which can be power/settings on some OEM ROMs).

  Future<ActionResult> _openApp(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String appName = (params['app']?.toString() ?? '').toLowerCase().trim();

    if (appName.isEmpty) {
      await _tts.speak(TtsStrings.askApp, lang);
      return ActionResult.fail('no_app_name');
    }

    await _tts.speakComposed(TtsStrings.opening, appName, lang);

    final String? package = AppRegistry.resolvePackage(appName);
    if (package == null) {
      await _tts.speak(TtsStrings.appNotFound, lang);
      return ActionResult.fail('unknown_app: $appName');
    }

    // For camera, try multiple OEM package IDs
    final candidates = (appName == 'camera')
        ? AppRegistry.cameraPackageCandidates()
        : [package];

    for (final pkg in candidates) {
      try {
        // CATEGORY_LAUNCHER ensures we open the home/launcher activity
        // not some internal activity (fixes "power on/off" bug on Unisoc)
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: pkg,
          category: 'android.intent.category.LAUNCHER',
          flags: <int>[
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
          ],
        );
        await intent.launch();
        return ActionResult.ok(detail: appName);
      } catch (_) {
        // Try next candidate
        continue;
      }
    }

    // All candidates failed
    await _tts.speak(TtsStrings.appNotFound, lang);
    return ActionResult.fail('app_launch_failed: $appName');
  }

  // ─── NAVIGATE ─────────────────────────────────────────────────────────────

  Future<ActionResult> _navigate(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String dest = params['destination']?.toString().trim() ?? '';
    if (dest.isEmpty) {
      await _tts.speak(TtsStrings.askDestination, lang);
      return ActionResult.fail('no_destination');
    }

    await _tts.speak(TtsStrings.navigating, lang);

    try {
      final String encoded = Uri.encodeComponent(dest);
      final Uri uri = Uri.parse('google.navigation:q=$encoded');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final Uri fallback = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded',
        );
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
      return ActionResult.ok(detail: dest);
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('navigate_failed: $e');
    }
  }

  // ─── WIFI ────────────────────────────────────────────────────────────────

  Future<ActionResult> _toggleWifi(
    Map<String, dynamic> params,
    String lang,
  ) async {
    await _tts.speakEarcon();
    try {
      await _tts.speak(TtsStrings.wifiSettings, lang);
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      await intent.launch();
      return ActionResult.ok(detail: params['state']?.toString());
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('wifi_settings_failed: $e');
    }
  }

  // ─── BLUETOOTH ───────────────────────────────────────────────────────────

  Future<ActionResult> _toggleBluetooth(
    Map<String, dynamic> params,
    String lang,
  ) async {
    await _tts.speakEarcon();
    try {
      await _tts.speak(TtsStrings.btSettings, lang);
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.BLUETOOTH_SETTINGS',
      );
      await intent.launch();
      return ActionResult.ok(detail: params['state']?.toString());
    } catch (e) {
      await _tts.speak(TtsStrings.generalError, lang);
      return ActionResult.fail('bt_settings_failed: $e');
    }
  }

  // ─── GO HOME ─────────────────────────────────────────────────────────────

  Future<ActionResult> _goHome(String lang) async {
    await _tts.speakEarcon();
    await _tts.speak(TtsStrings.goingHome, lang);
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.HOME',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return ActionResult.ok(detail: 'home');
    } catch (e) {
      return ActionResult.fail('go_home_failed: $e');
    }
  }

  // ─── GO BACK ─────────────────────────────────────────────────────────────

  Future<ActionResult> _goBack(String lang) async {
    await _tts.speakEarcon();
    await _tts.speak(TtsStrings.goingBack, lang);
    try {
      await SystemChannels.navigation.invokeMethod<void>('SystemNavigator.pop');
      return ActionResult.ok(detail: 'back');
    } catch (e) {
      return ActionResult.fail('go_back_failed: $e');
    }
  }

  // ─── LOCK SCREEN ─────────────────────────────────────────────────────────

  Future<ActionResult> _lockScreen(String lang) async {
    await _tts.speakEarcon();
    await _tts.speak(TtsStrings.locking, lang);
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.SECURITY_SETTINGS',
      );
      await intent.launch();
      return ActionResult.ok(detail: 'lock');
    } catch (e) {
      return ActionResult.fail('lock_failed: $e');
    }
  }

  // ─── TAKE SCREENSHOT ─────────────────────────────────────────────────────
  // FIX #3: Was silently failing with no TTS. Now speaks a message.

  Future<ActionResult> _takeScreenshot(String lang) async {
    // MediaProjection needs user permission — not safe for demo.
    // Speak a helpful message then fail gracefully. Never crash.
    await _tts.speak(TtsStrings.screenshotUnavailable, lang);
    return ActionResult.fail('screenshot_needs_accessibility');
  }
}
