# ForeverDB quest source import

Run **Actions → Import WoW Forever quests and zones → Run workflow** on `main`.
The workflow uses the existing `FOREVERDB_API_KEY` repository secret.

- It downloads **all paginated quest index and zone records**, preserving the original JSON and response metadata.
- It then downloads up to `details_limit` individual quest details (default 700), including chains, prerequisites, starter and finisher locations, where provided.
- A checkpoint cache allows later runs to continue without repeating downloaded detail requests. The run also publishes `foreverdb-quest-source` as a downloadable artifact.
- GitHub Actions has a 55-minute job limit and ForeverDB's free account quota is 5,000 requests/day and 30/minute. If a run hits quota or time limits, lower `details_limit` and rerun after the limit resets.
- The import **does not automatically trust Classic-only locations**. Data needs Forever provenance checks before it can drive navigation.
- The importer does **not** yet build Lua guide steps or fill missing objective waypoints. The source API documents starter/finisher locations and chains, not every objective location.

Source: [ForeverDB API documentation](https://foreverdb.net/developers). **Data from [ForeverDB.net](https://foreverdb.net).** Follow its credit and redistribution rules. Never distribute the API key in an addon.
