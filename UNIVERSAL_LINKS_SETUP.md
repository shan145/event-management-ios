# Universal Links Setup Guide

This guide explains how to set up Universal Links so that invite links (e.g., `https://us-eventify.com/join/{token}`) open directly in the iOS app when clicked.

## What Are Universal Links?

Universal Links allow iOS apps to handle HTTPS URLs. When a user taps a Universal Link:
- If the app is installed, it opens in the app
- If the app is not installed, it opens in Safari/web

## iOS App Configuration (Already Done)

The iOS app has been configured with:
1. ✅ Associated Domains entitlement (`applinks:us-eventify.com`)
2. ✅ Universal Link handling in `AppDelegate`
3. ✅ Navigation coordinator to route invite links
4. ✅ `InviteLinkView` to display and handle group invitations

## Server-Side Configuration (Required)

For Universal Links to work, you need to serve an `apple-app-site-association` file on your web server.

### Step 1: Get Your App's Team ID and Bundle ID

1. Open Xcode
2. Select your project in the navigator
3. Select your app target
4. Go to the "Signing & Capabilities" tab
5. Note your **Team ID** (e.g., `ABC123DEF4`)
6. Note your **Bundle Identifier** (e.g., `com.us-eventify.eventable`)

### Step 2: Create the apple-app-site-association File

Create a file named `apple-app-site-association` (no file extension) with the following content:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.us-eventify.eventable",
        "paths": [
          "/join/*"
        ]
      }
    ]
  }
}
```

**Important:** Replace `TEAM_ID` with your actual Team ID from Step 1.

### Step 3: Host the File on Your Web Server

The file must be served at:
```
https://us-eventify.com/.well-known/apple-app-site-association
```

**Requirements:**
- Must be served over HTTPS
- Must be accessible without authentication
- Must return `Content-Type: application/json` (or `text/plain`)
- Must NOT have a file extension (e.g., `.json`)
- Should return a 200 status code

### Step 4: Verify the File

1. Open a browser and navigate to:
   ```
   https://us-eventify.com/.well-known/apple-app-site-association
   ```
2. You should see the JSON content
3. Verify the content type is `application/json` (check browser developer tools)

### Step 5: Test Universal Links

1. **On Device (Recommended):**
   - Install the app on a physical iOS device
   - Send yourself an invite link via Messages or Email
   - Tap the link - it should open in the app

2. **In Simulator:**
   - Long-press a link in Safari
   - Select "Open in [Your App Name]"

3. **Using Terminal:**
   ```bash
   xcrun simctl openurl booted "https://us-eventify.com/join/YOUR_TOKEN_HERE"
   ```

## Troubleshooting

### Links Open in Safari Instead of App

1. **Check Associated Domains:**
   - Verify the entitlement file includes `applinks:us-eventify.com`
   - Make sure the domain matches exactly (no `www`, no trailing slash)

2. **Verify apple-app-site-association File:**
   - Check it's accessible at the correct URL
   - Verify the JSON is valid (no syntax errors)
   - Check the `appID` matches your Team ID + Bundle ID

3. **Clear iOS Cache:**
   - Delete and reinstall the app
   - iOS caches the association file, so changes may take time to propagate

4. **Check Path Matching:**
   - The `paths` array in the association file must match your URL paths
   - We're using `/join/*` to match all invite links

### Testing Tips

- Universal Links only work on physical devices or simulators (not in Xcode preview)
- The association file is cached by iOS, so changes may take a few minutes to take effect
- You can force iOS to re-download the association file by deleting and reinstalling the app

## Example Server Configuration

### Express.js Example

```javascript
// Serve apple-app-site-association file
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.sendFile(path.join(__dirname, 'apple-app-site-association'));
});
```

### Nginx Example

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
    root /path/to/your/static/files;
}
```

## Additional Resources

- [Apple's Universal Links Documentation](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Apple's Associated Domains Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_associated-domains)

