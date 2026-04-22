import 'package:flutter/material.dart';
import 'package:flutter_app/l10n/app_localizations.dart';

extension ContextExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
