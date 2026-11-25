import '../catalog_search.dart';

enum LiveRegion {
  jordan('Jordan'),
  levant('Levant'),
  gulf('Gulf'),
  egypt('Egypt'),
  middleEast('Middle East');

  const LiveRegion(this.label);
  final String label;

  bool includes(String market) => switch (this) {
    jordan => market == 'JO',
    levant => const {'JO', 'LB', 'SY', 'PS'}.contains(market),
    gulf => const {'SA', 'AE', 'QA', 'KW', 'OM', 'BH'}.contains(market),
    egypt => market == 'EG',
    middleEast => true,
  };
}

enum LiveGenre {
  news('News'),
  entertainment('Entertainment'),
  sports('Sports'),
  kids('Kids'),
  factual('Documentaries');

  const LiveGenre(this.label);
  final String label;
}

class RegionalChannel {
  const RegionalChannel(this.market, this.genre, this.name, this.aliases);

  final String market, name;
  final LiveGenre genre;
  final List<String> aliases;

  String get key => 'regional:$market:${catalogQuery(name)}';
}

// Editorial order. Source lineups: Roya, e& eLife, Shahid, PBC, UMS, beIN,
// Thmanyah and Alkass. Names and aliases are metadata, with no stream URLs.
// https://en.roya.tv/
// https://www.eand.ae/en/sas/home/plans/details/channel-list/200-elife.html
// https://shahid.mbc.net/ar/livestream
// https://www.pbc.ps/sat/
// https://freebox.cdn.scw.iliad.fr/Liste_Chaines_PDS_Janvier_2026_d0ee80328b.pdf
// https://ums.com.eg/tv-channels/
// https://www.bein.com/en/channel-list/
// https://ask.thmanyah.com/en/what-are-the-thamanyah-satellite-channels
// https://www.alkass.net/trdd2
final regionalChannels = List<RegionalChannel>.unmodifiable(
  _stations.trim().split('\n').map((line) {
    final fields = line.split('|');
    return RegionalChannel(
      fields[0],
      LiveGenre.values.byName(fields[1]),
      fields[2],
      fields.length == 4 ? fields[3].split(';') : const [],
    );
  }),
);

