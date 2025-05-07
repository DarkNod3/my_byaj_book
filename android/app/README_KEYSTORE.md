# Keystore Setup for Release

Before publishing your app to the Google Play Store, you need to create a keystore file and configure it in the project. This keystore will be used to sign your app, and **it's very important to keep it secure and never lose it**.

## 1. Generate a Keystore

Run the following command in a terminal to generate your keystore:

```bash
keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

You'll be prompted to:
- Create a password for the keystore
- Enter your name, organization, and location details
- Create a password for the key (you can use the same as the keystore password)

## 2. Move the Keystore

Move the generated `my-release-key.jks` file to the `android/app` directory of your Flutter project.

## 3. Configure Credentials

Add the keystore information to your `local.properties` file in the `android` folder. **Do not commit this file to version control!**

```properties
# Keystore configuration
keystore.path=my-release-key.jks
keystore.password=your-keystore-password
keystore.key_alias=my-key-alias
keystore.key_password=your-key-password
```

Replace the values with your actual keystore details.

## 4. Build the App

Now you can build your app for release:

```bash
flutter build appbundle --release
```

## Important Security Notes

1. **NEVER include your keystore or passwords in version control**
2. **ALWAYS back up your keystore file in a secure location**
3. If you lose your keystore, you will not be able to update your app on the Play Store
4. Keep your passwords secure and do not share them

## Environment Variables Alternative

You can also set up keystore details using environment variables:

```
RELEASE_STORE_FILE=path/to/your/keystore.jks
RELEASE_STORE_PASSWORD=your-keystore-password
RELEASE_KEY_ALIAS=your-key-alias
RELEASE_KEY_PASSWORD=your-key-password
```

This is useful for CI/CD environments. 