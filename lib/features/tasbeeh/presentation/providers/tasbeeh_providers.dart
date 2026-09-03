import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tasbeeh_item.dart';

final tasbeehListProvider = FutureProvider<List<TasbeehItem>>((ref) async {
  final raw = await rootBundle.loadString('assets/tasbeeh.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => TasbeehItem.fromJson(e as Map<String, dynamic>))
      .toList();
});
