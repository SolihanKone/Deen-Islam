import 'package:equatable/equatable.dart';
import 'package:quran/quran.dart' as q;

/// Per-ayah recitation via [cdn.islamic.app](https://cdn.islamic.app) (global ayah 1–6236).
class Reciter extends Equatable {
  const Reciter({
    required this.id,
    required this.name,
    required this.cdnSlug,
  });

  final String id;
  final String name;
  final String cdnSlug;

  static int globalAyahNumber(int surah, int ayahInSurah) {
    var offset = 0;
    for (var s = 1; s < surah; s++) {
      offset += q.getVerseCount(s);
    }
    return offset + ayahInSurah;
  }

  String ayahUrl(int surah, int ayahInSurah) {
    final global = globalAyahNumber(surah, ayahInSurah);
    return 'https://cdn.islamic.app/quran/audio/$cdnSlug/$global.mp3';
  }

  /// Standalone bismillah — uses Al-Fatiha 1:1 (bismillah at start of file).
  String bismillahUrl() => ayahUrl(1, 1);

  @override
  List<Object?> get props => [id, name, cdnSlug];

  static const List<Reciter> presets = [
    Reciter(
      id: 'mishary',
      name: 'Mishary Rashid Alafasy',
      cdnSlug: 'ar.alafasy',
    ),
    Reciter(
      id: 'sudais',
      name: 'Abdur Rahman As-Sudais',
      cdnSlug: 'ar.abdurrahmaansudais',
    ),
    Reciter(
      id: 'shuraym',
      name: 'Saud Al-Shuraim',
      cdnSlug: 'ar.saoodshuraym',
    ),
    Reciter(
      id: 'maher',
      name: 'Maher Al Muaiqly',
      cdnSlug: 'ar.mahermuaiqly',
    ),
    Reciter(
      id: 'basit',
      name: 'Abdul Basit Murattal',
      cdnSlug: 'ar.abdulbasitmurattal',
    ),
    Reciter(
      id: 'abdulsamad',
      name: 'Abdul Samad',
      cdnSlug: 'ar.abdulsamad',
    ),
    Reciter(
      id: 'husary',
      name: 'Mahmoud Khalil Al-Husary',
      cdnSlug: 'ar.husary',
    ),
    Reciter(
      id: 'husary_mujawwad',
      name: 'Al-Husary (Mujawwad)',
      cdnSlug: 'ar.husarymujawwad',
    ),
    Reciter(
      id: 'minshawi',
      name: 'Muhammad Siddiq Al-Minshawi',
      cdnSlug: 'ar.minshawi',
    ),
    Reciter(
      id: 'minshawi_mujawwad',
      name: 'Al-Minshawi (Mujawwad)',
      cdnSlug: 'ar.minshawimujawwad',
    ),
    Reciter(
      id: 'ayyub',
      name: 'Muhammad Ayyub',
      cdnSlug: 'ar.muhammadayyoub',
    ),
    Reciter(
      id: 'jibreel',
      name: 'Muhammad Jibreel',
      cdnSlug: 'ar.muhammadjibreel',
    ),
    Reciter(
      id: 'shatri',
      name: 'Abu Bakr Al-Shatri',
      cdnSlug: 'ar.shaatree',
    ),
    Reciter(
      id: 'hudhaify',
      name: 'Ali Al-Huthaify',
      cdnSlug: 'ar.hudhaify',
    ),
    Reciter(
      id: 'ajamy',
      name: 'Ahmed Al-Ajamy',
      cdnSlug: 'ar.ahmedajamy',
    ),
    Reciter(
      id: 'basfar',
      name: 'Abdullah Basfar',
      cdnSlug: 'ar.abdullahbasfar',
    ),
    Reciter(
      id: 'rifai',
      name: 'Hani Ar-Rifai',
      cdnSlug: 'ar.hanirifai',
    ),
    Reciter(
      id: 'akhdar',
      name: 'Ibrahim Al-Akhdar',
      cdnSlug: 'ar.ibrahimakhbar',
    ),
    Reciter(
      id: 'sowaid',
      name: 'Ayman Sowaid',
      cdnSlug: 'ar.aymanswoaid',
    ),
    Reciter(
      id: 'parhizgar',
      name: 'Shahriar Parhizgar',
      cdnSlug: 'ar.parhizgar',
    ),
  ];

  static Reciter byId(String id) {
    return presets.firstWhere(
      (r) => r.id == id,
      orElse: () => presets.first,
    );
  }
}
