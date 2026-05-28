import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class SirahScreen extends StatelessWidget {
  const SirahScreen({super.key});

  static const _stories = [
    {
      'title': 'Hz. Muhammed (s.a.v.)',
      'subtitle': 'Son peygamber, el-Emin, rahmet elçisi',
      'facts': [
        '571 yılı civarında Mekke’de, Kureyş’in Hâşimoğulları kolunda dünyaya geldi.',
        'Babası Abdullah, Peygamberimiz doğmadan önce ticaret yolculuğu dönüşünde Medine’de vefat etti.',
        'Annesi Âmine, Peygamberimiz 6 yaşındayken Ebvâ’da vefat etti.',
        'Dedesi Abdülmuttalib onu himaye etti; dedesi vefat edince amcası Ebû Tâlib’in yanında büyüdü.',
        'Çocukluk ve gençlik döneminde çobanlık yaptı; daha sonra ticaretle meşgul oldu.',
        'Doğruluğu ve güvenilirliği sebebiyle Mekkeliler arasında “el-Emin” diye tanındı.',
        '25 yaşlarında Hz. Hatice validemizle evlendi; onun ticaret işlerinde güvenilir temsilci olarak çalıştı.',
        '40 yaşında Hira’da ilk vahiy geldi; tevhid, ahlak ve adalet çağrısı başladı.',
        'Mekke’de 13 yıl tebliğ etti; 622 yılında Medine’ye hicret etti.',
        'Medine’de kardeşlik, mescid, toplumsal sözleşme ve ümmet bilinci etrafında yeni bir hayat kurdu.',
        '632 yılında Medine’de vefat etti; kabri Mescid-i Nebevî’dedir.',
      ],
    },
    {
      'title': 'Hz. İbrahim (a.s.)',
      'subtitle': 'Tevhid mücadelesi, teslimiyet ve dua örneği',
      'facts': [
        'Putlara tapan bir çevrede Allah’ın birliğini savundu.',
        'Kur’an’da “hanîf” olarak anılır; hakka yönelen, şirkten uzak duran bir kuldur.',
        'Kavmini akıl yürütmeye ve putların acizliğini fark etmeye çağırdı.',
        'Ateşe atılması, Allah’a güven ve teslimiyetin sembol olaylarından biri olarak anlatılır.',
        'Hicret etti; yurdundan ayrılmayı Allah rızası için göze aldı.',
        'Hz. Hâcer ve Hz. İsmail’i Mekke vadisine bıraktı; bu teslimiyet zemzem ve hac hatıralarıyla anılır.',
        'Hz. İsmail ile Kâbe’nin temellerini yükseltti.',
        'Kurban ibadeti, onun ve Hz. İsmail’in teslimiyet hatırasıyla yaşatılır.',
        'Dualarında neslinin namazı dosdoğru kılan kullar olmasını istedi.',
      ],
    },
    {
      'title': 'Hz. Musa (a.s.)',
      'subtitle': 'Zulme karşı cesaret, sabır ve liderlik',
      'facts': [
        'Firavun’un baskıcı yönetimi döneminde Mısır’da dünyaya geldi.',
        'Allah’ın korumasıyla bebekken saraya ulaştı ve orada büyüdü.',
        'Medyen tarafına gitti; orada yıllarca sade bir hayat yaşadı.',
        'Tûr’da vahye muhatap oldu ve Firavun’a tebliğle görevlendirildi.',
        'Asası ve elinin parlaması gibi mucizelerle desteklendi.',
        'Kardeşi Hz. Hârûn ona yardımcı olarak görevlendirildi.',
        'İsrailoğullarını kölelikten kurtarmak için mücadele etti.',
        'Denizin yarılması olayı, onun hayatındaki en büyük kurtuluş sahnelerinden biridir.',
        'Kendisine Tevrat verildi; kavmine sabırla rehberlik etti.',
      ],
    },
    {
      'title': 'Hz. İsa (a.s.)',
      'subtitle': 'Merhamet, hikmet ve kulluk bilinci',
      'facts': [
        'Annesi Hz. Meryem’dir; babasız yaratılışı Allah’ın kudretinin bir işareti olarak anlatılır.',
        'Kur’an’da daha beşikteyken Allah’ın kulu ve peygamberi olduğunu söylediği bildirilir.',
        'İsrailoğullarına gönderildi.',
        'Kendisine İncil verildi.',
        'Allah’ın izniyle hastaları iyileştirme ve ölüleri diriltme gibi mucizeler gösterdi.',
        'Havarileri onun yakın yardımcıları olarak bilinir.',
        'Mesajında Allah’a kulluk, merhamet, arınma ve ahiret bilinci öne çıkar.',
        'Kur’an onu Allah’ın kulu ve peygamberi olarak tanıtır.',
      ],
    },
    {
      'title': 'Hz. Nuh (a.s.)',
      'subtitle': 'Uzun davet, sabır ve sebat',
      'facts': [
        'Kavmini uzun yıllar boyunca Allah’a kulluğa davet etti.',
        'Alay, inkâr ve baskıya rağmen tebliğini sürdürdü.',
        'Kavminin ileri gelenleri onu küçümsemeye çalıştı; o ise sabırla devam etti.',
        'Allah’ın emriyle gemi yaptı.',
        'İman edenlerle birlikte gemiye bindi.',
        'Tufan kıssası, inkârın sonucu ve imanın kurtuluşu olarak anlatılır.',
        'Onun hayatı, vazgeçmeden doğruyu anlatmanın güçlü bir örneğidir.',
      ],
    },
    {
      'title': 'Hz. Yusuf (a.s.)',
      'subtitle': 'İffet, sabır, rüya ve affedicilik',
      'facts': [
        'Hz. Yakub’un oğludur; çocukken gördüğü rüya hayatının önemli işaretlerinden biri oldu.',
        'Kardeşlerinin kıskançlığı sebebiyle kuyuya bırakıldı.',
        'Mısır’a götürüldü ve zorlu bir hayat başladı.',
        'İffet imtihanında Allah’a sığındı.',
        'Haksız yere zindana düştü; orada da güzel ahlakını korudu.',
        'Rüyaları yorumlama bilgisiyle tanındı.',
        'Mısır’da mali işlerden sorumlu yüksek bir göreve geldi.',
        'Kardeşlerini affetmesi, Kur’an’daki en güçlü merhamet örneklerinden biridir.',
      ],
    },
    {
      'title': 'Hz. Eyyub (a.s.)',
      'subtitle': 'Hastalık, kayıp ve sabır imtihanı',
      'facts': [
        'Mal, sağlık ve yakın çevre imtihanlarıyla anılır.',
        'Ağır sıkıntılara rağmen Allah’a bağlılığını kaybetmedi.',
        'Duasında Rabbine halini arz etti; isyan değil teslimiyet gösterdi.',
        'Sabır denince ilk hatırlanan peygamberlerden biridir.',
        'Onun kıssası, dert zamanında edep ve ümit dengesini öğretir.',
      ],
    },
    {
      'title': 'Hz. Yunus (a.s.)',
      'subtitle': 'Tevbe, dua ve yeniden dönüş',
      'facts': [
        'Kavmini Allah’a davet etti.',
        'Kavminden ayrıldıktan sonra denizde büyük bir imtihan yaşadı.',
        'Balığın karnındaki duası tevbe ve teslimiyetin sembolü oldu.',
        '“Senden başka ilah yoktur; seni tenzih ederim” manasındaki duasıyla anılır.',
        'Allah’ın rahmetiyle kurtuldu ve görevine döndü.',
        'Kıssası, hatadan dönüş kapısının açık olduğunu hatırlatır.',
      ],
    },
    {
      'title': 'Hz. Süleyman (a.s.)',
      'subtitle': 'Hikmet, adalet ve nimet bilinci',
      'facts': [
        'Hz. Davud’un oğludur.',
        'Kendisine büyük bir mülk, hikmet ve hüküm verme kabiliyeti verildi.',
        'Kur’an’da kuşlar, rüzgâr ve cinlerle ilgili kıssaları anlatılır.',
        'Belkıs kıssasında hikmetli davet ve güçlü yönetim örneği görülür.',
        'Nimetleri kendinden bilmedi; Allah’ın lütfu olarak gördü.',
        'Onun hayatı güç sahibi bir kulun şükürle nasıl dengede kalacağını öğretir.',
      ],
    },
    {
      'title': 'Hz. Davud (a.s.)',
      'subtitle': 'Hüküm, zikir, adalet ve güzel ses',
      'facts': [
        'Hz. Süleyman’ın babasıdır; kendisine Zebur verilmiştir.',
        'Kur’an’da dağların ve kuşların onunla birlikte Allah’ı tesbih ettiği anlatılır.',
        'Güçlü bir hükümdar olmasına rağmen kulluk bilincini kaybetmedi.',
        'Adaletle hükmetme konusunda uyarılar ve ibretler onun kıssasında öne çıkar.',
        'El emeğiyle geçinme, zanaat ve çalışkanlık yönüyle de anılır.',
        'Hayatı, güç ve makamın şükürle taşınması gerektiğini hatırlatır.',
      ],
    },
    {
      'title': 'Hz. Zekeriyya (a.s.)',
      'subtitle': 'Ümit, dua ve geç yaşta gelen müjde',
      'facts': [
        'Mescid hizmeti ve Hz. Meryem’in himayesiyle anılır.',
        'Yaşlılık döneminde bile Allah’ın rahmetinden ümit kesmedi.',
        'Rabbinden hayırlı bir nesil istedi; duasına Hz. Yahya ile karşılık verildi.',
        'Duasında sesini alçaltarak samimi bir yakarışta bulunduğu bildirilir.',
        'Onun kıssası, gecikmiş görünen duaların da Allah katında karşılıksız kalmadığını öğretir.',
      ],
    },
    {
      'title': 'Hz. Yahya (a.s.)',
      'subtitle': 'Takva, iffet ve erken yaşta hikmet',
      'facts': [
        'Hz. Zekeriyya’nın oğludur.',
        'Kur’an’da kendisine çocuk yaşta hikmet verildiği bildirilir.',
        'Temiz ahlakı, merhameti ve anne babasına iyiliğiyle övülür.',
        'Dünya tutkularından uzak, takva merkezli bir hayat sürdü.',
        'Hak sözü söylemekten çekinmeyen örnek bir peygamber olarak anılır.',
      ],
    },
    {
      'title': 'Hz. Lut (a.s.)',
      'subtitle': 'Ahlak, aile imtihanı ve toplumsal uyarı',
      'facts': [
        'Hz. İbrahim’e iman eden ve onunla hicret eden peygamberlerdendir.',
        'Kavmini iffete, temizliğe ve Allah’ın sınırlarına davet etti.',
        'Toplumsal bozulmaya karşı yalnız kalsa da hakkı söylemeye devam etti.',
        'Aile içinden bile imtihan yaşaması, hidayetin kişisel bir tercih olduğunu gösterir.',
        'Kıssası, ahlaki çöküşün toplumları nasıl yıprattığını hatırlatır.',
      ],
    },
    {
      'title': 'Hz. Şuayb (a.s.)',
      'subtitle': 'Ticaret ahlakı, ölçü ve adalet',
      'facts': [
        'Medyen halkına gönderildi.',
        'Kavmini Allah’a kulluğa ve ticarette dürüstlüğe çağırdı.',
        'Eksik ölçüp tartma, kul hakkı ve ekonomik haksızlıklar onun tebliğinde öne çıkar.',
        'Sözlü baskıya rağmen davetini hikmetle sürdürdü.',
        'Hayatı, ibadetin ticaret ve sosyal hayat ahlakından ayrı düşünülemeyeceğini öğretir.',
      ],
    },
    {
      'title': 'Hz. Harun (a.s.)',
      'subtitle': 'Yardımcılık, kardeşlik ve tebliğ desteği',
      'facts': [
        'Hz. Musa’nın kardeşidir.',
        'Musa (a.s.) duasında onu kendisine yardımcı istemiştir.',
        'Dili açık, iletişimi güçlü bir peygamber olarak Firavun’a tebliğde Musa’ya destek oldu.',
        'Kavminin zorlu dönemlerinde sabırla onları doğruya çağırdı.',
        'Kıssası, hayırlı işlerde ekip olmanın ve kardeş desteğinin önemini gösterir.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siyer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLG),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peygamberlerin Hayatından',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  'Kısa bilgiler, ibretlik kesitler ve temel hayat notları',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          for (final story in _stories) _buildStoryCard(story),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, Object> story) {
    final facts = story['facts'] as List<String>;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMD,
          vertical: AppDimensions.spacingSM,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingMD,
          0,
          AppDimensions.spacingMD,
          AppDimensions.spacingMD,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingSM),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(Icons.auto_stories, color: AppColors.primary),
        ),
        title: Text(
          story['title'] as String,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          story['subtitle'] as String,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          for (final fact in facts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.brightness_1, size: 7, color: AppColors.accent),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Expanded(
                    child: Text(
                      fact,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
