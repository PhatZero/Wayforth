# Side-quest cleanup on zone changes

The optional **Offer side-quest cleanup on new area** setting is off by default. When enabled, WayForth checks the quest log after a zone transition and asks before taking action. The prompt names up to four quests and shows the remaining count.

WayForth only offers quests the client reports as abandonable. It excludes entries marked as campaign, story, important, legendary, task, bounty, or recurring, as well as quest-line/campaign entries and the client's Important Quest tag. The list is checked again when the player confirms.

Abandoning a quest loses its current quest progress. The feature does not act in combat, inside an instance, when required client APIs are missing, or without confirmation. This setting changes quest-cleanup behavior per character.
