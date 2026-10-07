# Topshiriq: tez yozish mashqi uchun o'zbekcha so'zlar to'plami

Tez yozish moduli so'zlarni bitta matn faylidan oladi: `assets/words/uz.txt`.
Hozir unda namuna sifatida ~350 ta so'z bor. Kerakli narsa — shu faylni to'liq,
tekshirilgan to'plam bilan almashtirish.

## Fayl formati

- UTF-8 matn fayli, **har bir qatorda bitta so'z**.
- `#` bilan boshlangan qatorlar izoh hisoblanadi va o'qilmaydi.
- Bo'sh qatorlar, takrorlangan so'zlar va ichida bo'sh joy bo'lgan qatorlar
  avtomatik tashlab ketiladi.

```text
# eng ko'p ishlatiladigan so'zlar
va
bilan
o'zbek
to'g'ri
ma'no
```

## Talablar

| # | Talab | Izoh |
|---|-------|------|
| 1 | **Hajm:** kamida 1 000 ta, eng yaxshisi 3 000–5 000 ta so'z | So'z qancha ko'p bo'lsa, mashq shuncha kam takrorlanadi |
| 2 | **Tartib:** eng ko'p ishlatiladigan so'zlar fayl boshida | Keyinchalik "eng ommabop 200 / 1 000 / 5 000 so'z" darajalarini shu tartib asosida ajratamiz |
| 3 | **Lotin yozuvi, kichik harflar** | Bosh harf va tinish belgilarini ilova o'zi qo'shadi ("tinish belgilari" rejimi) |
| 4 | **Uzunlik:** 1–14 harf | Juda uzun so'zlar telefon ekraniga sig'maydi |
| 5 | **Atoqli otlar kerak emas** | Ism, shahar, davlat nomlari (toshkent, alisher) kiritilmaydi |
| 6 | **Faqat harflar va tutuq belgisi** | Raqam, defis, nuqta, qisqartmalar (va h.k., AQSH) kiritilmaydi |
| 7 | **Imlosi tekshirilgan** | Ayniqsa x/h (xato — hato), tutuq belgisi (ma'no, san'at, e'tibor), o'/g' |
| 8 | **Qo'shimchali shakllar ham bo'lsin** (taxminan 30%) | kitob, kitoblar, kitobni, o'qiydi, bordim — matn tabiiyroq chiqadi |
| 9 | **Nomaqbul so'zlar yo'q** | Ilovadan o'quvchilar foydalanadi |

## Tutuq belgisi haqida

Faylda o', g' va tutuq belgisi uchun **istalgan** belgini ishlatish mumkin:
`'` `’` `‘` `ʻ` `ʼ` `` ` ``. Ilova ularning barchasini o'qish paytida bitta
belgiga keltiradi, foydalanuvchi terayotganda ham barcha variantlarni to'g'ri
deb qabul qiladi. Ya'ni `o'zbek`, `o‘zbek` va `oʻzbek` — bir xil so'z.

Ekranda esa so'zlar imlo qoidasiga mos ko'rsatiladi: `o‘`, `g‘` va tutuq
belgisi uchun `’` (masalan: `to‘g‘ri`, `ma’no`).

## Ixtiyoriy (bo'lsa yaxshi)

- **Gaplar to'plami** — `assets/words/uz_gaplar.txt`, har bir qatorda bitta
  to'liq gap (5–20 so'z, bosh harf va tinish belgilari bilan). Bu "iqtibos"
  rejimini qo'shish imkonini beradi.
- **Mavzuli to'plamlar** — masalan, maktab, tabiat, texnologiya (alohida
  fayllarda, xuddi shu formatda).

## Topshirish va tekshirish

1. Tayyor faylni `assets/words/uz.txt` o'rniga qo'ying (yoki menga yuboring).
2. `flutter test` — so'zlarni o'qish va hisoblash testlari o'tishi kerak.
3. `flutter run -d chrome` — "Tez yozish" bo'limida yangi so'zlar chiqishini
   tekshiring.

Landing sahifadagi kichik namuna (demo) alohida, qisqa ro'yxatdan foydalanadi:
`imlogo-uz/src/data/typing.tsx` → `demoWords` (60 ta so'z). Uni o'zgartirish
shart emas.
