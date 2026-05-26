import 'package:just_audio/just_audio.dart';

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<bool> playSurah(int surahId) async {
    try {
      await _player.stop();
      await _player.setUrl(_surahAudioUrl(surahId));
      await _player.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> playTurkishMeal(int surahId) async {
    final fileName = _turkishMealAudioFiles[surahId];
    if (fileName == null) return false;

    try {
      await _player.stop();
      await _player.setUrl(_turkishMealAudioUrl(fileName));
      await _player.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }

  String _surahAudioUrl(int surahId) {
    return 'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surahId.mp3';
  }

  String _turkishMealAudioUrl(String fileName) {
    return 'https://archive.org/download/Prof.Dr.Hamdi_DoNDuREN-Turkce_Meal/$fileName';
  }

  static const Map<int, String> _turkishMealAudioFiles = {
    1: '001fatiha_64kb.mp3',
    2: '002bakara_64kb.mp3',
    3: '003aliimran_64kb.mp3',
    4: '004nisa_64kb.mp3',
    5: '005maide_64kb.mp3',
    6: '006enam_64kb.mp3',
    7: '007araf_64kb.mp3',
    8: '008enfal_64kb.mp3',
    9: '009tevbe_64kb.mp3',
    10: '010yunus_64kb.mp3',
    11: '011hud_64kb.mp3',
    12: '012yusuf_64kb.mp3',
    13: '013rad_64kb.mp3',
    14: '014ibrahim_64kb.mp3',
    15: '015hicr_64kb.mp3',
    16: '016nahl_64kb.mp3',
    17: '017isra_64kb.mp3',
    18: '018kehf_64kb.mp3',
    19: '019meryem_64kb.mp3',
    20: '020taha_64kb.mp3',
    21: '021enbiya_64kb.mp3',
    22: '022hac_64kb.mp3',
    23: '023muminun_64kb.mp3',
    24: '024nur_64kb.mp3',
    25: '025furkan_64kb.mp3',
    26: '026suara_64kb.mp3',
    27: '027neml_64kb.mp3',
    28: '028kasas_64kb.mp3',
    29: '029ankebut_64kb.mp3',
    30: '030rum_64kb.mp3',
    31: '031lokman_64kb.mp3',
    32: '032secde_64kb.mp3',
    33: '033ahzab_64kb.mp3',
    34: '034sebe_64kb.mp3',
    35: '035fatir_64kb.mp3',
    36: '036yasin_64kb.mp3',
    37: '037saffat_64kb.mp3',
    38: '038sad_64kb.mp3',
    39: '039zumer_64kb.mp3',
    40: '040mumin_64kb.mp3',
    41: '041fussilet_64kb.mp3',
    42: '042sura_64kb.mp3',
    43: '043zuhruf_64kb.mp3',
    44: '044duhan_64kb.mp3',
    45: '045casiye_64kb.mp3',
    46: '046ahkaf_64kb.mp3',
    47: '047muhammed_64kb.mp3',
    48: '048fetih_64kb.mp3',
    49: '049hucurat_64kb.mp3',
    50: '050kaf_64kb.mp3',
    51: '051zariyat_64kb.mp3',
    52: '052tur_64kb.mp3',
    53: '053necm_64kb.mp3',
    54: '054kamer_64kb.mp3',
    55: '055rahman_64kb.mp3',
    56: '056vakia_64kb.mp3',
    57: '057hadid_64kb.mp3',
    58: '058mucadele_64kb.mp3',
    59: '059hasr_64kb.mp3',
    60: '060mumtehine_64kb.mp3',
    61: '061saf_64kb.mp3',
    62: '062cuma_64kb.mp3',
    63: '063munafikun_64kb.mp3',
    64: '064tegabun_64kb.mp3',
    65: '065talak_64kb.mp3',
    66: '066tahrim_64kb.mp3',
    67: '067mulk_64kb.mp3',
    68: '068kalem_64kb.mp3',
    69: '069hakka_64kb.mp3',
    70: '070mearic_64kb.mp3',
    71: '071nuh_64kb.mp3',
    72: '072cin_64kb.mp3',
    73: '073muzzemmil_64kb.mp3',
    74: '074muddessir_64kb.mp3',
    75: '075kiyamet_64kb.mp3',
    76: '076insan_64kb.mp3',
    77: '077murselat_64kb.mp3',
    78: '078nebe_64kb.mp3',
    79: '079naziat_64kb.mp3',
    80: '080abese_64kb.mp3',
    81: '081tekvir_64kb.mp3',
    82: '082infitar_64kb.mp3',
    83: '083mutaffifin_64kb.mp3',
    84: '084insikak_64kb.mp3',
    85: '085buruc_64kb.mp3',
    86: '086tarik_64kb.mp3',
    87: '087ala_64kb.mp3',
    88: '088gasiye_64kb.mp3',
    89: '089fecr_64kb.mp3',
    90: '090beled_64kb.mp3',
    91: '091sems_64kb.mp3',
    92: '092leyl_64kb.mp3',
    93: '093duha_64kb.mp3',
    94: '094insirah_64kb.mp3',
    95: '095tin_64kb.mp3',
    96: '096alak_64kb.mp3',
    97: '097kadr_64kb.mp3',
    98: '098beyyine_64kb.mp3',
    99: '099zilzal_64kb.mp3',
    100: '100adiyat_64kb.mp3',
    101: '101karia_64kb.mp3',
    102: '102tekasur_64kb.mp3',
    103: '103asr_64kb.mp3',
    104: '104humeze_64kb.mp3',
    105: '105fil_64kb.mp3',
    106: '106kureys_64kb.mp3',
    107: '107maun_64kb.mp3',
    108: '108kevser_64kb.mp3',
    109: '109kafirun_64kb.mp3',
    110: '110nasr_64kb.mp3',
    111: '111tebbet_64kb.mp3',
    112: '112ihlas_64kb.mp3',
    113: '113felak_64kb.mp3',
    114: '114nas_64kb.mp3',
  };
}
