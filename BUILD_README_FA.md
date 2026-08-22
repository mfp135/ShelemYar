# شلم‌یار — پروژه اصلاح‌شده برای Build ابری

این بسته شامل سورس Flutter، تست‌ها و دو نسخه از فایل Build است:

- `.github/workflows/build.yml` برای اجرای خودکار در GitHub Actions
- `GITHUB_ACTIONS_BUILD.yml` نسخه قابل مشاهده همان فایل برای جلوگیری از مشکل پوشه مخفی `.github`

## نکته مهم
این محیط امکان اجرای واقعی Flutter و تولید APK را ندارد؛ بنابراین این فایل «APK نهایی» نیست و ادعای Build موفق برای آن نمی‌شود.
Workflow داخل بسته روی Runner ابری GitHub این مراحل را انجام می‌دهد:

1. ایجاد پروژه‌های Android و Windows در صورت نیاز.
2. `flutter pub get`
3. `flutter test`
4. ساخت `app-release.apk`
5. ساخت Windows Release و بسته ZIP آن
6. ذخیره خروجی‌ها به‌عنوان Artifact

اگر پوشه `.github` در آپلود مرورگر انتخاب نشد، فایل `GITHUB_ACTIONS_BUILD.yml` را جداگانه نگه دارید و در مخزن GitHub از مسیر زیر ایجاد کنید:
`.github/workflows/build.yml`
