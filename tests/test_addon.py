import sys
import unittest
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from build import TOC, source_path, BRAND_PATH, ART_PATH, brand_texture, illustrated_art, build, manifest


class AddonFoundationTests(unittest.TestCase):
    def test_manifest_and_file_order(self):
        scripts = manifest()
        self.assertEqual(scripts[0], "Core/Namespace.lua")
        self.assertEqual(scripts[-1], "Core/Bootstrap.lua")
        self.assertLess(scripts.index("Core/Database.lua"), scripts.index("UI/Window.lua"))
        self.assertLess(scripts.index("Data/StarterGuide.lua"), scripts.index("Core/Guides.lua"))

    def test_offline_requirements(self):
        sources = "\n".join(source_path(item).read_text() for item in manifest())
        self.assertNotIn("SendAddonMessage", sources)
        self.assertNotIn("https://", sources)
        self.assertNotIn("SlashCmdList", sources)
        self.assertIn("WoWForeverCharDB", source_path("Core/Database.lua").read_text())
        self.assertIn("WoWForeverDB", source_path("Core/Database.lua").read_text())

    def test_rebrand_preserves_legacy_settings_globals(self):
        toc = TOC.read_text()
        self.assertIn("## Title: |cff24c9e0Way|r|cffffcd73Forth|r", toc)
        self.assertIn("## SavedVariables: WoWForeverDB", toc)
        self.assertIn("## SavedVariablesPerCharacter: WoWForeverCharDB", toc)
        self.assertIn("WayForth", source_path("UI/Minimap.lua").read_text())
        self.assertIn("WoWForever.lua", (ROOT / "README.md").read_text())

    def test_zephras_guide_is_packaged_after_starter(self):
        scripts = manifest()
        self.assertLess(scripts.index("Data/StarterGuide.lua"), scripts.index("Data/ZephrasIsle.lua"))
        self.assertLess(scripts.index("Data/ZephrasIsle.lua"), scripts.index("Core/Guides.lua"))
        self.assertLess(scripts.index("Data/ForeverQuestCatalog.lua"), scripts.index("Data/KalimdorAlliance.lua"))
        self.assertLess(scripts.index("Data/KalimdorAlliance.lua"), scripts.index("Core/Guides.lua"))
        self.assertIn("## Version: 1.0.0-beta", TOC.read_text())
        guide = source_path("Data/ZephrasIsle.lua").read_text()
        self.assertIn('id = "zephras-alliance"', guide)
        self.assertIn('id = "zephras-horde"', guide)
        for quest_id in (92460, 92461, 92462, 92474, 92597, 92598):
            self.assertIn(f"questId = {quest_id}", guide)
        for faction_quest in ("Alliance = 94369", "Horde = 93836", "Alliance = 93089", "Horde = 93090", "Alliance = 93461", "Horde = 92514"):
            self.assertIn(faction_quest, guide)
        self.assertIn("step.mapId = 2521", guide)
        engine = source_path("Core/Guides.lua").read_text()
        self.assertIn("IsQuestFlaggedCompleted", engine)
        self.assertIn("SetUserWaypoint", engine)
        self.assertIn("saved.currentStepId", engine)


    def test_tracker_and_navigation_modules(self):
        scripts = manifest()
        self.assertLess(scripts.index("Core/Guides.lua"), scripts.index("UI/Navigator.lua"))
        self.assertLess(scripts.index("UI/Navigator.lua"), scripts.index("UI/Tracker.lua"))
        self.assertLess(scripts.index("UI/Tracker.lua"), scripts.index("UI/Window.lua"))
        navigator = source_path("UI/Navigator.lua").read_text()
        for api in ("GetNextWaypoint", "GetPlayerMapPosition", "GetPlayerFacing", "SetRotation", "0.25"):
            self.assertIn(api, navigator)
        self.assertIn("if not self.target", navigator)
        tracker = source_path("UI/Tracker.lua").read_text()
        for action in ('"Previous"', '"Next Step"', '"Skip"', '"PIN"', '"Sync Guide Now"', '"Pause Guide"', "trackerVisible"):
            self.assertIn(action, tracker.replace("< Prev", "Prev").replace("Next >", "Next"))
        dashboard = source_path("UI/Modern.lua").read_text()
        self.assertIn('"SMART START"', dashboard)
        self.assertIn('"FROM BEGINNING"', dashboard)
        self.assertIn('"RESUME SAVED"', dashboard)
        self.assertTrue('UI:ShowTab("Dashboard")' in dashboard
                        or 'self:ShowTab("Dashboard")' in dashboard,
                        "Dashboard navigation must remain reachable")
        self.assertIn('UI.selectedGuideId', dashboard)
        self.assertIn('"Navigation"', dashboard)
        self.assertIn('"Favorites"', dashboard)
        self.assertNotIn("UIPanelButtonTemplate", source_path("UI/Theme.lua").read_text())
        database = source_path("Core/Database.lua").read_text()
        for key in ("trackerScale", "trackerLocked", "trackerX", "navX"):
            self.assertIn(key, database)
        events = source_path("Core/Bootstrap.lua").read_text()
        self.assertIn('invoke("Tracker", "Initialize")', events)
        self.assertIn('ns:Call("Navigator", "Refresh")', events)

    def test_illustrated_guide_library_navigation(self):
        modern = source_path("UI/Modern.lua").read_text()
        self.assertIn("function UI:LibraryCard(prefix, id, x, y, width)", modern)
        self.assertIn('self:Art(prefix.."art"', modern)
        self.assertIn('self:Hit(prefix.."open"', modern)
        self.assertIn('UI:ShowTab("Guide Details")', modern)
        self.assertIn('guides:ToggleFavorite(id)', modern)
        self.assertIn('guide.levelMax or 999) <= 15', modern)
        self.assertIn('local perPage=math.max(3,math.min(8', modern)
        self.assertIn('if self.guidePage>1 then', modern)
        self.assertIn('if self.guidePage<pages then', modern)
        # Don't create a third main window to browse guides.
        self.assertNotIn('CreateFrame("Frame", "WayForthGuideLibrary"', modern)
        self.assertIn('widget:SetLabel(str)', modern)

    def test_guide_details_preview_and_explicit_start(self):
        modern = source_path("UI/Modern.lua").read_text()
        section = modern.split('elseif tab == "Guide Details" then', 1)[1].split(
            'elseif tab == "Settings" then', 1)[0]
        # The existing guide engine remains authoritative for both preview
        # and eventual switching; selecting a card only updates UI state.
        self.assertIn('routing:Preview(selected.id, selectedMode)', section)
        self.assertIn('UI.detailMode=modeKey', section)
        self.assertIn('local modeKey=choice.key', section)
        self.assertIn('routing:Switch(selected.id,selectedMode)', section)
        self.assertEqual(section.count('routing:Switch('), 1)
        self.assertIn('if index then', section)
        self.assertIn('if ok then', section)
        self.assertIn('ns.Modules.Tracker:Show()', section)
        self.assertIn('UI:Hide()', section)
        for mode in ('recommended', 'beginning', 'resume'):
            self.assertIn('key="' + mode + '"', section)
        self.assertIn('guides:ToggleFavorite(selected.id)', section)
        self.assertIn('guides:Status(selected.id)', section)
        self.assertIn('self:Art("detailsArt"', section)
        self.assertIn('self:Surface("detailsBarBg"', section)
        self.assertIn('UI:ShowTab("Guide Library")', section)
        self.assertNotIn('CreateFrame(', section)

    def test_modern_dashboard_rendering_layers(self):
        modern = source_path("UI/Modern.lua").read_text()
        theme = source_path("UI/Theme.lua").read_text()
        tracker = source_path("UI/Tracker.lua").read_text()
        # WoW draws child Frames above parent FontStrings regardless of whether
        # those FontStrings were created later. Cards must use background textures.
        self.assertIn('widget = self.page:CreateTexture(nil, "BACKGROUND"', modern)
        self.assertNotIn('widget = CreateFrame("Frame", nil, self.page)', modern)
        self.assertIn('theme:Compass(header', modern)
        self.assertIn('theme:Compass(header', tracker)
        self.assertIn('self:Portrait("characterPortrait"', modern)
        self.assertIn('self:Hit("category"', modern)
        self.assertIn('self.brandCaption:SetText("Step "', tracker)
        self.assertIn('variant == "primary"', theme)

    def test_custom_button_consumers_do_not_use_native_font_string(self):
        # A recent button-label refactor made the dashboard fail at
        # initialization because its sidebar queried GetFontString().
        theme = source_path("UI/Theme.lua").read_text()
        modern = source_path("UI/Modern.lua").read_text()
        tracker = source_path("UI/Tracker.lua").read_text()
        legacy = source_path("UI/Window.lua").read_text()
        self.assertIn("button.label = label", theme)
        self.assertIn("function button:SetLabel(value)", theme)
        self.assertIn("local font = button.label", modern)
        for source in (modern, tracker, legacy):
            self.assertNotIn("GetFontString()", source)
        self.assertIn("widget:SetLabel(str)", modern)
        self.assertNotIn("button:SetFontString(label)", theme)

    def test_official_wayforth_logo_is_reused_everywhere(self):
        art = brand_texture()
        self.assertGreater(len(art), 1000)
        self.assertEqual(art[2], 10)  # TGA RLE truecolor
        self.assertEqual(art[12:16], bytes([64, 0, 64, 0]))
        self.assertEqual(art[16], 32)  # RGBA transparency
        theme = source_path("UI/Theme.lua").read_text()
        minimap = source_path("UI/Minimap.lua").read_text()
        dashboard = source_path("UI/Modern.lua").read_text()
        tracker = source_path("UI/Tracker.lua").read_text()
        self.assertIn("WayForthCompass.tga", theme)
        self.assertIn("Theme.logoTexture", minimap)
        self.assertNotIn("MiniMap-TrackingBorder", minimap)
        self.assertIn("theme:Compass(header", dashboard)
        self.assertIn("theme:Compass(header", tracker)
        self.assertIn("self.brandTitle", tracker)

    def test_illustrated_art_and_surname_present(self):
        data = illustrated_art()
        self.assertEqual(data[2], 10)
        self.assertEqual(data[12:16], bytes([0, 2, 128, 0]))  # 512x128 atlas
        self.assertEqual(data[16], 32)
        modern = source_path("UI/Modern.lua").read_text()
        tracker = source_path("UI/Tracker.lua").read_text()
        theme = source_path("UI/Theme.lua").read_text()
        character = source_path("Core/Character.lua").read_text()
        self.assertIn("theme.artAtlas", modern)
        self.assertIn("theme.artAtlas", tracker)
        self.assertIn('theme:Gear(settings', modern)
        self.assertIn('theme:Gear(settings', tracker)
        self.assertIn("WayForthArtAtlas.tga", theme)
        self.assertIn("snap.displayName", modern)
        self.assertIn("UnitFullName", character)
        self.assertIn("UnitName", character)
        self.assertIn("GetNormalizedRealmName", character)
        self.assertIn("firstName", character)
        self.assertIn("lastName", character)
        self.assertIn("displayName", character)

    def test_packaging(self):
        package = build()
        with zipfile.ZipFile(package) as archive:
            files = archive.namelist()
            self.assertEqual(len(files), len(manifest()) + 3)
            self.assertEqual(files[0], "WayForth/WayForth.toc")
            self.assertIn(BRAND_PATH, files)
            self.assertEqual(archive.read(BRAND_PATH), brand_texture())
            self.assertIn(ART_PATH, files)
            self.assertEqual(archive.read(ART_PATH), illustrated_art())
            self.assertTrue(all(path.startswith("WayForth/") for path in files))
            self.assertFalse(any("README" in path or ".py" in path for path in files))


if __name__ == "__main__":
    unittest.main()
