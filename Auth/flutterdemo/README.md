# Implement Auth in Flutter

## Dependencies

* [**http**](https://pub.dartlang.org/packages/http): A composable, Future-based library for making HTTP requests.
* [**flutter_appauth**](https://pub.dev/packages/flutter_appauth): A well-maintained wrapper package around [AppAuth](https://appauth.io/) for Flutter developed by the [dexterx.dev](https://dexterx.dev/) team. AppAuth authenticates and authorizes users and supports the PKCE extension. it's a package that wraps around the `AppAuth` native libraries. It provides access to the methods required to perform user authentication, following the standards that Auth0 also happens to implement. To build a communication bridge between your Flutter app and Auth0, you need to set up a callback URL to receive the authentication result in your application after a user logs in with Auth
* [**flutter_secure_storage**](https://pub.dev/packages/flutter_secure_storage): A library to securely persist data locally

## Android

You also need to tweak the Android build system to work with `flutter_secure_storage`.

`defaultConfig { // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html). applicationId "com.auth0.flutterdemo" minSdkVersion 18 targetSdkVersion 28 versionCode flutterVersionCode.toInteger() versionName flutterVersionName manifestPlaceholders = [ 'appAuthRedirectScheme': 'com.auth0.flutterdemo' ] }`

## iOS

iOS default settings work with the project dependencies without any modifications. You can set the callback scheme by adding the following entry to the `<dict>` element present in the `ios/Runner/Info.plist` file:

```
   <key>CFBundleURLTypes</key>
   <array>
      <dict>
         <key>CFBundleTypeRole</key>
         <string>Editor</string>
         <key>CFBundleURLSchemes</key>
         <array>
            <string>com.auth0.flutterdemo</string>
         </array>
      </dict>
   </array>
```
