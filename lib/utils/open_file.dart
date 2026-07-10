import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a local file (e.g. a proof PDF) with the OS's default handler.
Future<void> openLocalFile(BuildContext context, String path) async {
  if (!File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This file is missing from disk.')),
      );
    }
    return;
  }

  final launched = await launchUrl(Uri.file(path));
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the file.')),
    );
  }
}
