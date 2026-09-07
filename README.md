# Vakil - جستجوی قوانین

## ساخت APK با GitHub Actions

1. همه فایل‌های این پوشه را در ریشه یک Repository جدید در GitHub آپلود کنید.
2. فایل‌ها را Commit کنید.
3. به تب Actions بروید.
4. Workflow با نام Build Android APK را اجرا کنید.
5. پس از پایان Build، فایل APK را از بخش Artifacts دانلود کنید.

## نکته مهم

این پروژه عمداً پوشه android را داخل فایل ZIP ندارد تا خطای فایل‌های ناقص Gradle رخ ندهد.
GitHub Actions قبل از Build این دستور را اجرا می‌کند:

flutter create --platforms=android .

سپس APK ساخته می‌شود.

## سرویس جستجو

اپ از آدرس زیر استفاده می‌کند:

https://rc.majlis.ir/fa/search/searchAjax

اگر خود دامنه rc.majlis.ir از اینترنت یا DNS گوشی قابل دسترسی نباشد،
اپ نمی‌تواند مشکل DNS را از داخل Flutter برطرف کند.
