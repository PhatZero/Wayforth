"""Keep Classic fallback data in the correct quest phase and Forever map frame."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from import_forever_locations import Catalog


class QuestSourceTests(unittest.TestCase):
    def catalog(self):
        catalog = Catalog.__new__(Catalog)
        catalog.data = {"Quest": {"783": {"1": "A Threat Within", "2": {"1": {"1": 823}},
                                          "3": {"1": {"1": 197}}}}}
        catalog.maps = {12: 1429, 215: 1412}
        catalog.names = {1429: "Elwynn Forest", 1412: "Mulgore"}
        catalog.transforms = {
            12: dict(scale_x=1, offset_x=0, scale_y=1, offset_y=0),
            215: dict(scale_x=.8348002068275978, offset_x=7.007453108736848,
                      scale_y=.8349418225477033, offset_y=13.15387327724201),
        }
        return catalog

    def fact(self, point="start", entity_id=823, name="A Threat Within"):
        return dict(questId=783, flavor="classic", questName=name, mapper={"objectives": {
            "12": {"zone": "Elwynn Forest", "levels": [[dict(
                type=1, point=point, id=entity_id, name="Quest NPC", coord=[48.2, 42.8])]]}}})

    def test_classic_fallback_keeps_forever_turnin(self):
        record = {"turnin": [{"mapId": 1429, "x": 48.92, "y": 41.61}]}
        self.catalog().supplement(record, self.fact())
        self.assertEqual(record["pickup"][0]["id"], 823)
        self.assertEqual(record["pickup"][0]["source"], "Wowhead Classic")
        self.assertEqual(record["turnin"][0]["x"], 48.92)

    def test_mismatched_quest_and_endpoint_are_rejected(self):
        for fact in (self.fact(name="A Different Quest"), self.fact(entity_id=197)):
            record = {}
            self.catalog().supplement(record, fact)
            self.assertNotIn("pickup", record)

    def test_changed_map_is_projected_once(self):
        catalog = self.catalog()
        self.assertEqual(catalog.classic_point(215, [43.9, 76.7]), [43.66, 77.19])
        self.assertEqual(catalog.classic_point(12, [48.2, 42.8]), [48.2, 42.8])
        self.assertIsNone(catalog.classic_point(999999, [50, 50]))

    def test_enemy_loot_source_is_available_to_quest_faction(self):
        catalog = self.catalog()
        catalog.data["Npc"] = {"12676": {"1": "Sharptalon", "13": "A",
                                         "7": {"12": {"1": {"1": 48.2, "2": 42.8}}}}}
        catalog.data["Item"] = {"16305": {"2": {"1": 12676}}}
        points = catalog.item(16305)
        self.assertEqual(points[0]["kind"], "loot")
        self.assertNotIn("faction", points[0])

    def test_known_entity_can_use_another_quests_recorded_position(self):
        catalog = self.catalog()
        catalog.extra_entities = {}
        catalog.data["Npc"] = {"197": {"1": "Marshal McBride"}}
        catalog.index_maps([self.fact(point="end", entity_id=197)])
        points = catalog.entity("Npc", 197)
        self.assertEqual(points[0]["id"], 197)
        self.assertEqual(points[0]["mapId"], 1429)
        self.assertEqual(points[0]["source"], "Wowhead Classic")

    def test_forever_fact_uses_native_coordinates(self):
        catalog = self.catalog()
        fact = self.fact()
        fact["flavor"] = "forever"
        fact["mapper"]["objectives"] = {"215": {
            "zone": "Mulgore", "levels": [[dict(type=1, point="start", id=823,
                                                name="Quest NPC", coord=[43.9, 76.7])]]}}
        record = {}
        catalog.supplement(record, fact)
        self.assertEqual(record["pickup"][0]["x"], 43.9)
        self.assertEqual(record["pickup"][0]["y"], 76.7)


if __name__ == "__main__":
    unittest.main()
