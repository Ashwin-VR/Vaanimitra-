// lib/features/actions/action_executor.dart

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
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

  // Single VolumeController instance — avoids repeated platform channel init
  final VolumeController _volumeController = VolumeController();

  void init(TtsService tts) {
    _tts = tts;
  }

  Future<ActionResult> processIntent(ParsedCommand cmd) async {
    switch (cmd.intent) {
      case VIntent.flashlightOn:
        return _flashlightOn(cmd.language);
      case VIntent.flashlightOff:
        return _flashlightOff(cmd.language);
      case VIntent.volumeUp:
        return _volumeUp(cmd.language);
      case VIntent.volumeDown:
        return _volumeDown(cmd.language);
      case VIntent.callContact:
        return _callContact(cmd.params, cmd.language);
      case VIntent.setAlarm:
        return _setAlarm(cmd.params, cmd.language);
      case VIntent.sendWhatsapp:
        return _sendWhatsapp(cmd.params, cmd.language);
      case VIntent.openApp:
        return _openApp(cmd.params, cmd.language);
      case VIntent.navigate:
        return _navigate(cmd.params, cmd.language);
      case VIntent.toggleWifi:
        return _toggleWifi(cmd.params, cmd.language);
      case VIntent.toggleBluetooth:
        return _toggleBluetooth(cmd.params, cmd.language);
      case VIntent.goHome:
        return _goHome(cmd.language);
      case VIntent.goBack:
        return _goBack(cmd.language);
      case VIntent.lockScreen:
        return _lockScreen(cmd.language);
      case VIntent.takeScreenshot:
        return _takeScreenshot(cmd.language);
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

  Future<ActionResult> _callContact(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String contact = params['contact']?.toString().trim() ?? '';
    if (contact.isEmpty) {
      // USER-FACING: tell them we need a contact name/number
      await _tts.speak(TtsStrings.askContact, lang);
      return ActionResult.fail('no_contact');
    }
    await _tts.speakComposed(TtsStrings.calling, contact, lang);

    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final result = await Permission.phone.request();
      if (!result.isGranted) {
        await _tts.speak(TtsStrings.generalError, lang);
        return ActionResult.fail('permission_denied');
      }
    }

    try {
      final Uri uri = Uri.parse('tel:$contact');
      await launchUrl(uri);
      return ActionResult.ok(detail: contact);
    } catch (e) {
      await _tts.speak(TtsStrings.contactNotFound, lang);
      return ActionResult.fail('call_failed: $e');
    }
  }

  // ─── ALARM ───────────────────────────────────────────────────────────────

  Future<ActionResult> _setAlarm(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String timeStr = params['time']?.toString().trim() ?? '';

    // USER-FACING: if no time provided, ask for it (DPR §11 + TtsStrings.askTime)
    if (timeStr.isEmpty) {
      await _tts.speak(TtsStrings.askTime, lang);
      return ActionResult.fail('no_time_provided');
    }

    await _tts.speakDynamic('Alarm for $timeStr', lang);

    try {
      final List<String> parts = timeStr.split(':');
      final int hour = int.tryParse(parts[0].trim()) ?? 7;
      final int minute =
          parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;

      // Clamp to valid range — Android alarm intent is strict
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

  Future<ActionResult> _sendWhatsapp(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String contact = params['contact']?.toString().trim() ?? '';
    final String message = params['message']?.toString().trim() ?? '';

    if (contact.isEmpty) {
      // USER-FACING: need a contact
      await _tts.speak(TtsStrings.askContact, lang);
      return ActionResult.fail('no_contact');
    }

    await _tts.speakComposed(TtsStrings.calling, contact, lang);

    try {
      // Strip non-numeric characters (keep leading +)
      final String clean = contact.replaceAll(RegExp(r'[^\d+]'), '');

      // USER-FACING: if clean string is empty (purely alphabetical name),
      // we cannot route to a WhatsApp number — tell the user
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

  // ─── OPEN APP ────────────────────────────────────────────────────────────

  Future<ActionResult> _openApp(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String appName =
        (params['app']?.toString() ?? '').toLowerCase().trim();

    if (appName.isEmpty) {
      // USER-FACING: ask which app
      await _tts.speak(TtsStrings.askApp, lang);
      return ActionResult.fail('no_app_name');
    }

    await _tts.speakComposed(TtsStrings.opening, appName, lang);

    final String? package = AppRegistry.resolvePackage(appName);
    if (package == null) {
      await _tts.speak(TtsStrings.appNotFound, lang);
      return ActionResult.fail('unknown_app: $appName');
    }

    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: package,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return ActionResult.ok(detail: appName);
    } catch (e) {
      // Fallback to Play Store
      try {
        final Uri market = Uri.parse('market://details?id=$package');
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return ActionResult.ok(detail: appName);
      } catch (_) {
        await _tts.speak(TtsStrings.appNotFound, lang);
        return ActionResult.fail('app_launch_failed: $e');
      }
    }
  }

  // ─── NAVIGATE ────────────────────────────────────────────────────────────

  Future<ActionResult> _navigate(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final String dest = params['destination']?.toString().trim() ?? '';

    // USER-FACING: ask where to navigate if destination missing
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

  Future<ActionResult> _takeScreenshot(String lang) async {
    // MediaProjection requires user permission popup — not demo-safe.
    // DPR §11: graceful fail, NEVER crash, NO TTS before.
    return ActionResult.fail('screenshot_needs_accessibility');
  }
}
