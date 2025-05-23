# SmartPantri – Intelligens Készlet- és Bevásárlólista Menedzser

## Leírás

A SmartPantri egy mobilalkalmazás, amely segíti a háztartási készletek és bevásárlólisták kezelését, csoportos együttműködéssel, kiadáskövetéssel, receptajánlóval és értesítésekkel. A cél az élelmiszer-pazarlás csökkentése és a mindennapi vásárlás megkönnyítése.

## Fő funkciók

- **Regisztráció/Bejelentkezés**: E-mail/jelszóval vagy Google-fiókkal.
- **Csoportok**: Bevásárlólista megosztása, közös kezelés.
- **Bevásárlólista**: Termékek hozzáadása, szerkesztése, törlése.
- **Költségkövetés**: Vásárlások rögzítése, havi kiadások megjelenítése, diagramok.
- **Hűtőtartalom**: Lejárati idő figyelése, értesítés romlandó termékekről.
- **Receptajánló**: Személyre szabott receptek, szűrhető találatok.
- **Csoportos chat, AI-asszisztens**: Valós idejű üzenetváltás, ChatGPT alapú segítség.
- **Push értesítések**: Lejárat, vásárlás, üzenet, stb.
- **Profil/beállítások**: Nyelv (magyar/angol), jelszóváltás, téma, fiók törlés.

## Technológiák

- **Flutter (Dart)**
- **Firebase Firestore, Auth, Storage, Cloud Messaging**
- **ChatGPT API**
- **Spoonacular API**
- **Google Translate API**

## Könyvtárstruktúra

- `config/` – Alkalmazás beállításai, Firebase konfig
- `l10n/` – Lokalizációs fájlok (magyar/angol)
- `models/` – Adatmodellek
- `providers/` – Állapotkezelés
- `screens/` – Képernyők
- `services/` – Backend és API logika

## Tesztelés

- Egységtesztek (unit, mock) a fő funkciókra
- Android Studio + GitHub verziókövetés

**Készítette:** Fekete Ádám, SZTE Informatikai Intézet  
**Témavezető:** Dr. Bilicki Vilmos  
**E-mail:** h157514@stud.u-szeged.hu