const _stations = '''
JO|entertainment|Roya TV|Roya;رؤيا;قناة رؤيا
JO|news|Al Mamlaka|AlMamlaka;AlMamlaka TV;Al Mamlaka TV;المملكة;قناة المملكة
JO|entertainment|Jordan TV|Jordan;Jordan Satellite Channel;JRTV;التلفزيون الأردني;الأردن الأولى
JO|sports|Jordan Sport|Jordan Sports;JRTV Sports;الأردن الرياضية;الاردنية الرياضية
JO|entertainment|Amman TV|Amman;عمان تي في;قناة عمان
JO|sports|Roya Sports 1|Roya Sport 1;رؤيا سبورت 1
JO|sports|Roya Sport|Roya Sports;رؤيا الرياضية;رؤيا سبورت
JO|kids|Roya Kids|رؤيا أطفال;رؤيا كيدز
JO|entertainment|Roya Comedy|رؤيا كوميدي
JO|entertainment|Roya Kitchen|رؤيا مطبخ
JO|news|Roya News|Roya Akhbar;رؤيا الإخبارية;أخبار رؤيا
JO|entertainment|Roya Palestine|رؤيا فلسطين
JO|entertainment|Roya Production|رؤيا للإنتاج
JO|entertainment|Roya Caravan|Caravan Roya;رؤيا كرفان
JO|entertainment|Roya Sett Al-Nakhat|Roya Sit Alnkhat;ست النكهات
JO|entertainment|Roya Chefman|Roya Chief Mann;شيف مان
JO|factual|Roya Adventures|رؤيا مغامرات
JO|factual|Roya Around the World|رؤيا حول العالم
JO|factual|Roya Documentaries|Roya Documentary;Roya Docmentary;رؤيا وثائقيات
JO|factual|Roya Big World|Roya The Big World
JO|entertainment|Roya 911|رؤيا 911
JO|entertainment|Roya Jalta|Roya Galta;رؤيا جلطة
JO|entertainment|Roya Watan Ala Watar|Roya Watan 3a Watar;وطن ع وتر
JO|entertainment|Roya Stories|Roya El Gessa;القصه
JO|sports|Roya RFC|RFC Roya
LB|entertainment|MTV Lebanon|MTV Liban;One MTV Lebanon;ام تي في لبنان
LB|entertainment|LBCI|LBCI Lebanon;المؤسسة اللبنانية للإرسال
LB|entertainment|LBC International|ال بي سي انترناشونال
LB|entertainment|Al Jadeed|Al Jadeed TV;El Jadeed;الجديد;قناة الجديد
LB|entertainment|Télé Liban|Tele Liban;تلفزيون لبنان
LB|entertainment|OTV Lebanon|OTV;Orange TV Lebanon;او تي في
LB|news|NBN|NBN TV;ان بي ان
LB|entertainment|Aghani Aghani|أغاني أغاني
SY|entertainment|Al Souriya|Al Souriya TV;Syrian Satellite;السورية;القناة السورية
SY|entertainment|Syria TV|Syria Television;تلفزيون سوريا
PS|entertainment|Palestine TV|Palestine Satellite;تلفزيون فلسطين
PS|news|Palestine Live|Palestine Mubasher;فلسطين مباشر
SA|entertainment|Saudi TV|Saudi 1;Saudi First;Al Saudiya;السعودية الأولى
SA|entertainment|SBC|SBC Channel;اس بي سي
SA|news|Al Ekhbariya|Alikhbariya;Saudi Al Ekhbariya;الإخبارية السعودية
SA|factual|Al Thaqafeya|AlThaqafeya;الثقافية
SA|entertainment|Thikrayat TV|Zikrayat TV;ذكريات
SA|sports|Thmanyah 1|Thamanyah 1;ثمانية 1;Thamanya 1
SA|sports|Thmanyah 2|Thamanyah 2;ثمانية 2;Thamanya 2
SA|sports|Thmanyah 3|Thamanyah 3;ثمانية 3;Thamanya 3
SA|sports|KSA Sports 1|Saudi Sports 1;الرياضية السعودية 1
SA|sports|KSA Sports 2|Saudi Sports 2;الرياضية السعودية 2
SA|sports|KSA Sports 3|Saudi Sports 3;الرياضية السعودية 3
AE|entertainment|Dubai TV|تلفزيون دبي
AE|entertainment|Sama Dubai|سما دبي
AE|entertainment|Dubai One|دبي ون
AE|entertainment|Dubai Zaman|Dubai Zaman TV;دبي زمان
AE|entertainment|Abu Dhabi TV|Abu Dhabi Al Oula;أبو ظبي الأولى
AE|entertainment|Al Emarat|Al Emarat TV;Emarat TV;الإمارات
AE|entertainment|Sharjah TV|الشارقة
AE|entertainment|Ajman TV|عجمان
AE|entertainment|Fujairah TV|الفجيرة
AE|sports|Abu Dhabi Sports 1|AD Sports 1;أبوظبي الرياضية 1;AD Sport 1;Abu Dhabi Sport 1
AE|sports|Abu Dhabi Sports 2|AD Sports 2;أبوظبي الرياضية 2;AD Sport 2;Abu Dhabi Sport 2
AE|sports|Dubai Sports 1|Dubai Sports;دبي الرياضية 1;Dubai Sport 1
AE|sports|Dubai Sports 2|دبي الرياضية 2;Dubai Sport 2
AE|sports|Dubai Sports 3|دبي الرياضية 3;Dubai Sport 3
AE|sports|Dubai Racing 1|Dubai Racing;دبي ريسنغ 1
AE|sports|Dubai Racing 2|دبي ريسنغ 2
AE|sports|Yas Sports|Yas TV;ياس الرياضية
AE|sports|Sharjah Sports|الشارقة الرياضية
AE|kids|Majid Kids|Majid Kids TV;Majid TV;ماجد
QA|entertainment|Qatar TV|تلفزيون قطر
QA|entertainment|Al Rayyan|Al Rayyan TV;الريان
QA|entertainment|Al Rayyan Al Qadeem|الريان القديم
QA|sports|Alkass 1|Al Kass One;Alkass One;Al Kass 1;الكأس 1
QA|sports|Alkass 2|Al Kass Two;Alkass Two;Al Kass 2;الكأس 2
QA|sports|Alkass 3|Al Kass Three;Alkass Three;Al Kass 3;الكأس 3
QA|sports|Alkass 4|Al Kass Four;Alkass Four;Al Kass 4;الكأس 4
QA|sports|Alkass 5|Al Kass Five;Alkass Five;Al Kass 5;الكأس 5
QA|sports|Alkass 6|Al Kass Six;Alkass Six;Al Kass 6;الكأس 6
QA|sports|Alkass 7|Al Kass Seven;Alkass Seven;Al Kass 7;الكأس 7
QA|sports|Alkass 8|Al Kass Eight;Alkass Eight;Al Kass 8;الكأس 8
QA|sports|Alkass 9|Al Kass Nine;Alkass Nine;Al Kass 9;الكأس 9
QA|sports|Alkass 10|Al Kass Ten;Alkass Ten;Al Kass 10;الكأس 10
KW|entertainment|Kuwait TV|Kuwait TV 1;تلفزيون الكويت;الكويت الأولى
KW|entertainment|Kuwait TV 2|الكويت الثانية
KW|entertainment|Al Rai TV|Al Rai;الرأي
KW|sports|Kuwait Sports|Kuwait Sport;الكويت الرياضية
KW|sports|Kuwait Sports Plus|Kuwait Sports +;الكويت الرياضية بلس
OM|entertainment|Oman TV|تلفزيون عمان
OM|sports|Oman TV Sports|Oman Sports;عمان الرياضية
BH|entertainment|Bahrain TV|تلفزيون البحرين
BH|entertainment|Bahrain International|البحرين الدولية
BH|sports|Bahrain Sports 1|البحرين الرياضية 1
BH|sports|Bahrain Sports 2|البحرين الرياضية 2
EG|entertainment|MBC Masr|MBC Masr 1;MBC Maser;MBC Misr;ام بي سي مصر;ام بي سي مصر 1
EG|entertainment|MBC Masr 2|MBC Misr 2;ام بي سي مصر 2
EG|entertainment|ON|ON E;ON TV;اون;اون تي في
EG|entertainment|ON Drama|اون دراما
EG|sports|ON Time Sports|ON Time Sports 1;ON Sport;اون تايم سبورت;ON Sport 1;ON Sports 1;اون تايم سبورت 1
EG|sports|ON Time Sports 2|اون تايم سبورت 2;ON Sport 2;ON Sports 2
EG|entertainment|DMC|DMC TV;دي ام سي
EG|entertainment|DMC Drama|دي ام سي دراما
EG|entertainment|CBC|CBC Egypt;سي بي سي
EG|entertainment|CBC Drama|سي بي سي دراما
EG|entertainment|CBC Sofra|سي بي سي سفرة
EG|entertainment|Al Hayah|Al Hayat Egypt;الحياة;الحياة المصرية
EG|entertainment|Al Hayah Drama|الحياة دراما
EG|news|Extra News|اكسترا نيوز
EG|entertainment|Al Nahar TV|El Nahar;Al Nahar;النهار
EG|entertainment|Al Nahar Drama|El Nahar Drama;النهار دراما
EG|entertainment|Sada Al Balad|صدى البلد
EG|entertainment|Sada Al Balad Drama|صدى البلد دراما
EG|entertainment|Al Mehwar|Al Mehwar TV;المحور
EG|entertainment|TEN|Ten TV;تن تي في
EG|entertainment|Nile Drama|نايل دراما
EG|entertainment|Nile Cinema|نايل سينما
EG|entertainment|Nile Comedy|نايل كوميدي
EG|sports|Nile Sports|Nile Sport;نايل سبورت
EG|sports|Zamalek TV|الزمالك;قناة الزمالك
EG|sports|Al Ahly TV|Al Ahly;الأهلي;قناة الأهلي
IQ|entertainment|MBC Iraq|ام بي سي العراق
IQ|entertainment|Al Sharqiya|الشرقية;الشرقية العراقية
IQ|news|Al Sharqiya News|الشرقية نيوز
IQ|entertainment|Alsumaria|Al Soumariya;Al Sumaria;السومرية
ME|entertainment|MBC 1|ام بي سي 1
ME|entertainment|MBC 2|ام بي سي 2
ME|kids|MBC 3|ام بي سي 3
ME|entertainment|MBC 4|ام بي سي 4
ME|entertainment|MBC 5|ام بي سي 5
ME|entertainment|MBC Drama|ام بي سي دراما
ME|entertainment|MBC Action|ام بي سي اكشن
ME|entertainment|MBC Max|ام بي سي ماكس
ME|entertainment|MBC Bollywood|ام بي سي بوليوود
ME|entertainment|Rotana Cinema|روتانا سينما
ME|entertainment|Rotana Classic|روتانا كلاسيك
ME|entertainment|Rotana Drama|روتانا دراما
ME|entertainment|Rotana Khalijia|Rotana Khalejia;روتانا خليجية
ME|kids|Rotana Kids|روتانا كيدز
ME|news|Al Jazeera|Al Jazeera Arabic;الجزيرة;الجزيرة الإخبارية
ME|news|Al Jazeera Mubasher|الجزيرة مباشر
ME|factual|Al Jazeera Documentary|الجزيرة الوثائقية
ME|news|Al Arabiya|Al Arabiya TV;العربية
ME|news|Al Hadath|Al Arabiya Al Hadath;الحدث
ME|news|Asharq News|الشرق للأخبار;أخبار الشرق
ME|news|Sky News Arabia|سكاي نيوز عربية
ME|news|Al Mashhad|Al Mashhad TV;المشهد
ME|news|Al Ghad|Al Ghad TV;الغد
ME|news|CNBC Arabiya|CNBC Arabia;سي ان بي سي عربية
ME|factual|National Geographic Abu Dhabi|Nat Geo Abu Dhabi;ناشيونال جيوغرافيك أبوظبي
ME|factual|Asharq Discovery|الشرق ديسكفري
ME|factual|Asharq Documentaries|الشرق الوثائقية
ME|kids|Spacetoon|سبيستون
ME|kids|Cartoon Network Arabic|CN Arabic;كرتون نتورك بالعربية
ME|kids|Jeem|Jeem TV;تلفزيون ج
ME|kids|Baraem|براعم
ME|sports|beIN Sports 1|بي ان سبورت 1;beIN Sport 1;بين سبورت 1
ME|sports|beIN Sports 2|بي ان سبورت 2;beIN Sport 2;بين سبورت 2
ME|sports|beIN Sports 3|بي ان سبورت 3;beIN Sport 3;بين سبورت 3
ME|sports|beIN Sports 4|بي ان سبورت 4;beIN Sport 4;بين سبورت 4
ME|sports|beIN Sports 5|بي ان سبورت 5;beIN Sport 5;بين سبورت 5
ME|sports|beIN Sports 6|بي ان سبورت 6;beIN Sport 6;بين سبورت 6
ME|sports|beIN Sports 7|بي ان سبورت 7;beIN Sport 7;بين سبورت 7
ME|sports|beIN Sports 8|بي ان سبورت 8;beIN Sport 8;بين سبورت 8
ME|sports|beIN Sports 9|بي ان سبورت 9;beIN Sport 9;بين سبورت 9
ME|sports|beIN Sports News|بي ان سبورت الإخبارية;beIN News
ME|sports|beIN Sports EN 1|beIN Sports English 1;beIN Sports 1 EN
ME|sports|beIN Sports EN 2|beIN Sports English 2;beIN Sports 2 EN
ME|sports|beIN Sports FR 1|beIN Sports French 1;beIN Sports 1 FR
ME|sports|beIN Sports FR 2|beIN Sports French 2;beIN Sports 2 FR
ME|entertainment|beIN Movies 1|بي ان موفيز 1
ME|entertainment|beIN Movies 2|بي ان موفيز 2
ME|entertainment|beIN Movies 3|بي ان موفيز 3
ME|entertainment|beIN Movies 4|بي ان موفيز 4
ME|entertainment|beIN Drama|بي ان دراما
ME|entertainment|beIN Series 1|بي ان سيريز 1
ME|entertainment|beIN Series 2|بي ان سيريز 2
ME|sports|beIN Sports|بي ان سبورت
ME|sports|beIN 4K|beIN Sports 4K;بي ان 4K
ME|sports|beIN Sports Xtra 1|beIN Sports 1 Xtra;beIN Extra 1;beIN Xtra 1
ME|sports|beIN Sports Xtra 2|beIN Sports 2 Xtra;beIN Extra 2;beIN Xtra 2
ME|sports|beIN Sports Xtra 3|beIN Sports 3 Xtra;beIN Extra 3;beIN Xtra 3
ME|sports|beIN Sports Xtra 4|beIN Sports 4 Xtra;beIN Extra 4;beIN Xtra 4
ME|sports|beIN Sports Xtra 5|beIN Sports 5 Xtra;beIN Extra 5;beIN Xtra 5
ME|sports|beIN Sports Xtra 6|beIN Sports 6 Xtra;beIN Extra 6;beIN Xtra 6
ME|sports|beIN Sports Xtra 7|beIN Sports 7 Xtra;beIN Extra 7;beIN Xtra 7
ME|sports|beIN Sports Xtra 8|beIN Sports 8 Xtra;beIN Extra 8;beIN Xtra 8
ME|sports|beIN Sports Xtra 9|beIN Sports 9 Xtra;beIN Extra 9;beIN Xtra 9
ME|sports|beIN Sports AFC|بي ان سبورت AFC
ME|sports|beIN Sports AFC 1|beIN Sports 1 AFC
ME|sports|beIN Sports AFC 2|beIN Sports 2 AFC
ME|sports|beIN Sports AFC 3|beIN Sports 3 AFC
ME|sports|beIN Sports NBA|beIN NBA
ME|sports|beIN Sports Premium 1|beIN Sports 1 Premium
ME|sports|beIN Sports Premium 2|beIN Sports 2 Premium
ME|sports|beIN Sports Premium 3|beIN Sports 3 Premium
ME|factual|beIN Gourmet|بي ان جورميه
ME|entertainment|Star Movies|ستار موفيز
ME|entertainment|Star Action|ستار اكشن
ME|entertainment|Star World|ستار وورلد
ME|factual|BBC Earth|بي بي سي إيرث
ME|factual|National Geographic Wild|Nat Geo Wild
ME|factual|Food Network|قناة فود نتورك
ME|factual|HGTV|HGTV MENA
ME|news|Al Hurra|Alhurra;الحرة
ME|news|France 24 Arabic|France 24 AR;فرانس 24 عربي
ME|news|DW Arabia|DW Arabic;دويتشه فيله عربية
ME|news|RT Arabic|روسيا اليوم
ME|kids|Boomerang MENA|Boomerang Arabia
ME|entertainment|Zee Aflam|زي أفلام
ME|entertainment|B4U Aflam|بي فور يو أفلام
ME|entertainment|Rotana Music|روتانا موسيقى
ME|entertainment|Rotana Clip|روتانا كليب
AE|sports|Al Ain TV|Al Ain Sports;العين الرياضية
''';
