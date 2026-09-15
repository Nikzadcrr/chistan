# راهنمای کامل بیلد اندروید برای چیستان

<div dir="rtl">

این سند قدم‌به‌قدم توضیح می‌دهد چطور فایل‌های **APK** و **AAB** بازی چیستان را بسازید.

## پیش‌نیازها

| ابزار | نسخه | توضیح |
|---|---|---|
| Godot | 4.7.x (یا 4.4 به بالا) | نسخه استاندارد (نه mono) |
| Export Templates | هم‌نسخه با گودو | از داخل خود گودو قابل دانلود است |
| JDK | 17 | برای گریدل |
| Android SDK | — | با Android Studio یا خط فرمان |

## ۱) نصب تمپلیت خروجی
در گودو: منوی `Editor > Manage Export Templates` و دکمه **Download and Install**.

## ۲) نصب Android Build Template (گریدل)
منوی `Project > Install Android Build Template` — این مرحله برای خروجی APK/AAB با گریدل الزامی است.

## ۳) تنظیم Android SDK
در `Editor > Editor Settings > Export > Android`:
- مسیر Java SDK (JDK 17)
- مسیر Android SDK

## ۴) امضای ریلیز (اختیاری برای تست، لازم برای انتشار)
یک کی‌استور بسازید:
```bash
keytool -genkeypair -v -keystore chistan-release.keystore \
  -alias chistan -keyalg RSA -keysize 2048 -validity 10950
```
سپس در `Project > Export > Android APK/AAB > Keystore` مسیر و رمزها را وارد کنید.

> ⚠️ فایل کی‌استور را هرگز در گیت کامیت نکنید (در .gitignore ما مستثناست).

## ۵) خروجی گرفتن
در پنجره Export:
- پریست **«Android APK»** → دکمه **Export Project** (تیک Export With Debug را برای انتشار بردارید)
- پریست **«Android AAB»** → برای گوگل‌پلی

خروجی‌ها در پوشه `build/` ذخیره می‌شوند.

## ۶) بیلد بدون ادیتور (خط فرمان)
```bash
godot --headless --path . --import
godot --headless --path . --export-release "Android APK" build/chistan.apk
godot --headless --path . --export-release "Android AAB" build/chistan.aab
```

## ۷) بیلد خودکار با گیت‌هاب اکشنز
هر push به شاخه `main` بیلد خودکار را اجرا می‌کند:
- **Debug APK** — برای تست سریع
- **Release APK** — امضاشده با کی‌استور رمزگذاری‌شده در Secrets
- **Release AAB** — آماده آپلود در گوگل‌پلی

نتیجه در بخش Actions → Artifacts (و در تگ‌ها، در بخش Releases) قرار می‌گیرد.

### رمزهای موردنیاز (Secrets)
| نام | توضیح |
|---|---|
| `KEYSTORE_BASE64` | فایل کی‌استور به‌صورت base64 |
| `KEYSTORE_PASSWORD` | رمز کی‌استور و کلید |
| `KEYSTORE_ALIAS_USER` | نام alias (چیستان: `chistan`) |

## عیب‌یابی

**«Unable to find Android SDK»** → مسیر SDK را در تنظیمات ادیتور درست وارد کنید.

**«Keystore was tampered»** → رمز کی‌استور یا alias اشتباه است.

**بیلد گریدل گیر می‌کند** → اولین بیلد چند دقیقه طول می‌کشد (دانلود وابستگی‌ها)؛ اینترنت سرور را چک کنید.

**APK نصب نمی‌شود** → اگر قبلاً نسخه‌ای با امضای دیگر نصب کرده‌اید، اول حذفش کنید.

</div>
