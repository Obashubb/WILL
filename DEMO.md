# Demo + manual test script

A focused 5-7 minute walkthrough that exercises every feature in the build. Steps marked **(seed)** use the **Profile → Demo data** sheet to shortcut into a populated state. Run on a fresh install (or after **Sign out** → confirm) so the auth flow starts clean.

---

## 0. Fresh start

- Uninstall and reinstall, or sign out from a previous run.
- Launch — you should land on **Welcome**.

---

## 1. Auth flow (≈ 90 s)

Pick one path per demo run; the other two paths are quick to show on a separate device.

**a. Sign in (returning user)**
1. Welcome → **Sign in**.
2. Wrong password once → expect "Email or password is incorrect."
3. Right password → expect **Device Setup** screen.

**b. Sign up (new user)**
1. Welcome → **Create account**.
2. Try a 5-character password → expect "Password is too weak…"
3. Use ≥ 8 characters → expect **Device Setup**.

**c. Guest**
1. Welcome → **Continue as guest**.
2. Empty name submit → expect "Please enter your name."
3. Enter "Ada" → expect **Device Setup**.

**Verify:** the chevron back arrow is platform-native (Material on Android, Cupertino on iOS).

---

## 2. Device setup (≈ 30 s)

1. Tap **Pair device**.
2. Animated rings + Bluetooth icon pulse during scan + connect.
3. After ≈ 1.3 s the screen advances to **Dashboard**.

**Alt path:** tap **I'll set this up later** → Dashboard shows the **No band paired** banner with a **Pair** button inline. Tap it → flow completes; banner disappears.

---

## 3. Dashboard live readings (≈ 30 s)

- Connection pill **Connected** (green dot) at the top.
- Greeting headline pulled from your name.
- 2×2 metric grid: Heart rate, Oxygen, Temperature, Activity.
- Values lerp smoothly every 2 seconds — not snapping.

---

## 4. Seeded data **(seed)** (≈ 30 s)

1. Tap **Profile** tab → tap **Demo data**.
2. Tap **6 hours of history** → "Done. history applied."
3. Tap **Sample medications** → three meds saved + reminders scheduled.
4. Tap **Today's water** → five hydration entries populated.
5. Close the sheet.

---

## 5. History tab (≈ 30 s)

1. **History** tab.
2. Chart populated with 6 hours of data.
3. Tap **Heart rate / Oxygen / Temperature / Activity** chips.
4. Notice short abnormal patches mid-day (intentional — they came from the seeded data).

---

## 6. Care tab (≈ 30 s)

1. **Care** tab.
2. Hydration ring shows ≈ 1850/2500 ml (animates on first paint).
3. Tap **+250 ml** → ring fills further, count updates.
4. Three medication rows visible. Tap an unticked dose chip on **Hydroxyurea** → chip turns green, **SnackBar** confirms ("Hydroxyurea marked taken.").
5. Tap the trash icon on **Paludrine** → row removed, reminders cancelled.

---

## 7. Insights pipeline **(seed)** (≈ 60 s)

1. Go to **Profile → Demo data** again.
2. Pick the **Stress** chip.
3. Close the sheet, jump to **Dashboard** — values shift: HR climbs into the 100s, motion stays low.
4. Wait ≈ 30 s for the inference window to fill.
5. **Insights** tab → status hero says **"Looking stressed"** with the narrative + recommendations. Confidence bar animates to its level.
6. Within a few seconds the band buzzes (`WearableCommand.vibrate` in logs) and a system notification arrives on the **Health alerts** channel.

Repeat with other scenarios to show every label:
- **Dehydration** → "Hydration check"
- **Low oxygen** → "Low oxygen"
- **Crisis** → all four trees agree quickly, alert fires fast
- **Normal** → status returns to "All clear"

> The alert cooldown is 5 minutes per label — to re-fire for a demo, switch to another label and back.

---

## 8. Sync (≈ 20 s)

1. **Profile** tab.
2. **Sync** row: signed-in user shows "Synced just now" or "X min ago". Guest shows "Local only".
3. Tap the row → forces a flush.
4. Verify in [Firebase Console → Firestore](https://console.firebase.google.com/project/will-wristband/firestore) → `users/{uid}/readings/{hourId}` exists with a `samples` array.

---

## 9. Sign out (≈ 20 s)

1. **Profile** tab → **Sign out**.
2. Lands back on **Welcome**.
3. Sign in again → expect the dashboard with **fresh** state (history, hydration, meds, notifications all cleared).

---

## What this covers

| Feature | Step |
|---|---|
| Sign in / sign up / guest | 1 |
| Form validation + readable errors | 1 |
| Native back chevron | 1 |
| Device pairing flow + skip path | 2 |
| Live readings + animated values | 3 |
| Local cache + history chart + multi-metric | 5 |
| Hydration tracking + animated ring + quick-add | 6 |
| Medication CRUD + scheduled reminders + dose logging | 6 |
| ML inference pipeline (every label) | 7 |
| Band vibrate on concerning insight | 7 |
| Local notification alert | 7 |
| 5-minute alert cooldown | 7 |
| Batched Firestore sync + guest skip | 8 |
| Sign-out clears local state | 9 |

If any of those misbehaves, that's the regression to flag.

---

## Quick keyboard recipes (during defense)

- **Hot-reset to fresh state:** Profile → Demo data → **Reset all demo data**, then sign out.
- **Demonstrate every Insights label in one minute:** open Demo data → tap scenario chips in sequence with ~15 s between each, jumping to Insights to show the swap.
- **Show offline-safe sync:** turn off Wi-Fi/cellular on the device — the dashboard keeps updating, the Sync row flips to "Offline". Turn it back on → next minute's flush drains the backlog.
