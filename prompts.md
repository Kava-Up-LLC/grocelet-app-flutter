# The prompts behind ShopList

ShopList is a shared grocery list for everyone in a house. When someone gets to the store they tap
**"I'm at the store"**, the rest of the house gets a push, and anything they add shows up with a **"New"** badge.

Built with **three prompts** sent to a coding agent (Claude Code) with the **AppAmbit MCP** connected, on branch
`dev`. Product rules, data, structure and design: [docs/tech/shoplist/tech_shoplist.md](docs/tech/shoplist/tech_shoplist.md).
Agent rules: [AGENTS.md](AGENTS.md).

| Step | Where | What it builds |
|---|---|---|
| 0 | By hand | AppAmbit apps, App Keys, push credentials, Firebase file |
| 1 | Agent + AppAmbit MCP | Push check, the database, the cloud function |
| 2 | Agent, Flutter | The shared list on two phones |
| 3 | Agent, Flutter | "I'm at the store", the push and the "New" badge |

---

## 0. By hand (before the agent)

1. AppAmbit dashboard: create **ShopList - iOS** (iOS, Flutter) and **ShopList - Android** (Android, Flutter).
2. Copy `.env.example` to `.env` and paste both App Keys. Never in the chat.
3. Firebase: Android app with package **`com.kavaup.shoplist`** → download `google-services.json` →
   `android/app/google-services.json`. Service-account JSON → AppAmbit **ShopList - Android** → App Info →
   Push Notifications Credentials.
4. Apple: App ID **`com.kavaup.shoplist`** with Push Notifications. APNs key `.p8` + Key ID + Team ID →
   AppAmbit **ShopList - iOS** → App Info → Push Notifications Credentials.
5. `git checkout dev`.

---

## 1. Backend in AppAmbit: push check, database, cloud function

```text
Use the AppAmbit MCP to set up the backend for ShopList, a shared grocery list for a house.
Call get-started-tool first. Work on the two apps "ShopList - iOS" and "ShopList - Android".
Read docs/tech/shoplist/tech_shoplist.md sections 4, 5, 6 and 11 before you start.

FIRST, CHECK PUSH. Stop if it fails.
- Find out how a Cloud Code function can send a push notification to specific users of an app
  (users identified with AppAmbitSdk.setUserId), and whether one function can reach users on
  BOTH apps (an iPhone and an Android phone in the same house).
- Tell me what you found and where you found it (doc or MCP tool). If Cloud Code cannot send a
  push to specific users, STOP and create nothing. Give me the options instead.

DATABASE
- Create the database ShopListDb and link BOTH apps to it.
- Create the tables houses, members and items and their indexes exactly as in section 5.
  Dates always come from the database clock.

CLOUD CODE
- Write cloud_functions/start_shopping.mjs as in section 6: one shopper per house at a time
  (atomic claim, a 3-hour-old trip can be taken over), push to every OTHER member:
  "Ana is at the store. Add what you need." with data open=list.
- Write cloud_functions/start_shopping.test.mjs and make it pass with node --test.
- Deploy it to both apps with an HTTP trigger.
- Test it for real: a test house with two members, call it twice (second call refused),
  show me both results, then delete the test rows.

Commit on dev. End with a table "What the agent did": AppAmbit | ShopList app.
```

---

## 2. The app: one list for the whole house

```text
Build the ShopList Flutter app on branch dev, following docs/tech/shoplist/tech_shoplist.md
and AGENTS.md. Read sections 2, 3, 5, 7, 8 and 9 first.

SETUP
- Bundle id com.kavaup.shoplist on Android and iOS, display name ShopList.
- Packages from section 3 only. Hanken Grotesk from ../quote_generator_app/assets/fonts.
- Start the AppAmbit SDK with the per-platform key from .env.
- The folder structure of section 7.1, exactly.

STATE, NO PACKAGES
- No provider, riverpod or bloc. One controller per feature that extends ChangeNotifier,
  views rebuild with ListenableBuilder, no setState for app data (section 7.2).

FEATURES (only these)
- House by code: Welcome, Create house (nickname, then the 6-letter code big with Copy),
  Join house (code + nickname). One house per phone, saved locally.
- Shared list: add (name + optional quantity), check off, swipe to delete, Clear checked.
  Reload on open, on resume and on pull to refresh.
- Online only: any network failure shows the red "No connection" banner with Retry.
- Analytics events from section 8.

DESIGN
- Tokens and screens of sections 7.3 and 7.4. Clean, consistent, all in English.

TESTS
- Controller tests with fake repositories, as listed in section 7.1. flutter analyze clean.

Then run it on my iPhone and my Android phone and tell me the steps to check that an item
added on one shows up on the other. Commit on dev. End with the table
"What the agent did": AppAmbit | ShopList app.
```

---

## 3. "I'm at the store": the push and the New badge

```text
Add the store trip to ShopList on branch dev, following docs/tech/shoplist/tech_shoplist.md
sections 2, 4, 6 and 7.3. Use the push approach confirmed in prompt 1.

PUSH IN THE APP
- appambit_sdk_push_notifications on iOS and Android, started after the SDK.
- AppAmbitSdk.setUserId(member_id) on every start.
- Ask for notification permission once, the first time the List screen opens.
- A ShopList push with the app open reloads the list; tapping one opens the list.

THE STORE BUTTON
- Big "I'm at the store" button when nobody is shopping. It calls the start_shopping function.
- Someone else shopping: "Ana is shopping". Me shopping: "You're at the store" + Done.
- Refused because someone else is already shopping: show "Ana is already at the store."

NEW WHILE SHOPPING
- Items created after shopping_since get the yellow "New" badge on every phone.
- Done clears the trip and every badge. A trip older than 3 hours counts as finished.

TESTS
- Item.isNew rules (including the 3-hour expiry) and the controller's shopping flow.

Then the real test with both phones: the iPhone taps "I'm at the store", the Android phone
gets the push and adds "milk", the iPhone pulls to refresh and sees "milk" with New.
Commit on dev. End with the table "What the agent did": AppAmbit | ShopList app.
```
