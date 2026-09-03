import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/allah_name.dart';

final namesOfAllahProvider = FutureProvider<List<AllahName>>((ref) async {
  final raw = await rootBundle.loadString('assets/names_of_allah.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => AllahName.fromJson(e as Map<String, dynamic>))
      .toList();
});
