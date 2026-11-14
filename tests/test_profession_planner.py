"""Regression guards for the profession planner's known failure modes."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "shared/core/ProfessionGuides.lua"
TRACKER = ROOT / "shared/tracker/Tracker.lua"
BOOTSTRAP = ROOT / "shared/core/Bootstrap.lua"

class ProfessionPlannerRegressionTests(unittest.TestCase):
    def test_recipe_snapshot_persists_per_character(self):
        source = ENGINE.read_text()
        self.assertIn("ns.char.professionRecipeCache[id]=candidates", source)
        self.assertIn("ns.char.professionRecipeCache[id]", source)
        self.assertIn("function Profession:Initialize()", source)
        self.assertIn("recipeSnapshots[id]=candidates", source)

    def test_live_inventory_and_recipe_capture(self):
        source = ENGINE.read_text()
        tracker = TRACKER.read_text()
        self.assertIn("GetItemCount", source)
        self.assertIn("CaptureOpenProfession", tracker)
        self.assertIn("Tracker:RenderProfession()", tracker)
        self.assertIn("professionElapsed>=1.5", tracker)

    def test_no_false_completed_craft_claims(self):
        tracker = TRACKER.read_text()
        self.assertIn("Skill gains ", tracker)
        self.assertNotIn('text="Crafted "..craft.completed', tracker)

    def test_profession_events_are_dispatched(self):
        source = BOOTSTRAP.read_text()
        for event in ("TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE", "SKILL_LINES_CHANGED"):
            self.assertIn(event, source)

    def test_offline_full_route_not_misrepresented(self):
        tracker = TRACKER.read_text()
        self.assertIn("Full offline shopping lists are not available yet", tracker)
        self.assertIn("Current learned recipe only", tracker)

if __name__ == "__main__":
    unittest.main()
