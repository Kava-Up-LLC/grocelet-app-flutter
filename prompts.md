# The prompts behind ShopList

ShopList is one grocery list for everyone in a house. When someone gets to the store they tap
**"I'm at the store"**, everyone else gets a notification, and anything they add shows up with a **"New"** badge.

> *As someone who lives with other people, I want one shared grocery list that tells everyone when I'm at the
> store, so I come home with everything we need.*

The app is built with **three prompts** sent to a coding agent (Claude Code) with the **AppAmbit MCP** connected.

| Step | Where | What it builds |
|---|---|---|
| 0 | By hand | The AppAmbit apps, their keys and the push credentials |
| 1 | Agent + AppAmbit MCP | The database and the cloud function that sends the "at the store" alert |
| 2 | Agent, Flutter | The house and the shared list on two phones |
| 3 | Agent, Flutter | "I'm at the store", the notification and the "New" badge |

---

## 0. By hand

1. AppAmbit dashboard: create **ShopList - iOS** and **ShopList - Android** (stack Flutter).
2. Put both App Keys in `.env` (template `.env.example`). Never in the chat.
3. Upload the push credentials to each app (App Info → Push Notifications Credentials): FCM service-account JSON
   for Android, APNs `.p8` key for iOS. App id on both platforms: `com.kavaup.shoplist`.

---

## 1. The backend in AppAmbit

```text
Use the AppAmbit MCP to set up the backend for ShopList, a shared grocery list for a house.
Call get-started-tool first and work on the apps "ShopList - iOS" and "ShopList - Android".

The idea: people who live together join the same house with a 6-letter code and share one
list. When someone taps "I'm at the store", everyone else in the house gets a notification,
and anything added while they shop is marked as new.

DATABASE
- Create ShopListDb and link BOTH apps to it, so an iPhone and an Android phone share a house.
- houses: id, code (6 letters, unique), shopper_id, shopping_since, created_at
- members: id, house_id, nickname, platform, created_at
- items: id, house_id, name, quantity (optional text), checked, added_by, created_at
- Ids are uuids. Dates always come from the database clock, never from the phone.

CLOUD CODE: start_shopping
- In: house_id and member_id.
- Only one shopper per house at a time. Claim the trip in a single update; a trip older than
  3 hours counts as finished. If someone else is shopping, return their nickname and send nothing.
- Send a push to every OTHER member of the house:
  "Ana is at the store. Add what you need."  (data: open = list)
- Deploy it to both apps with an HTTP trigger, with unit tests for the rules above.
- Test it for real with a test house and two members, then delete the test data.

End with a table "What the agent did": AppAmbit | ShopList app.
```

---

## 2. The app: one list for the whole house

```text
Build the ShopList Flutter app for iPhone and Android on AppAmbit. Follow AGENTS.md and match
DESIGN.md exactly. App id com.kavaup.shoplist, display name ShopList. Screens in English.

KEEP IT SIMPLE
- No state-management packages: one controller per feature that extends ChangeNotifier, and
  views that rebuild with ListenableBuilder. No setState for app data.
- Two features (house, list). All AppAmbit calls in one core folder.

HOUSE BY CODE (no login)
- Welcome: "Create a house" or "Join with a code".
- Create: your nickname, then the 6-letter code big with a Copy button.
- Join: code + nickname. Wrong code: "No house with that code."
- The phone remembers its house. Start AppAmbit with the key from .env.

THE SHARED LIST
- Add an item (name + optional quantity), check it off, swipe to delete.
- "Clear checked" removes everything already bought.
- Everyone in the house sees the same list: it reloads when the app opens, when it comes back
  to the front, and on pull to refresh.

ONLINE ONLY
- No internet: a "No connection" banner with Retry. Nothing is saved for later.

ANALYTICS
- house_created, house_joined, item_added, item_checked, item_deleted, checked_cleared.

Add tests for the controllers, run it on my iPhone and my Android phone, and check that an item
added on one shows up on the other. End with a table "What the agent did": AppAmbit | ShopList app.
```

---

## 3. "I'm at the store"

```text
Now the reason ShopList exists: telling the house you're at the store.

PUSH
- Add AppAmbit push notifications on iPhone and Android. Each phone sets its member id as the
  AppAmbit user id, so the start_shopping function can reach it.
- Ask for notification permission once, the first time the list opens.
- With the app open, a ShopList notification reloads the list. Tapping one opens the list.

THE BUTTON
- Big "I'm at the store" button when nobody is shopping. It calls start_shopping.
- Someone else shopping: "Ana is shopping". You shopping: "You're at the store" and a Done button.
- If someone got there first: "Ana is already at the store."

NEW WHILE SHOPPING
- Items added after the trip started get a "New" badge on every phone.
- Done ends the trip and clears every badge.

ANALYTICS
- shopping_started, shopping_refused, shopping_done, push_opened.

Add tests for the "New" rules and the trip. Then the real test with both phones: the iPhone taps
"I'm at the store", the Android phone gets the notification and adds "milk", and the iPhone
pulls to refresh and sees "milk" with "New". End with a table "What the agent did":
AppAmbit | ShopList app.
```
