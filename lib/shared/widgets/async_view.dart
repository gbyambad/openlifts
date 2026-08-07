import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// Renders an [AsyncValue] with the app's standard loading and error states,
/// delegating the loaded case to [data]. Keeps every screen's spinner/error
/// arms identical without repeating them.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({required this.value, required this.data, super.key});

  final AsyncValue<T> value;
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context)!.errorGeneric('$e')),
      ),
      data: data,
    );
  }
}
