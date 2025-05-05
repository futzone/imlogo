import 'package:dication/src/core/models/text_model.dart';

class StaticDatabase {
  static List<TextModel> get texts => TextModel.asList(_dataList);
}

const _dataList = [
  {
    "id": 1,
    "className": "1-sinf",
    "ageName": "7-8",
    "title": "ULKAN SHAHAR",
    "text": "Toshkent ko‘p millatli ulkan shahar bo‘lib, hozir unda 3 millionga yaqin aholi yashaydi. Uning chiroyi kundan-kunga ortib boryapti.",
    "length": 18,
    "time": 20,
    "url":"https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Ulkan%20shahar.m4a"
  },
  {
    "id": 2,
    "className": "1-sinf",
    "ageName": "7-8",
    "title": "AXLOQ",
    "text":
        "O‘rinli, axloqli va adolatli yashamay turib, yaxshi umr kechirib bo‘lmaydi va aksincha, yaxshi umr kechirmay turib, o‘rinli, axloqli va adolatli yashab bo‘lmaydi (Ekipur).",
    "length": 22,
    "time": 20,
    "url": "https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Axloq.m4a"
  },
  {
    "id": 3,
    "className": "2-sinf",
    "ageName": "8-9",
    "title": "YER",
    "text":
        "Yer tabiatning in’omi. U xalqqa noz-u ne’mat beradi. Qish kunlarida yer miriqib dam oladi. U qor va yomg‘ir namlarini yig‘ib kelgusi yil hosili uchun asrab turadi. Bahorda yer insonga o‘z bahrini ochadi, saxiy mehrini sochadi.",
    "length": 35,
    "time": 30,
    "url":"https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Yer.m4a"
  },
  {
    "id": 4,
    "className": "2-sinf",
    "ageName": "8-9",
    "title": "O‘ZBEK KURASHI",
    "text":
        "Bugungi kunga kelib dunyoning turli burchaklarida jahon miqyosida o‘tkaziladigan o‘zbek kurashi musobaqalarida polvon, kurash, yonbosh, chala, tanbeh, dakki, halol, g‘irrom kabi bir qancha o‘zbekcha atamalar barchaning havasini keltirib, jaranglaydigan bo‘ldi. Biz dunyo miqyosiga chiqqan o‘zbek kurashi bilan haqli ravishda faxrlanamiz.",
    "length": 40,
    "time": 30
  },
  {
    "id": 5,
    "className": "3-sinf",
    "ageName": "9-10",
    "title": "KUCH – BILIMDA",
    "text":
        "Xalqimizda «Kuch – bilimda!» degan gap bor. Albatta, to‘g‘ri. Bilimsiz odam hech narsaga erisholmaydi, aksincha, hayotda yutqazadi. Ayniqsa, hech narsa o‘qimaydigan, johil kimsalar faqat bugunini o‘ylab, hayotdan orqada qoladi. Shu bois, bilim olishga astoydil kirishmoq darkor! Orzularga erishishning yagona yo‘li shu.",
    "length": 40,
    "time": 40
  },
  {
    "id": 6,
    "className": "3-sinf",
    "ageName": "9-10",
    "title": "ONA TILIM",
    "url":"https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Ona%20tilim.m4a",
    "text":
        "O‘zbek tili XI asrdan boshlab mustaqil til sifatida shakllana boshladi. O‘zbek tilining rivojlanishida XI asrda yashab o‘tgan eng birinchi turkiy tilshunos olim Mahmud Qoshg‘ariy, adib Yusuf Xos Hojib, buyuk alloma Alisher Navoiylarning hissalari kattadir. O‘zbek tilining rivojiga, ayniqsa, O‘zbekiston mustaqillikka erishgandan so‘ng ahamiyat berildi.",
    "length": 44,
    "time": 40
  },
  {
    "id": 7,
    "className": "4-sinf",
    "ageName": "10-11",
    "title": "VATAN",
    "text":
        "Vatan! Ne-ne aziz insonlar voyaga yetgan, uning porloq istiqboli, fazl u kamoli uchun jon fido etgan zamin. El borki, Vatan bor. Vatan borki, el bor. Elsiz vatan biyobon, Vatansiz el - darbadar. Shuning uchun ham, el qadri bilan yashagan kishilarni vatanparvar deya ardoqlaganlar. Jonajon yurtimizni mustaqil Vatan deb ataymiz. Bu ko‘hna diyor torlarini shundayin chertib yubordiki, endi uning sehrli va fusunkor sarhadlari dunyo mamlakatlari ko‘z o‘ngida O‘zbekiston nomi ila namoyon bo‘lmoqda. Bugun biz istiqbolimizni, erkinligimizni, mustaqilligimizni sharaflaymiz, qo‘shiqlarda kuylaymiz.",
    "length": 79,
    "time": 40,
    "url":"https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Vatan.m4a"
  },
  {
    "id": 8,
    "className": "4-sinf",
    "ageName": "10-11",
    "title": "TABIATNI ASRAYLIK",
    "text":
        "Agar havoda kislorod bo‘lmasa, odam bir daqiqa ham yashay olmaydi. Ammo tabiat bunga yo‘l qo‘ymaydi. U o‘pkamiz uchun hamisha kerakli miqdorda toza havo yetkazib beradi. Agar suv bo‘lmasa, hayot bo‘lmas edi. Lekin g‘amxo‘r tabiatning shu kungacha insonni suvsiz qoldirgan hollari bo‘lgan emas. Quyosh bo‘lmasa, hayot to‘xtab qolgan bo‘lar edi. Ammo tabiatning buyuk qonuniga bo‘ysungan Quyosh har doim erta tongda chiqib, tirik mavjudotga xizmat qiladi. Inson - tabiatning oliy mahsuli. Tabiat marhamatisiz yashay olmas ekanmiz, demak u bizning onamiz.",
    "length": 78,
    "time": 40,
    "url":"https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Tabiatni%20asraylik.m4a"
  },
  {
    "id": 9,
    "className": "5-sinf",
    "ageName": "11-12",
    "title": "SAXOVAT",
    "text":
        "Bir muruvvatli saxiy odamning juda ko‘p doni bor edi. U turgan shaharda oziq-ovqat tangligi boshlandi. Saxiy odam hamma donlarini beva-bechoralarga ulashib tugatdi. Tanglik kuchaygach, o‘zi ham donga muhtoj bo‘lib qolibdi. Kishilar uni malomat qilishdi: – Qiziq odam ekansan, o‘zing muhtojlikka tushib qolishingni bila turib, nega donlaringni hammaga ulashib berib yubording? Saxiy kishi dedi: – Xalq och bo‘la turib, men rohatda yashasam, insofsizlik qilgan bo‘laman. Ochlik azobini xalq bilan barobar tortishni, xalq qayg‘usiga sherik bo‘lishni vijdonim buyurdi. Men vijdonim buyrug‘iga itoat qildim.",
    "length": 100,
    "time": 40
  },
  {
    "id": 10,
    "className": "5-sinf",
    "ageName": "11-12",
    "title": "KOMIL INSON",
    "text":
        "Komil inson barcha insonlarning ishonchli kishisi. U qanoatkor va oz yemak bilan to‘yadi. Komil kishi g‘oyat sof va jozibali bir ko‘zgu kabi bo‘lishi kerakki, shoyad unga qaragan odam o‘z aybu qusurlarini ko‘rib, o‘zlari tuzatsinlar. U barcha bilan ulfatdir. Jafolarga sabr etadi, kechiradi, u sodda va aldanuvchan, aldanganini bilsa ham bilmagandek bo‘ladi, hamishi yaxshilik ustidadir. Haqiqiy inson birovga og‘irligi tushmaydigan kishidir, Alloh taolo uchun yaqin farishtalardan ham afzaldir, yumshoq, muloyim, soddadir. Hatto soddaligi tufayli uni ahmoq deb hisoblaydilar. Do‘stini o‘zidan afzal ko‘radi. Dunyoda boshiga kelgan illatlar tufayli faryodu fig‘on chekmaydi.",
    "length": 89,
    "time": 40
  },
  {
    "id": 11,
    "className": "6-sinf",
    "ageName": "12-13",
    "title": "SUV – BEBAHO BOYLIK",
    "text":
        "Suvga tupurish, unga xas-xashak tashlash hamda isrof qilish qadimdan qoralangan. Biz ham bugungi kunda suvni tejab ishlatish, ariq va anhorlarga axlat tashlamaslik haqida uka-singillarimizga gapirib bersak, o‘zimiz ularga ibrat bo‘lsak, maqsadga muvofiq bo‘ladi. Odam och-nahor bir necha kun yashashi mumkin, lekin suvsiz yashay almasligini hamma biladi. Suv nafaqat hayot manbayi, shuningdek, hayotimizning ko‘rki hamdir. Bizning issiq mintaqamizda suvning o‘rni nihoyatda katta. Zilol suvlar oqib turgan ariqcha oldida bir zumgina o‘tiring, bahri dilingiz ochiladi. Sharsharani kuzating, ko‘zingiz dam oladi. Favvoradan sachragan suv tomchilari xuddi durdek sizga orom bag‘ishlaydi. Oddiy one holat, kechki payt ko‘cha-hovlilarga suv sepib, hamma yoqni orasta qilib, muzdekkina qilib o‘tirishning fayziga nima yetsin?",
    "length": 105,
    "time": 40
  },
  {
    "id": 12,
    "className": "6-sinf",
    "ageName": "12-13",
    "title": "INSHO",
    "text":
        "Adabiyot fanidan nazorat ishi bo’lishi kerak edi. Adabiyot o‘qitivchimiz Mahmud Ilhomov doskaga bir necha mavzuni yozib qo‘ydilar. Oxirgisi erkin mavzudagi insho ekan: «Mening Vatanim». Menga shu mavzu yoqdi. «Mening Vatanim» deb sarlavha qo‘ydim. Ancha vaqtgacha inshoni nimadan boshlash kerakligini bilmay o‘tirdim. Mahmud Ilhomovich qiynalib o‘tirganimni sezdi, shekilli, partalar orasidan asta-asta yurib, mening yonimga kelib to‘xtadilar. Daftarimga qaradilar. Hech narsa yozilmagan. – Boshlab olish shunaqa qiyin bo‘ladi, - dedilar o‘qituvchimiz. Vatan haqida o‘qiganlaringni bir eslab ko‘rgin. Kecha yod aytib bergan she’ringdan boshlasang ham bo‘ladi. E.Vohidovning «O’zbegim» she’rini yod aytib bergan edim. She’rning birinchi satrini sarlavhadan keyin epigraf qilib yozdim, shundan keyin fikr quyilib kelaverdi…",
    "length": 103,
    "time": 40
  },
  {
    "id": 13,
    "className": "7-sinf",
    "ageName": "13-14",
    "title": "SHARAFLI KASB",
    "text":
        "Ibtidoiy jamiyat davridayoq odamlar ovchilik, keyinroq esa chorvachilik, dehqonchilik, kosibchilik bilan shug‘ullanganlar. Jamiyat rivojlangan sari ortib borayotgan ehtiyoj va talabni qondirish uchun kasblar ham ko‘payib borgan. Bugungi kunda jamiyatimizni novvoy, uchuvchi, huquqshunos, konstruktor, sartarosh, operator, oshpaz, soatsoz, shaxtyor, haydovchi, traktorchi, suvoqchi, ekskovatorchi, buldozerchi, payvandchi, aktyor, xonanda, rassom, shifokor, musiqachi, bastakor, duradgor, temirchi, hisobchi, naqqosh, chilangar, broker, yozuvchi, menenjer va hokazo kabi yuzlab kasblarsiz tasavvur etib bo‘lmaydi. Ko‘pchiligimiz hali maktabga bormasimizdanoq, ayrimlarimiz esa maktabda o‘qiy boshlagach, o‘zimizga kasb tanlaymiz. Kimdir mashhur sportchi, kimdir taniqli jurnalist, yana kimdir mohir tikuvchi, tergovchi, quruvchi, kosmonavt, harbiy mutaxassis bo‘lishni orzu qiladi. Har birimiz shu ezgu orzuyimizga erishish, tanlagan kasbimizni egallash uchun tinmay o‘qiymiz, izlanamiz, intilamiz. Dunyoda shunday bir sharafli kasb egalari borki, ular ming yillardan beri barcha xalqlar orasida el-yurt hurmatiga sazovor bo‘lib keladi",
    "length": 129,
    "time": 45
  },
  {
    "id": 14,
    "className": "7-sinf",
    "ageName": "13-14",
    "title": "ONA",
    "text":
        "Ona! Bu hayot kabi abadiy va aziz so‘z. Bu so‘zda olam-olam ma’no bor. Ona borki, odam bor; ona borki, Vatan bor. Zero Ona kabi muqaddas va tabarruk, aziz va mo‘tabar, beg‘araz va beminnat inson bu yorug‘ olamda topilmaydi. Ona uchun o‘z farzandlarini tarbiyalashdan, voyaga yetkazishdan buyuk baxt bo‘lmasa kerak. Shuning uchun ham ona farzandi uchun har qanday qiyinchiliklarga bardosh beradi, chidaydi, farzand uchun chekilgan bu nihoyasi yo‘q kulfat, mashaqqatlardan xafa bo‘lish o‘rniga, aksincha, o‘zini baxtiyor his etadi. Hadisi sharifda aytilishicha: “Musoviya ibn Xayida aytadilarki, Rasulullohdan: “ Ey, Rasululloh, men yaxshiligimni kimga qilsam bo‘ladi?” – deb so‘radim. “Onangga”,- dedilar. Men shu savolni uch marta qaytarsam ham, Rasululloh: “Onagga”, - deyaverdilar. To‘rt marta so‘raganimda “Otangga va yaqin bo‘lgan qarindoshlaringga”,- dedilar. Darhaqiqat, go‘dakni qalbida to‘qqiz oy ko‘targan, dunyoga keltirgan, tarbiyalab inson darajasiga ko‘targan - bu Ona! Bejiz aytilmagan, “Onani bir qo‘li beshikni, bir qo‘li dunyoni tebratadi” deb. Ona qo‘li nafaqat dunyoni, bunyodkorlikni, hayotni tebratadi.",
    "length": 130,
    "time": 45
  },
  {
    "id": 15,
    "className": "8-sinf",
    "ageName": "14-15",
    "title": "NOCHORLIK NIMADAN?",
    "text":
        "Tog‘ qishloqlaridan birini kuchli sel bosibdi. Sel bir xonadonning Hasan va Husan ismli egizaklarini ham oqizib ketibdi. Bu qishloqdan ancha quyidagi bir joyda Hasanni bir cho‘pon, boshqa yerda Husanni bir hunarmand qutqaribdi va o‘zlariga asrandi o‘g‘il, aniqrog‘i, xizmatkor qilib olibdi. Bolalar qiyinchilik bilan ulg‘ayibdilar. Bo‘sh, kamharakat va qo‘rqoq Hasan tushkunlikka tushibdi va taqdirim shu ekan deb, cho‘ponga xizmatkor bo‘lib qolaveribdi. Husan esa tabiatan tirishqoq va dadil ekan.U qunt bilan ishlabdi, hayotni diqqat bilan o‘rganibdi, oqilona harakat qilibdi. U tezda hunarmandlik sirlarini o‘zlashtiribdi, halol ishlab, asta-sekin o‘z ishini tashkil etibdi. Yosh hunarmand o‘z kasbiga, uyiga, bola-chaqasiga, do‘koniga ega bo‘libdi, zavqli mehnat bilan tinch yashay boshlabdi. Kunlardan bir kuni aka-ukalar bir-biri bilan topishibdi. Shunda Hasan taqdiridan, nochorlikdan nolibdi. Ukasi Husan esa qanday qilib baxtli bo‘lgani, o‘z harakatlari, tadbirkorligi haqida so‘zlab beribdi. Shuning uchun ham xalqimiz: “Nochorlik – harakatsizlikdan”, deydi.",
    "length": 143,
    "time": 45
  },
  {
    "id": 16,
    "className": "8-sinf",
    "ageName": "14-15",
    "title": "BO‘ZBOLA",
    "text":
        "Qishloqda bir bo’zbola bo’ladi. Bo’zbola yelkador, pishiq qomatlik bo’ladi. Kulcha yuzlarida chuqur-chuqur kuldirgichlari bo’ladi. Qo’y ko’zlik, siyrak qoshlik bo’ladi. Bo’zbola qomatini g’oz tutadi. Joyida tik turadi. Qo’llarini ko’kragiga qovushtiradi yo beliga tiraydi. Bir nuqtaga tikiladi. Qayerga tikiladi, nimaga tikiladi? Bilmaymiz, o’zi-da bilmaydi. Shox-u butog’ing bormi, muncha kerilasan, deymiz. U mizoji xush ko’rmish odamlar bilan salom-alik qiladi. Chin dildan gapirishadi. Ko’ngliga o’tirmaydiganlar bilan salomlashgisida kelmaydi! Oqibat, bo’zbola bizni nazarga ilmaydi, deymiz. U o’zini biz uchun dil-dildan oshno biladi. Bir qorindan talashib chiqqanlardayin bo’lsam, deydi. Aqalli, one yomonligimizni ko’rsa bo’ldi! Bizdan qo’lini yuvib qo’ltiqqa uradi. Biz bilan salom-alik qilmaslik payida bo’ladi. Ichimdan top deb yuradi. U odamovi! U olislardan ko’z uzmaydi, kipriklarini-da pirpiratmaydi. Biz u tikilmish tarafga qaraymiz. Zangori ufq. Aqalli bulutlar-da yo’q. U bizni hayron qoldirib yashaydi! Bir nimani so’rasak, ha yo yo’q deb qo’ya qoladi. Qo’liga suv beramiz. Suvni go’yo birinchi ko’rayotganday tikiladi. Minnatdorchilikni tilab olamiz. «Sen ham odamga o’xshab biror nima de». «Nima deyin?» «Hech bo’lmasa, baraka toping, de». Shunda u tizzalarini quchoqlaydi. Olis-olislarga — Bobotog’ cho’qqilariga o’ychan o’ychan termiladi",
    "length": 168,
    "time": 45
  },
  {
    "id": 17,
    "className": "9 va undan katta sinflar",
    "ageName": "15…",
    "title": "MILLATNING OYNASI",
    "url": "https://jvqhqinpulczyhgckgbb.supabase.co/storage/v1/object/public/imlogo-audios//Millatning%20oynasi.m4a",
    "text":
        "Xalqimiz tilimizni, Vatanimizni uyqash tarzda – “ona tili”, “Ona Vatan” deb e’zozlaydi. Bunday mehr-muhabbatda katta ma’no bor. Shu bois ham taqdir taqozosi bilan boshqa mamlakatlarga borib, yashab qolishga majbur bo‘lgan vatandoshlarimiz o‘zbek tilimizni o‘zlari uchun Vatan o‘rnida ko‘radilar, unga suyanadilar,undan madad, kuch-qudrat oladilar. Ana shu go‘zal va qudratli ona tilimiz istiqlol tufayli o‘zining qonuniy o‘rnini topish imkoniga ega bo‘ldi. Bugungi kunda o‘zbek tilining gullab-yashnashi uchun barcha yo‘llar ochiq: son-sanoqsiz nashriyotlar, gazeta-jurnallar, radiostudiyalar, telestudiyalar, Til va adabiyot instituti, maxsus atamaqo‘m… Tilimiz taraqqiyotida ancha-muncha ijobiy o‘zgarishlar yaqqol ko‘zga tashlanib turibdi. Bir misol: mustaqillikkacha televideniye yoki radiodan o‘zbek tilida burro-burro gapirayotgan ingliz, nemis yoki fransuzni onda sondagina ko‘rgan bo‘lsangiz, hozir qariyb har kuni ko‘rasiz, eshitasiz. Bu – faxr emasmi! Albatta, odam quvonadigan hol. Chiroyli o‘zbek tilida gapirayotgan xorijlikning kalomini eshitganingizda, beixtiyor ustod Abdulla Qahhorning ichki bir mehr bilan aytgan: ”Juda boy, chiroyli tilimiz bor. Bu tilda ifoda etib bo‘lmaydigan fikr, tuyg‘u, holat yo‘q!” degan haqqoniy so‘zlarini eslaysiz. Ha, shunday ajoyib ona tilimiz bor! Biroq, biz o‘z tilimiz – o‘zbek tilimizga unga munosib tarzda sadoqat ko‘rsatayotirmizmi, munosib tarzda hurmatini joyiga qo‘yayotirmizmi? Rostini aytaylik: ayrim zamondoshlarimiz tilimizga beparvolarcha, mas’uliyatsizlik bilan, ba’zi hollarda esa bepisand munosabatda bo‘ladilar. Bunga ishonch hosil qilish uchun hech bo‘lmasa gazeta-jurnallar, radio-televideniye tiliga bir e’tibor bering!... Noto‘g‘ri so‘z qo‘llashlar, siyqa gaplar talaffuzdagi no‘noqlik, beo‘xshov tarjimalar, shevaga xos so‘z, qoshimchalar! Shundagina biz ONA – TIL oldidagi burchimizni bajargan bo‘lamiz. Zotan, ona tili – millatning aslida kim ekanini ko‘rsatuvchi haqqoniy oynadir.",
    "length": 230,
    "time": 45
  },
  {
    "id": 18,
    "className": "9 va undan katta sinflar",
    "ageName": "15…",
    "title": "INSOF, NOMUS VA HAQGO‘YLIK FIDOYISI",
    "text":
        "Insof, nomus va haqgo‘ylik Abdulla Qodiriy hayotining asosiy tamoyillari edi. Tabiat in’om qilgan nodir iste’dod chinakam o‘zbekona mehnatkashlik bilan uyg‘unlashgani uchun Qodiriyning qalamidan asrlar mobaynida eskirmaydigan asarlar dunyoga keldi. 1894-yilning 10-aprelida Toshkent shahridagi o‘rtahol oilalardan birida dunyoga kelgan Abdulla Qodiriy o‘z davrining maktab va madrasalarida muntazam o‘qish imkoniga ega bo‘lmasa-da, ilmga chanqoqligi va tirishqoqligi tufayli zamonasining eng bilimdon kishilaridan biriga aylandi. 1917-yilgi to‘ntarishlargacha o‘ziga to‘q xonadonlarda turli yumushlar bilan band bo‘lgan: prikazchik (ishboshqaruvchilik), ustachilik, bog‘bonlik qilgan. Hamisha xalq orasida bo‘lgan, uning ehtiyojlarini, og‘riqli joylarini, kayfiyat-u istaklarini bilgan yozuvchi asarlaridagi dilbar obrazlar orqali o‘zi mansub bo‘lgan xalqning turmushini yaxshilash, ma’naviyatini yuksaltirish, milliy g‘ururini uyg‘otishga intildi. Uning hikoyalari chiqqan jurnallar, gazetalar qo‘lma-qo‘l bo‘lib ketardi. Feletonlari bosilgan «Mushtum» jurnali hamisha talash bo‘lardi. Romanlarini o‘qish uchun navbat kutib turganlarning sanog‘iga etib bo‘lmas, «O‘tkan kunlar» romanini yod biladigan kitobxonlar bor edi. Chunki adib inson ruhiyatining sirli va nozik jihatlarini chuqur, ta’sirli va haqqoniy aks ettirardi. Uning asarlari yolg‘iz haqqoniylikdan tashqari, go‘zal ifoda uslubi bilan ham ajralib turardi. O‘zbek adabiy tilining hozirgi shaklini bunyod etishda hech bir yozuvchi Abdulla Qodiriy kabi muhim o‘rin tutmagan.",
    "length": 178,
    "time": 45
  }
];
