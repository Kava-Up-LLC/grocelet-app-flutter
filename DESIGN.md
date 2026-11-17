# DESIGN.md — Grocelet · "Fridge Door"

The look of Grocelet. Match it exactly: colors, type, spacing, components and screens.
Reference mockups (9 screens): https://claude.ai/artifact/SnmYxYmw2F8495Y6yzhRQJ — row **A · Fridge Door**.

## 1. The idea

Grocelet is the list that used to live on the fridge door. The screen is the **fridge** (pale enamel green), the list
is a **notepad** stuck on it (white paper, ruled lines, a lavender glue strip on top), and the people in the house are
**magnets** (round color dots). The trip to the store has its own color: it paints the "I'm at the store"
button, the "You're at the store" card and the **New** magnet. The trip color is **denim**: a calm, muted blue.
When denim shows up, someone is at the store.

Three rules:
1. **Denim means "store trip"** and nothing else. Never use it for normal buttons, links or errors.
   Strong color only on small things (buttons, the New magnet). **Big blocks (cards, banners) use soft fills with
   dark text**, never a saturated fill.
2. **Nothing is black.** Text is deep pine, normal buttons are pine green.
3. **Things are stuck on, not floating.** Cards, the notepad, fields and buttons use a hard 2–4 px drop **without
   blur**, like paper and magnets on a door. No soft gray shadows, no gradients.

## 2. Colors

| Token | Hex | Use | Contrast |
|---|---|---|---|
| `fridge` | `#E8EFEC` | Screen background (Scaffold) | — |
| `paper` | `#FFFFFF` | Notepad, cards, fields, code chip | — |
| `ink` | `#1F3A32` | All main text, titles | 11.9:1 on paper |
| `inkMuted` | `#5A6B64` | Secondary text, quantities, checked items | 5.6:1 on paper · 4.7:1 on fridge |
| `rule` | `#DCE6E2` | Notepad ruled lines (1 px) | — |
| `edge` | `#C9D6D1` | The hard drop under paper things | — |
| `pine` | `#22614A` | Primary buttons, checkbox, secondary button border/text, links | white on pine 7.2:1 |
| `denim` | `#3E5C86` | Store trip only, small things: store button, Done, New magnet, shopper avatar | white on denim 7.0:1 |
| `denimDeep` | `#2C4466` | Hard drop under denim buttons | — |
| `denimSoft` | `#DFE7F1` | Fill of the "You're at the store" card | ink on it 9.6:1 |
| `denimEdge` | `#C3D0DF` | Hard drop under the denimSoft card | — |
| `inkOnSoft` | `#4E5F6E` | Secondary text on denimSoft | 5.2:1 |
| `glue` | `#DCE4EE` | Notepad top strip (14 px) | — |
| `butter` | `#F6E6BC` | "No connection" banner background (ink text on it) | ink on butter 9.6:1 |
| `onColor` | `#FFFFFF` | Text on pine and denim | — |

**Member magnets** (who added an item). Pick by `member_id.hashCode % 4`; no extra data:

| Token | Hex |
|---|---|
| `magnetPlum` | `#9466B5` |
| `magnetTeal` | `#15938A` |
| `magnetMustard` | `#E0A100` |
| `magnetSlate` | `#7A8B99` |

There is **no red** anywhere in the app, and no loud fills on big areas. Errors are written in `ink` next to a small
denim dot (see Join).

## 3. Type

One family: **Bricolage Grotesque**, bundled in `assets/fonts/` (static instances made from the Google Fonts
variable font, OFL license included). Regular/Medium/SemiBold/Bold at optical size 24, ExtraBold at optical size 48
for titles.

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: BricolageGrotesque
      fonts:
        - asset: assets/fonts/BricolageGrotesque-Regular.ttf
          weight: 400
        - asset: assets/fonts/BricolageGrotesque-Medium.ttf
          weight: 500
        - asset: assets/fonts/BricolageGrotesque-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/BricolageGrotesque-Bold.ttf
          weight: 700
        - asset: assets/fonts/BricolageGrotesque-ExtraBold.ttf
          weight: 800
