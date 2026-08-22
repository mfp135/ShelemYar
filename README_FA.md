# شلم‌یار

نسخه MVP فارسی برای Android و Windows.

## Build واقعی

1. Flutter SDK را نصب کنید.
2. در پوشه پروژه اجرا کنید:

```bash
flutter pub get
flutter test
flutter build apk --release
```

برای ویندوز، روی یک محیط Windows با Visual Studio و ابزارهای C++:

```powershell
flutter build windows --release
```

طبق مستندات Flutter، خروجی EXE به‌همراه DLLها و پوشه data باید با هم توزیع شوند.

## وضعیت این تحویل

این محیط اجرایی Flutter SDK و Android SDK/Windows toolchain ندارد؛ بنابراین فایل APK یا EXE جعلی تولید نشده است. سورس پروژه، موتور قوانین، UI فارسی و تست‌ها آماده شده‌اند.


## وضعیت این نسخه
این بسته نسبت به نسخه قبلی اصلاح شده است: فایل Workflow هم در مسیر استاندارد `.github/workflows/build.yml` و هم به صورت فایل قابل مشاهده `GITHUB_ACTIONS_BUILD.yml` وجود دارد تا هنگام آپلود دستی از قلم نیفتد. پلتفرم‌های Android و Windows در خود Workflow با `flutter create --platforms=android,windows .` ایجاد و سپس تست و Build می‌شوند.
