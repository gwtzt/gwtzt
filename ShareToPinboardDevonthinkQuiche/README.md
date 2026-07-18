# Share to Pinboard, DEVONthink & Quiche Reader

A single iOS/iPadOS Share Sheet action that takes a webpage and sends it to:

- **Pinboard** — via Pinboard's own `posts/add` API (no client app needed)
- **DEVONthink To Go** — via its `createbookmark` URL command
- **Quiche Reader** — via its own Share Extension (tapped manually, see below)

This isn't Xcode/Swift code — it's a build guide for a **Shortcuts app** automation,
since none of these three integrations can be driven from a compiled app without
each service's private API keys, and Shortcuts already has first-class access to
all three mechanisms.

## Why it works this way

| App | Mechanism | Why |
|---|---|---|
| Pinboard | Direct API call (`GET https://api.pinboard.in/v1/posts/add`) | Pinboard has no official iOS app or Share Extension, but its API is simple and well documented: https://pinboard.in/api/ |
| DEVONthink To Go | `x-devonthink://x-callback-url/createbookmark` URL command | DEVONthink To Go supports this URL command specifically for adding a page to its Reading List without opening the app's UI. This is the same mechanism used by the community's ["Add URL to DEVONthink Reading List"](https://discourse.devontechnologies.com/t/shortcut-add-url-to-devonthink-and-devonthink-to-go-reading-list/80066) shortcut. |
| Quiche Reader | Its own Share Extension | Quiche Reader (https://apps.apple.com/us/app/quiche-reader/id1387881185) only exposes a Share Extension for saving links — it has no public URL scheme or Shortcuts action to drive automatically. Shortcuts cannot select a specific extension in the system share sheet programmatically, so this last step needs one manual tap. |

## Before you build it

Get your Pinboard API token: Pinboard → **Settings → Password** → copy the token
(format `yourusername:XXXXXXXXXXXXXXXXXXXX`).

⚠️ The token will be stored in plain text inside the shortcut on your device.
That's fine for personal use, but **don't share/export this shortcut** to anyone
else once the token is in it.

## Build steps (Shortcuts app, iPhone/iPad)

1. Open **Shortcuts** → **+** to create a new shortcut. Name it e.g.
   `Share to Pinboard, DEVONthink & Quiche`.
2. Tap the shortcut's settings (ⓘ) → enable **Show in Share Sheet**. Under
   **Share Sheet Types**, keep only `URLs`, `Safari web pages`, and `Text`.
3. Add action **Text** — set the content to `Shortcut Input` (the magic
   variable representing whatever was shared in).
4. Add action **URL** — set it to the `Text` variable from step 3. This
   coerces the input into a clean URL, stored below as `Page URL`.
5. Add action **Get Name** (input: `Shortcut Input`) to get the page title.
   Rename this result `Page Title` (tap the result → Rename Variable). If the
   share source doesn't provide a name, this returns empty — that's fine.

### Step A — Send to Pinboard

6. Add action **URL Encode** → input `Page URL` → rename result `Encoded URL`.
7. Add action **URL Encode** → input `Page Title` → rename result `Encoded Title`.
8. Add action **Text**, and build the request URL:
   ```
   https://api.pinboard.in/v1/posts/add?url=Encoded URL&description=Encoded Title&auth_token=YOUR_TOKEN_HERE&format=json
   ```
   (Insert the `Encoded URL` / `Encoded Title` variables at those spots; type
   your real Pinboard auth token in place of `YOUR_TOKEN_HERE`.)
9. Add action **Get Contents of URL** → set the URL field to the `Text` from
   step 8 (leave method as GET). You can ignore the response.

### Step B — Send to DEVONthink To Go

10. Add another **Text** action:
    ```
    x-devonthink://x-callback-url/createbookmark?location=Encoded URL&title=Encoded Title
    ```
11. Add action **Open URLs** → input: the `Text` from step 10.
    DEVONthink To Go will briefly open, save the bookmark to its Reading
    List/Inbox, and hand control back. If it doesn't return automatically,
    just swipe back to the previous app — the bookmark is already saved.

### Step C — Finish in Quiche Reader

12. Add action **Show Notification** → text: `Saved to Pinboard & DEVONthink. Tap Quiche Reader next.`
13. Add action **Share** → input: `Page URL`. This re-opens the system share
    sheet — tap **Quiche Reader**'s icon to finish saving it there. (Pinboard
    and DEVONthink will also be in that list if you ever want to re-share
    manually, but you don't need to tap them again.)

## Using it

From Safari (or Mail, Twitter/X, any app with a share sheet), tap **Share**
→ scroll to your new shortcut → it silently posts to Pinboard, hands off to
DEVONthink To Go, then reopens the share sheet so you can tap Quiche Reader.

## Notes / limitations

- Shortcuts can't invoke a third-party Share Extension without user
  interaction — that's why the Quiche Reader step still needs one tap.
- If you ever switch to a real Pinboard client app (e.g. Pushpin, GoodLinks)
  instead of the raw API, delete steps 6–9 and add another **Share** action
  for it instead, same as Step C.
- Rate limit: Pinboard's API allows one call per user roughly every 3
  seconds, which a single share action stays well within.
