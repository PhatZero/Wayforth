# WayForth Forever 1.0b13

## Profession tracker improvements

- **Orange-only leveling:** Only orange recipes are considered for planned skill gains. Yellow recipes are excluded because they can fail to grant skill.
- **Live materials:** Refresh reagent counts while the profession guide is visible.
- **Remember learned recipes:** Capture known orange recipes when the profession window is opened, with per-character cache persistence across reloads.
- **Clearer skill tracking:** Show skill gains separately from successful craft counts.
- **Safer skill targets:** Avoid generating work for completed skill bands.
- **Better guidance:** Explain when a new orange recipe must be learned or a profession scan is needed.
- **Regression checks:** Added tests covering recipe filtering, caching, inventory updates and tracker text.

## Known limitations

- The complete offline 1–max profession recipe database and consolidated shopping lists are **not included**.
- Successful craft-event tracking and in-game end-to-end validation remain outstanding.
- A previously saved recipe may need rescanning after its skill color changes.

The complete profession overhaul remains tracked in issue #28.
