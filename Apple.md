# Deploying Interval Timer to iPad via TestFlight

This guide walks through deploying the Interval Timer app to iPads (no Developer Mode required) using TestFlight.

## Prerequisites

- Apple Developer Program membership ($99/year)
- Xcode installed with your Apple ID signed in
- Flutter SDK installed

## Current App Settings

| Setting | Value |
|---------|-------|
| Bundle ID | `com.petertools.intervalTimer` |
| Team ID | *(your Apple Developer Team ID)* |
| Version | 1.0.0 |
| Build | 1 |
| Min iOS | 13.0 |
| Orientations | Landscape only |

---

## Step 1: Register the Bundle ID

1. Go to [Apple Developer — Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** to register a new identifier
3. Select **App IDs** > **App**
4. Fill in:
   - **Description**: Interval Timer
   - **Bundle ID**: Select **Explicit**, enter `com.petertools.intervalTimer`
5. Under Capabilities, no special entitlements are needed (no push notifications, no HealthKit, etc.)
6. Click **Continue** > **Register**

## Step 2: Create the App in App Store Connect

1. Go to [App Store Connect — My Apps](https://appstoreconnect.apple.com/apps)
2. Click **+** > **New App**
3. Fill in:
   - **Platforms**: iOS
   - **Name**: Interval Timer
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.petertools.intervalTimer` from the dropdown (registered in Step 1)
   - **SKU**: `interval-timer` (any unique string, internal use only)
   - **User Access**: Full Access
4. Click **Create**

## Step 3: Build the IPA

From the project directory:

```bash
# From the project root:
# Clean and build the release IPA
flutter clean
flutter pub get
flutter build ipa --release
```

This creates an archive at:
```
build/ios/archive/Runner.xcarchive
```

And an IPA ready for upload at:
```
build/ios/ipa/interval_timer.ipa
```

### If the build fails with signing errors

Open the Xcode workspace and fix signing manually:

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select the **Runner** target
2. Go to **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select your team
5. Xcode will create/download the provisioning profile
6. Close Xcode, run `flutter build ipa --release` again

## Step 4: Upload to App Store Connect

Option A — using the command line:

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/interval_timer.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

To create an API key:
1. Go to [App Store Connect — Users and Access — Integrations — App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Click **+** to generate a new key
3. Name: `CLI Upload`, Role: `Developer`
4. Download the `.p8` file and note the Key ID and Issuer ID
5. Place the `.p8` file at `~/.appstoreconnect/private_keys/AuthKey_YOURKEYID.p8`

Option B — using Transporter (easier for one-off uploads):

1. Install **Transporter** from the Mac App Store (free, by Apple)
2. Open Transporter, sign in with your Apple ID
3. Drag `build/ios/ipa/interval_timer.ipa` into the window
4. Click **Deliver**

Option C — using Xcode directly:

1. Open the archive: `open build/ios/archive/Runner.xcarchive`
2. This opens the Xcode Organizer
3. Select the archive, click **Distribute App**
4. Choose **App Store Connect** > **Upload**
5. Follow the prompts

## Step 5: Set Up TestFlight

After the upload processes (takes a few minutes):

1. Go to [App Store Connect — My Apps](https://appstoreconnect.apple.com/apps) > **Interval Timer**
2. Click the **TestFlight** tab
3. Your build should appear under **iOS Builds** (status: Processing, then Ready to Test)
4. If prompted for **Export Compliance**, select **No** (this app doesn't use encryption beyond standard HTTPS)

### Add Internal Testers (up to 100, no review needed)

1. In TestFlight, click **Internal Testing** in the left sidebar
2. Click **+** next to "Internal Testing" to create a group
3. Name it (e.g., "Family")
4. Click **+** next to Testers, add people by Apple ID email
5. Enable the build for this group
6. Testers get an email invite immediately

### Add External Testers (up to 10,000, requires brief review)

1. In TestFlight, click **External Testing** in the left sidebar
2. Click **+** to create a group
3. Add testers by email
4. Submit the build for Beta App Review (usually approved within 24-48 hours)
5. Once approved, testers get an email invite

## Step 6: Install on iPad

On each iPad:

1. Install the **TestFlight** app from the App Store (free)
2. Open the invite email, tap **View in TestFlight**
3. In TestFlight, tap **Install** next to Interval Timer
4. The app appears on the home screen like any other app

No Developer Mode needed. No cable needed. Works over Wi-Fi.

---

## Updating the App

When you release a new version:

1. Bump the version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2   # format: name+buildNumber
   ```
   The build number must always increase (App Store Connect rejects duplicate build numbers).

2. Build and upload:
   ```bash
   flutter build ipa --release
   # Then upload via Transporter, xcrun, or Xcode
   ```

3. In App Store Connect > TestFlight, the new build appears automatically
4. If using internal testing, it's available immediately
5. If using external testing, it goes through Beta Review again

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter build ipa` fails with "no provisioning profile" | Open `ios/Runner.xcworkspace` in Xcode, enable automatic signing, select your team |
| Build number rejected ("already exists") | Increment the `+N` part in `version:` in pubspec.yaml |
| TestFlight build stuck on "Processing" | Wait up to 30 minutes; Apple processes the binary server-side |
| Testers don't receive invite | Check their email matches their Apple ID; check spam folder |
| "Export Compliance" warning | Select "No" — the app uses no custom encryption |
| App crashes on iPad but works on simulator | Check the minimum iOS version; test with `flutter run --release -d <device>` if you have a dev device |

## Notes

- TestFlight builds expire after **90 days**. Upload a new build before expiry to keep testers active.
- Internal testers must be added as App Store Connect users (with at least the "Marketing" or "Developer" role).
- External testers only need an email address — they don't need App Store Connect access.
- The app is landscape-only on iPad, which is intentional for gym use.
