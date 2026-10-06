import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists form field values to local storage so users can resume
/// filling multi-step forms (driver / vendor applications).
///
/// Usage:
/// 1. Call [load] in `initState` to restore saved values into controllers.
/// 2. Call [autoSave] to attach listeners that save on every keystroke.
/// 3. Call [saveCurrentStep] to persist the active step index.
/// 4. Call [clear] after successful submission.
class FormPersistence {
  final String _storageKey;

  FormPersistence(this._storageKey);

  // ── Keys ─────────────────────────────────────────────────────────────────

  String get _fieldsKey => '${_storageKey}_fields';
  String get _stepKey => '${_storageKey}_step';

  // ── Save ─────────────────────────────────────────────────────────────────

  /// Save all field values at once.
  Future<void> save(Map<String, TextEditingController> controllers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, String>{};
      for (final entry in controllers.entries) {
        if (entry.value.text.isNotEmpty) {
          data[entry.key] = entry.value.text;
        }
      }
      await prefs.setString(_fieldsKey, jsonEncode(data));
    } catch (e) {
      log('FormPersistence: save error: $e');
    }
  }

  /// Save the current step index.
  Future<void> saveCurrentStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_stepKey, step);
    } catch (e) {
      log('FormPersistence: saveStep error: $e');
    }
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  /// Restore saved values into controllers. Returns the saved step index
  /// (or 0 if none saved).
  Future<int> load(Map<String, TextEditingController> controllers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_fieldsKey);
      if (raw != null) {
        final data = Map<String, String>.from(jsonDecode(raw) as Map);
        for (final entry in data.entries) {
          if (controllers.containsKey(entry.key)) {
            controllers[entry.key]!.text = entry.value;
          }
        }
        log('FormPersistence: restored ${data.length} fields for $_storageKey');
      }
      return prefs.getInt(_stepKey) ?? 0;
    } catch (e) {
      log('FormPersistence: load error: $e');
      return 0;
    }
  }

  // ── Auto-save ────────────────────────────────────────────────────────────

  /// Attach listeners to all controllers so every change auto-saves.
  /// Returns a cleanup function to remove listeners (call in `dispose`).
  VoidCallback autoSave(Map<String, TextEditingController> controllers) {
    void listener() => save(controllers);

    for (final ctrl in controllers.values) {
      ctrl.addListener(listener);
    }

    return () {
      for (final ctrl in controllers.values) {
        ctrl.removeListener(listener);
      }
    };
  }

  // ── Bool helpers (verification state) ────────────────────────────────────

  /// Save a named boolean flag (e.g. `emailVerified`, `phoneVerified`).
  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_storageKey}_$key', value);
    } catch (e) {
      log('FormPersistence: saveBool error: $e');
    }
  }

  /// Load a named boolean flag, defaulting to [defaultValue].
  Future<bool> loadBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${_storageKey}_$key') ?? defaultValue;
    } catch (e) {
      log('FormPersistence: loadBool error: $e');
      return defaultValue;
    }
  }

  /// Save the value that was verified (email address or phone number string).
  Future<void> saveVerifiedValue(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_storageKey}_${key}Value', value);
    } catch (e) {
      log('FormPersistence: saveVerifiedValue error: $e');
    }
  }

  /// Load the value that was verified. Returns null if nothing saved.
  Future<String?> loadVerifiedValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('${_storageKey}_${key}Value');
    } catch (e) {
      log('FormPersistence: loadVerifiedValue error: $e');
      return null;
    }
  }

  // ── JSON helpers ─────────────────────────────────────────────────────────

  /// Save any JSON-serializable data under a specific key.
  Future<void> saveJson(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_storageKey}_json_$key', jsonEncode(value));
    } catch (e) {
      log('FormPersistence: saveJson error: $e');
    }
  }

  /// Load JSON-serializable data.
  Future<dynamic> loadJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_storageKey}_json_$key');
      return raw != null ? jsonDecode(raw) : null;
    } catch (e) {
      log('FormPersistence: loadJson error: $e');
      return null;
    }
  }

  // ── Clear ────────────────────────────────────────────────────────────────

  /// Remove all saved data for this form (call after successful submit).
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fieldsKey);
      await prefs.remove(_stepKey);
      
      // Clear verification flags
      for (final key in ['emailVerified', 'phoneVerified',
                         'emailVerifiedValue', 'phoneVerifiedValue']) {
        await prefs.remove('${_storageKey}_$key');
      }

      // Clear JSON data and branding
      for (final key in ['vendorType', 'selectedCuisines', 'pickedDocuments', 'logoImage', 'coverImage', 'latitude', 'longitude']) {
        await prefs.remove('${_storageKey}_json_$key');
      }
      
      log('FormPersistence: cleared $_storageKey');
    } catch (e) {
      log('FormPersistence: clear error: $e');
    }
  }

  /// Check whether there is saved draft data.
  Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_fieldsKey);
    } catch (_) {
      return false;
    }
  }
}
