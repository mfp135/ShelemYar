# ساخت ابری شلم‌یار

این پروژه شامل GitHub Actions است که پس از Push یا اجرای دستی workflow:

1. Flutter را روی runner ابری نصب می‌کند.
2. در صورت نبودن پوشه‌های platform، Android و Windows را ایجاد می‌کند.
3. وابستگی‌ها را دریافت می‌کند.
4. تست‌ها را اجرا می‌کند.
5. APK Release می‌سازد.
6. نسخه Windows Release می‌سازد.
7. خروجی‌ها را به صورت Artifact ذخیره می‌کند.

APK: `ShelemYar-APK`
Windows: `ShelemYar-Windows`
