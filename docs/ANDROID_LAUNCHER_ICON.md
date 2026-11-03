# SplitLui Android launcher icon setup

This PR configures the launcher icon generator, using the two approved
SplitLui teal icon files. Because the image files were generated in the
ChatGPT conversation rather than uploaded through GitHub, download the
separately provided `splitlui_icons_for_project.zip` and extract it into
the **repository root** before generating icons.

Expected files:

    assets/icons/app_icon.png
    assets/icons/app_icon_tran.png

The first PNG is the ordinary launcher icon. The second is the transparent
foreground for Android adaptive icons. No additional PNGs are required.

In the Android Studio Terminal at the SplitLui project root:

    flutter pub get
    dart run flutter_launcher_icons

Then use Android Studio's usual Run button (or `flutter run`).

If the app was already installed, Android launchers can cache old icons:
uninstall the debug app from the emulator/device and reinstall.

This only changes the app icon, not the in-app UI, group data, or Supabase.
For publishing to Google Play, also use the normal Play Console 512x512
store listing icon derived from the source art.

Do not merge and run the icon generator before putting the PNGs in the
folder: the generator will report that the configured icon image is missing.
