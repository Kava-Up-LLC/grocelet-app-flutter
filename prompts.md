# The prompts behind ShopList

ShopList is one grocery list for everyone in a house. When someone gets to the store they tap
**"I'm at the store"**, everyone else gets a notification, and anything they add shows up with a **"New"** badge.

> *As someone who lives with other people, I want one shared grocery list that tells everyone when I'm at the
> store, so I come home with everything we need.*

The app is built with **three prompts** sent to a coding agent (Claude Code) with the **AppAmbit MCP** connected.

| Step | Where | What it builds |
|---|---|---|
| 0 | By hand | The AppAmbit apps, their keys and the push credentials |
| 1 | Agent + AppAmbit MCP | The database and the two cloud functions: join a house, and the "at the store" alert |
| 2 | Agent, Flutter | The house and the shared list on two phones |
| 3 | Agent, Flutter | "I'm at the store", the notification and the "New" badge |

---

## 0. By hand

1. AppAmbit dashboard: create **App ShopList - ios** and **App ShopList - Android** (stack Flutter).
2. Put both App Keys in `.env` (template `.env.example`). Never in the chat.
3. Upload the push credentials to each app (App Info → Push Notifications Credentials): FCM service-account JSON
   for Android, APNs `.p8` key for iOS. App id on both platforms: `com.kavaup.shoplist`.

---

## 1. The backend in AppAmbit

```text
Use the AppAmbit MCP to set up the backend for ShopList, a shared grocery list for a house.
Call get-started-tool first and work on the apps "App ShopList - ios" and "App ShopList - Android".

The idea: people who live together join the same house with a 6-letter code and share one
list. When someone taps "I'm at the store", everyone else in the house gets a notification,
and anything added while they shop is marked as new. No login.

DATABASE
- Create ShopListDb and link BOTH apps to it, so an iPhone and an Android phone share a house.
- houses: id, code (6 letters, unique), shopper_id, shopping_since, created_at
- members: id, house_id, nickname, platform (ios | android), consumer_id, created_at
- items: id, house_id, name, quantity (optional text), checked, added_by, created_at
- Ids are uuids. Dates always come from the database clock, never from the phone.

CLOUD CODE (deploy each function to both apps, HTTP trigger with the same name)
- join_house: create a house (new code, no I or O, retried if taken) or join one by code.
  Save the caller's AppAmbit consumer id on the member, so we can send it a push later.
  Calling it again with the same member refreshes the consumer id instead of duplicating it.
- start_shopping: only one shopper per house at a time. Claim the trip in a single update;
  a trip older than 3 hours counts as finished. If someone else is shopping, return their
  nickname and send nothing. Otherwise push to every OTHER member by consumer id:
  "Ana is at the store. Add what you need."  (data: open = list)
- Unit tests for both against a real in-memory SQLite with the same schema.
- Then run both for real with a test house and two members, and delete the test data.

End with a table "What the agent did": AppAmbit | ShopList app.
```

---

## 2. The app: one list for the whole house

```text
Build the ShopList Flutter app for iPhone and Android on AppAmbit. Follow AGENTS.md and match
DESIGN.md exactly (the "Fridge Door" look, fonts already in assets/fonts). App id
com.kavaup.shoplist, display name ShopList, Android minSdk 24. Screens in English.

KEEP IT SIMPLE
- No state-management packages: one controller per feature that extends ChangeNotifier, and
  views that rebuild with ListenableBuilder. No setState for app data.
- Two features: house and list. Every AppAmbit call lives in lib/core/appambit/.
- Packages: appambit_sdk_flutter, flutter_dotenv, shared_preferences, uuid. Nothing else.

HOUSE BY CODE (no login)
- Each phone gets a member id the first time it opens; that is how it's identified.
- Welcome: "Create a house" or "Join with a code".
- Create: your nickname, then "Your house is ready" with the 6-letter code big and Copy code.
- Join: code (capitals, letters only) + nickname. Wrong code:
  "No house with that code. Check the 6 letters with whoever created it."
- Both go through the join_house cloud function. The phone remembers its house.
- Start AppAmbit with the iOS or Android key from .env.

THE SHARED LIST
- Add an item (name + optional quantity), tap to check it off, swipe left to delete.
- "Clear checked (n)" removes everything already bought.
- Unchecked first, newest first. Each item shows a small magnet in the color of who added it.
- Everyone in the house sees the same list: it reloads when the app opens, when it comes back
  to the front, and on pull to refresh. Dates come from the database, not the phone.
- Changes show at once; if they can't be saved, they're undone.

ONLINE ONLY
- No internet: a "No connection" banner with Retry. Nothing is saved for later.
- Watch out: the AppAmbit Android SDK crashes on null SQL params. Write NULL in the SQL instead.

ANALYTICS
- house_created, house_joined, item_added, item_checked, item_deleted, checked_cleared.
  No nicknames or item names in the events.

Tests for the controllers, the item rules and the main screens, with fake repositories.
flutter analyze clean. End with a table "What the agent did": AppAmbit | ShopList app.
```

---

## 3. "I'm at the store"

```text
Now the reason ShopList exists: telling the house you're at the store.

PUSH
- Add appambit_sdk_push_notifications and start it right after the core SDK. On Android it
  uses Firebase: apply the google-services plugin only when android/app/google-services.json
  exists, so the app still builds without it. On iOS add the aps-environment entitlement and
  the remote-notification background mode.
- Each phone calls join_house again on every start, so start_shopping always has its current
  AppAmbit consumer id.
- Ask for notifications once, politely, on the list: "Turn on notifications to know when
  someone is at the store." with Not now / Turn on. Never ask again.
- A ShopList notification that arrives with the app open reloads the list. Tapping one opens it.

THE BUTTON
- Big denim "I'm at the store" button when nobody is shopping. It calls start_shopping.
- Someone else shopping: a card "Ana is at the store · Add what you need now. Ana will see it."
- You shopping: a soft card "You're at the store · Leo and Sam got the alert." with Done.
- If someone got there first: "Ana is already at the store."
- A trip older than 3 hours counts as finished.

NEW WHILE SHOPPING
- Items added after the trip started get the denim "New" magnet on every phone. It pops in once.
- Done ends the trip and clears every New.

ANALYTICS
- shopping_started, shopping_refused, shopping_done, push_opened.

Tests for the New rules, the 3-hour rule, the trip and who got the alert. Then the real test
with both phones: the iPhone taps "I'm at the store", the Android phone gets the notification
and adds "milk", the iPhone pulls to refresh and sees "milk" with New. End with a table
"What the agent did": AppAmbit | ShopList app.
```
