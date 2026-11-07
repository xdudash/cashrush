# Cash Rush — iOS-тайкун на Flutter

Простой бизнес-тайкун: тапаешь по монете, покупаешь бизнесы, получаешь пассивный доход (в том числе офлайн), открываешь франшизы (престиж), собираешь достижения. Без интернета, без регистрации, без рекламы.

## Структура
- `lib/game.dart` — вся логика (состояние, экономика, события, сохранение)
- `lib/main.dart` — запуск, вкладки, диалог «с возвращением»
- `lib/ui/` — экраны: Бизнес, Магазин, Профиль
- `assets/icon.png` — иконка 1024×1024
- `codemagic.yaml` — облачная сборка и отправка в TestFlight (Mac не нужен)
- `store/listing.md` — тексты для App Store и политика конфиденциальности

Папки `ios/` в репозитории нет, она генерируется при сборке (см. codemagic.yaml).

## Твои действия (≈30–40 минут, один раз)

1. **Apple Developer** (99 $/год): developer.apple.com → Certificates, IDs & Profiles → Identifiers → `+` → App IDs → Bundle ID `com.goapps.cashrush` (или свой — тогда поменяй его в `codemagic.yaml` в двух местах).
2. **App Store Connect** → Apps → `+` → New App: iOS, название «Cash Rush: Business Tycoon», выбери этот Bundle ID, SKU любой (`cashrush1`).
3. **API-ключ**: App Store Connect → Users and Access → Integrations → App Store Connect API → создай ключ с ролью *App Manager*, скачай `.p8`.
4. **GitHub**: создай приватный репозиторий и залей в него содержимое этой папки.
5. **Codemagic** (codemagic.io, вход через GitHub): Add application → выбери репозиторий → тип Flutter, использовать `codemagic.yaml`. В Teams → Integrations → App Store Connect добавь ключ (Issuer ID, Key ID, `.p8`) под именем `codemagic`.
6. Запусти workflow **iOS → TestFlight**. Через ~15 минут сборка появится в TestFlight; поставь её на свой iPhone и проверь.
7. В App Store Connect заполни карточку из `store/listing.md`, загрузи скриншоты, укажи Privacy Policy URL и нажми **Submit for Review**.

## Локальный запуск (если есть Flutter)
```
flutter create --platforms=ios --org com.goapps --project-name cashrush .
flutter pub get
dart run flutter_launcher_icons
flutter run
```
(`flutter create` не перезаписывает `lib/`, но проверь это перед коммитом.)

## Баланс
Все цифры экономики — в `lib/game.dart` (`upgradeDefs`, рост цены 1.15, формула звёзд). Если игра идёт слишком медленно или быстро, правь их там.