```

| Style | Size / line height | Weight | Letter spacing | Use |
|---|---|---|---|---|
| `hero` | 56 / 0.95 | 800 | −1.7 (−0.03 em) | "Grocelet" on Welcome only |
| `title` | 30 / 1.1 | 800 | −0.6 (−0.02 em) | Screen titles, "Grocelet" header |
| `code` | 44 / 1.0 | 800 | +9.7 (0.22 em) | The house code on "Your house is ready" |
| `lead` | 20 / 1.35 | 400 | 0 | Welcome subtitle |
| `item` | 18 / 1.3 | 500 | 0 | Item name (700 when New) |
| `cardTitle` | 17–18 / 1.25 | 700–800 | 0 | Shopping card title ("Ana is at the store") |
| `body` | 17 / 1.45 | 400 | 0 | Paragraphs |
| `button` | 17 / 1.0 | 700 | 0 | Buttons (store button: 20 / 800) |
| `label` | 14 / 1.2 | 600 | 0 | Field labels |
| `meta` | 14–15 / 1.3 | 400–500 | 0 | Quantity, card subtitles |
| `chip` | 14 / 1.0 | 600 | +2.5 (0.18 em) | House code chip in the header |
| `magnet` | 13 / 1.0 | 800 | 0 | The "New" magnet |

Sentence case everywhere. **No all-caps text**, no italics.

## 4. Spacing, radius, drops

- **Spacing scale:** 4 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 24 · 28. Screen padding: 20 left/right, 28 bottom
  (plus safe areas). Vertical gap between header blocks: 18.
- **Radius:** 10 (code chip, small buttons) · 12 (Done, banner buttons, inline notes) · 14 (fields, primary
  buttons, banner) · 16 (shopping card) · 18 (notepad, store button) · circle (checkbox, magnets, avatars).
- **Drops (hard, no blur):** paper things `Offset(0, 2)` `edge` (fields, chip) or `Offset(0, 3)` `edge` (notepad,
  code card). Denim buttons `Offset(0, 3)`–`(0, 4)` `denimDeep`; the denimSoft card `Offset(0, 2)` `denimEdge`. Magnets also get an inner bottom shade
  (black 18–20 % at 3 px), which makes them look round. In Flutter: `BoxShadow(color: edge, offset: Offset(0, 3),
  blurRadius: 0)`.
- **Touch targets:** at least 48 px. Primary buttons 56 px tall, store button 64 px.

## 5. Components

| Component | Spec |
|---|---|
| **Notepad** | `paper`, radius 18, clip, drop 3. A 14 px `glue` strip on top. Rows separated by 1 px `rule`. Fills the free height; scrolls inside; pull to refresh on it. |
| **Item row** | Min height 56, padding 0 18, gap 14. Left → right: checkbox · name (`item`, flexible, 1 line, ellipsis) · quantity (`meta`, `inkMuted`) · member magnet **or** New magnet. Swipe left to delete (background `pine`, white "Delete"). |
| **Checkbox** | 26 px circle. Open: 2 px `pine` ring. Checked: filled `pine` with a white check (2.2 px stroke, round caps). Checked rows: name `inkMuted` + strikethrough. Checked items go to the bottom. |
| **Member magnet** | 10 px circle in the member's magnet color, right edge of the row. Decorative (`ExcludeSemantics`). |
| **New magnet** | Pill, `denim` fill, white `magnet` text "New", padding 5×11, rotated **−4°**, inner bottom shade + small drop. Replaces the member magnet on that row; the item name goes to 700. Appears with one short pop (scale 0.6 → 1.0, 220 ms, easeOutBack) the first time it shows; no animation if reduce motion is on. |
| **Shopping card · someone else** | `paper`, radius 16, drop 2, padding 14×16. 36 px `denim` avatar with the shopper's initial (800, white) · title "Ana is at the store" (`cardTitle`) · subtitle "Add what you need now. Ana will see it." (we don't know anyone's pronouns) (`meta`, `inkMuted`). |
| **Shopping card · me** | `denimSoft` fill, radius 16, drop 2 `denimEdge`, padding 12/12/12/16. Title "You're at the store" (18/800 `ink`) · subtitle "Leo and Sam got the alert." (`inkOnSoft`) · **Done** button: `denim` fill, white 16/700, 48 px, radius 12. |
| **Store button** | Only when nobody is shopping. Full width, 64 px, radius 18, `denim`, drop 4 `denimDeep`, "I'm at the store" 20/800 white. Sits under the notepad. |
| **Add bar** | Row, gap 8, under the notepad: item field (flexible) · quantity field (64 px wide) · **Add** primary button (56 px, padding 0 22). Fields: `paper`, radius 14, drop 2, no border, text 17/500. Placeholders "Add an item" and "Qty" in `inkMuted`. |
| **Code chip** | Header right. `paper`, radius 10, drop 2, padding 8×12, `chip` style. Tap copies the code (snackbar "Code copied"). |
| **Primary button** | `pine`, white `button` text, 56 px, radius 14, full width on forms. |
| **Secondary button** | Transparent, 2 px `pine` border, `pine` text, same size. |
| **Text button** | `pine` text 15–16/600, underline for "Clear checked (n)". |
| **Text field** | Label above (`label`, gap 6), then field: 56 px, `paper`, radius 14, drop 2, padding 0 16, text 18/500. Focus/error: 2 px ring (`pine` focus, `denim` + note for error). |
| **Inline note (error)** | `paper`, radius 12, padding 12×14, 10 px `denim` dot + text 15/400 `ink`. |
| **No connection banner** | Under the header. `butter`, radius 14, padding 10/10/10/16. Text "No connection. Changes can't be saved right now." 16/600 `ink` · **Retry** button `ink` fill, white 15/700, 44 px, radius 10. Announced as a live region. |
| **Empty list** | Inside the notepad, centered: "Nothing on the list yet." (`body`) and "Add the first item below." (`meta`, `inkMuted`). |

## 6. Screens

| Screen | Layout (top → bottom) |
|---|---|
| **Welcome** | Four member magnets in a row (denim, plum, mustard, teal; 22 px) · "Grocelet" `hero` · "The whole house's grocery list. One list, everyone's phone." `lead`, max width 290. Bottom: **Create a house** (primary) and **Join with a code** (secondary), gap 12. Content starts ~90 px below the top padding. |
| **Create house** | "Create a house" `title` · field "Your nickname" · **Create** (primary, bottom). |
| **Your house is ready** | `title` · code card (notepad style with glue strip): "House code" `meta` · code `code` style · **Copy code** (secondary, 48 px) · paragraph "Share this code with the people you live with. They join with it and their nickname. No accounts." · **Continue** (primary, bottom). |
| **Join a house** | **Back** text button · "Join a house" `title` · field "House code" (auto uppercase, 6 letters, letter spacing 0.2 em, 700) · field "Your nickname" · **Join** (primary, bottom). Wrong code: denim ring on the code field + inline note "No house with that code. Check the 6 letters with whoever created it." |
| **List · nobody shopping** | Header ("Grocelet" `title` + code chip) · notepad · **I'm at the store** store button. |
| **List · someone else shopping** | Header · shopping card (someone else) · notepad (New magnets on new items) · add bar. No store button. |
| **List · I'm shopping** | Header · shopping card (me, with Done) · notepad with New magnets · add bar. |
| **List · no connection** | Same as the state underneath, plus the banner under the header. |

"Clear checked (n)" sits at the bottom inside the notepad, left aligned, only when n > 0.
The add bar shows in every list state; the mockup of "I'm shopping" hides it only to give the aisle shot room.

## 7. Copy

| Where | Text |
|---|---|
| Welcome | "Grocelet" · "The whole house's grocery list. One list, everyone's phone." · "Create a house" · "Join with a code" |
| Create | "Create a house" · "Your nickname" · "Create" |
| Code | "Your house is ready" · "House code" · "Copy code" · "Code copied" · "Continue" |
| Join | "Join a house" · "House code" · "Your nickname" · "Join" · "No house with that code. Check the 6 letters with whoever created it." |
| List | "Add an item" · "Qty" · "Add" · "Clear checked (n)" · "Nothing on the list yet." · "Add the first item below." · "Delete" |
| Trip | "I'm at the store" · "Ana is at the store" · "Add what you need now. Ana will see it." (we don't know anyone's pronouns) · "You're at the store" · "Leo and Sam got the alert." (1 person: "Leo got the alert."; 3+: "Leo and 2 others got the alert."; nobody: "Nobody else is in the house yet.") · "Done" · "Ana is already at the store." · "New" |
| Push | Title "Grocelet" · body "Ana is at the store. Add what you need." |
| Offline | "No connection. Changes can't be saved right now." · "Retry" |
| Permission ask (before the OS prompt, one line on the list) | "Turn on notifications to know when someone is at the store." |

Never "server" or "backend" in the UI.

## 8. Motion

Only two moments move: the **New magnet pop** (above) and the **shopping card** sliding down 12 px + fade in
(200 ms) when a trip starts. Everything else is instant. Respect `MediaQuery.disableAnimations`.

## 9. Flutter mapping

- `lib/core/theme/app_colors.dart`: the tokens of §2 as `static const Color`.
- `lib/core/theme/app_text.dart`: the styles of §3 as `static const TextStyle` (family `BricolageGrotesque`, color `ink`).
- `lib/core/theme/app_theme.dart`: `ThemeData(useMaterial3: true, scaffoldBackgroundColor: fridge, fontFamily:
  'BricolageGrotesque', colorScheme: ColorScheme.light(primary: pine, onPrimary: onColor, secondary: denim,
  onSecondary: onColor, surface: paper, onSurface: ink))`, elevation 0 everywhere, no splash tint on the notepad rows.
- Hard drops: a small `paperDrop` / `denimDrop` `BoxShadow` list in `app_colors.dart` (blur 0).
- Status bar: dark icons on `fridge`.
- Shared widgets in `lib/core/widgets/`: `Notepad`, `PrimaryButton`, `SecondaryButton`, `AppTextField`,
  `NoConnectionBanner`, `InlineNote`, `Magnet`. Feature widgets (`ItemTile`, `ShoppingCard`, `StoreButton`,
  `AddItemBar`, `NewMagnet`) live in `features/list/widgets/`.

## 10. Don't

- Black or near-black fills (`#000`, `#111`, `#1D2B26`…). Text is `ink`, buttons are `pine`.
- Red, anywhere. Denim for anything that isn't the store trip. Saturated fills on big areas (cards, banners).
- Blurred shadows, gradients, glass, Material elevation tints.
- All caps, italics, emoji, icons inside buttons.
- Another font, or `google_fonts` (fonts are bundled).
