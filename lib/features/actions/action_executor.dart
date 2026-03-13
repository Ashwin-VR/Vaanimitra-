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
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

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
      case VIntent.typeText:           return _typeText(cmd.params['text'] ?? '', cmd.language);
      case VIntent.navigate:           return _navigate(cmd.params, cmd.language);
      case VIntent.toggleWifi:         return _toggleWifi(cmd.params, cmd.language);
      case VIntent.toggleBluetooth:    return _toggleBluetooth(cmd.params, cmd.language);
      case VIntent.goHome:             return _goHome(cmd.language);
      case VIntent.goBack:             return _goBack(cmd.language);
      case VIntent.lockScreen:         return _lockScreen(cmd.language);
      case VIntent.takeScreenshot:     return _takeScreenshot(cmd.language);
      case VIntent.closeApp:           return _closeApp(cmd.params, cmd.language);
      case VIntent.pickIndex:          return _pickIndex(cmd.params, cmd.language);
      case VIntent.readScreen:         return _readScreen(cmd.language);
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

  Future<ActionResult> _callContact(Map<String, dynamic> params, String lang) async {
    final String contactName = params['contact']?.toString().trim() ?? '';
    if (contactName.isEmpty) {
      await _tts.speak(TtsStrings.askContact, lang);
      return ActionResult.fail('no_contact_name');
    }

    // 1. Direct Dial if numeric
    final isNumeric = RegExp(r'^[+0-9\s\-()]+$').hasMatch(contactName);
    if (isNumeric) {
      final cleanNumber = contactName.replaceAll(RegExp(r'[\s\-()]'), '');
      await _tts.speakComposed(TtsStrings.calling, contactName, lang);
      await _dial(cleanNumber, params['app']?.toString());
      return ActionResult.ok(detail: contactName);
    }

    // 2. Resolve name to phone number
    final List<Contact> matches = await _resolveContacts(contactName);

    if (matches.isEmpty) {
      await _tts.speak(TtsStrings.contactNotFound, lang);
      return ActionResult.fail('contact_not_found: $contactName');
    }

    if (matches.length > 1) {
      // Multiple matches — return a list of names for user selection
      final names = matches.take(3).map((c) => c.displayName).toList();
      return ActionResult.clarify(names);
    }

    final bestMatch = matches.first;
    final phoneNumber = bestMatch.phones.first.number.replaceAll(RegExp(r'[\s\-()]'), '');
    await _tts.speakComposed(TtsStrings.calling, bestMatch.displayName, lang);
    await _dial(phoneNumber, params['app']?.toString());
    return ActionResult.ok(detail: bestMatch.displayName);
  }

  Future<void> _dial(String number, String? appOverride) async {
    if (appOverride != null) {
      final pkg = AppRegistry.resolvePackage(appOverride);
      if (pkg != null) {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'tel:$number',
          package: pkg,
        );
        await intent.launch();
        return;
      }
    }
    final Uri uri = Uri.parse('tel:$number');
    await launchUrl(uri);
    // User wants to return to app after call. 
    // We can't know when the call ends, so we wait 10s as a heuristic or let them toggle back.
    Future.delayed(const Duration(seconds: 10), () => _relaunch());
  }

  /// Looks up contacts by name with fuzzy matching.
  Future<List<Contact>> _resolveContacts(String name) async {
    try {
      final permission = await Permission.contacts.status;
      if (!permission.isGranted) await Permission.contacts.request();
      if (!await Permission.contacts.isGranted) return [];

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (contacts.isEmpty) return [];

      final query = name.toLowerCase().trim();
      final results = <MapEntry<Contact, int>>[];

      for (final c in contacts) {
        final displayName = c.displayName.toLowerCase();
        
        // Exact or substring match (high priority)
        if (displayName == query) {
          results.add(MapEntry(c, 0));
        } else if (displayName.contains(query)) {
          results.add(MapEntry(c, 1));
        } else {
          // Simple fuzzy match: check if first few chars match or use a distance if needed
          // For now, let's keep it simple: prefix match
          if (displayName.startsWith(query.substring(0, (query.length * 0.6).toInt().clamp(1, query.length)))) {
             results.add(MapEntry(c, 2));
          }
        }
      }

      results.sort((a, b) => a.value.compareTo(b.value));
      return results.map((e) => e.key).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── ALARM ────────────────────────────────────────────────────────────────

  Future<ActionResult> _setAlarm(
    Map<String, dynamic> params,
    String lang,
  ) async {
    final int hour = params['hour'] as int? ?? 0;
    final int minute = params['minute'] as int? ?? 0;
    final String timeStr = params['time'] ?? '$hour:$minute';
    final String action = params['action'] ?? 'set';

    if (action == 'remove') {
      await _tts.speakDynamic('Opening your alarms for management', lang);
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SHOW_ALARMS',
      );
      await intent.launch();
      return ActionResult.ok(detail: 'remove_request');
    }

    try {
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
      final String ampm = safeHour >= 12 ? 'PM' : 'AM';
      final int h12 = safeHour > 12 ? safeHour - 12 : (safeHour == 0 ? 12 : safeHour);
      await _tts.speakDynamic('Alarm set for $h12:${safeMinute.toString().padLeft(2, '0')} $ampm', lang);
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
      // 1. Direct if numeric
      final isNumeric = RegExp(r'^[+0-9\s\-()]+$').hasMatch(contact);
      String clean = contact.replaceAll(RegExp(r'[^\d+]'), '');

      if (!isNumeric) {
        // Resolve name to phone number
        final List<Contact> matches = await _resolveContacts(contact);

        if (matches.isEmpty) {
          await _tts.speak(TtsStrings.contactNotFound, lang);
          return ActionResult.fail('contact_not_found: $contact');
        }

        if (matches.length > 1) {
          final names = matches.take(3).map((c) => c.displayName).toList();
          return ActionResult.clarify(names);
        }

        final bestMatch = matches.first;
        if (bestMatch.phones.isNotEmpty) {
          clean = bestMatch.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
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

    try {
      // Use installed_apps for faster intent launching and ignoring hidden
      final List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: false);
      AppInfo? targetApp;

      for(final pkg in candidates) {
        try {
           targetApp = apps.firstWhere((app) => app.packageName == pkg);
           break;
        } catch(_) {}
      }

      if (targetApp != null) {
          // Found app, launch it directly via installed_apps plugin
          final bool launchSuccess = await InstalledApps.startApp(targetApp.packageName) ?? false;
          if (launchSuccess) {
            return ActionResult.ok(detail: appName);
          }
      }
    } catch (e) {
      // Fallback below
    }

    for (final pkg in candidates) {
      try {
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

        if (params['action'] == 'recents') {
          Future.delayed(const Duration(milliseconds: 1000), () async {
            const platform = MethodChannel('com.vanimitra.app/screenshot');
            await platform.invokeMethod('clickText', {'text': 'Recents'});
          });
        }

        return ActionResult.ok(detail: appName);
      } catch (_) {
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
      if (params['state'] == 'off') {
         await _tts.speak(TtsStrings.flashOff, lang);
      } else {
         await _tts.speak(TtsStrings.wifiSettings, lang);
      }
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      await intent.launch();
      // Trigger native automation
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('toggleWifi');
      
      // Extended delay to allow settings to load and automation to click
      Future.delayed(const Duration(seconds: 5), () => _relaunch());
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
      // Trigger native automation
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('toggleBluetooth');

      Future.delayed(const Duration(seconds: 5), () => _relaunch());
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
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('goHome');
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
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('goBack');
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
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('lockScreen');
      return ActionResult.ok(detail: 'lock');
    } catch (e) {
      return ActionResult.fail('lock_failed: $e');
    }
  }

  // ─── TAKE SCREENSHOT ─────────────────────────────────────────────────────
  // FIX #3: Was silently failing with no TTS. Now speaks a message.

  Future<ActionResult> _typeText(String text, String lang) async {
    if (text.isEmpty) return ActionResult.fail('empty_text');
    await _tts.speakEarcon(); // Play success beep
    try {
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('typeText', {'text': text});
      return ActionResult.ok(detail: 'typed');
    } catch (e) {
      await _tts.speakDynamic("Accessibility service is required for typing.", lang);
      return ActionResult.fail('typing_failed: $e');
    }
  }

  Future<ActionResult> _takeScreenshot(String lang) async {
    // MediaProjection needs user permission — not safe for demo.
    // Switching to AccessibilityService, configured natively.
    await _tts.speakEarcon();
    try {
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      final success = await platform.invokeMethod<bool>('takeScreenshot');
      if (success == true) {
        return ActionResult.ok(detail: 'screenshot');
      }
      return ActionResult.fail('screenshot_failed');
    } catch (e) {
      // Speak a helpful message then fail gracefully if accessibility not turned on.
      await _tts.speak(TtsStrings.screenshotUnavailable, lang);
      return ActionResult.fail('screenshot_needs_accessibility: $e');
    }
  }

  Future<ActionResult> _closeApp(Map<String, dynamic> params, String lang) async {
    final String appName = params['app']?.toString().trim() ?? '';
    if (appName.isEmpty) return ActionResult.fail('no_app_name');
    await _tts.speakComposed(TtsStrings.closing, appName, lang);
    try {
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('closeApp', {'app': appName});
      // Relaunch Vaanimitra after closing the other app
      Future.delayed(const Duration(milliseconds: 1500), () => _relaunch());
      return ActionResult.ok(detail: appName);
    } catch (e) {
      return ActionResult.fail('close_app_failed: $e');
    }
  }

  Future<ActionResult> _pickIndex(Map<String, dynamic> params, String lang) async {
    final int index = params['index'] as int? ?? 0;
    final String label = params['label']?.toString() ?? 'item';
    await _tts.speakDynamic('Selecting the $label', lang);
    try {
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('clickIndex', {'index': index});
      
      // Hands-free return
      Future.delayed(const Duration(seconds: 4), () => _relaunch());
      
      return ActionResult.ok(detail: 'index_$index');
    } catch (e) {
      return ActionResult.fail('pick_index_failed: $e');
    }
  }

  Future<ActionResult> _readScreen(String lang) async {
    await _tts.speakDynamic('Reading the screen...', lang);
    try {
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      final String text = await platform.invokeMethod('readScreen');
      if (text.isNotEmpty) {
        await _tts.speakDynamic(text, lang);
        return ActionResult.ok(detail: 'read_screen');
      } else {
        await _tts.speakDynamic('I could not find any text on the screen.', lang);
        return ActionResult.fail('no_text_found');
      }
    } catch (e) {
      return ActionResult.fail('read_screen_failed: $e');
    }
  }

  Future<void> _relaunch() async {
    try {
      const platform = MethodChannel('com.vanimitra.app/screenshot');
      await platform.invokeMethod('relaunchApp');
    } catch (_) {}
  }
}
