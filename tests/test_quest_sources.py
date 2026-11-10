"""Keep Classic fallback data in the correct quest phase and Forever map frame."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from import_forever_locations import Catalog, quest_name


class QuestSourceTests(unittest.TestCase):
    def catalog(self):
        catalog = Catalog.__new__(Catalog)
        catalog.data = {"Quest": {"783": {"1": "A Threat Within", "2": {"1": {"1": 823}},
                                          "3": {"1": {"1": 197}}}}}
        catalog.maps = {12: 1429, 215: 1412}
        catalog.names = {1429: "Elwynn Forest", 1412: "Mulgore"}
        catalog.reports, catalog.att, catalog.extra_entities, catalog.npc_names = {}, {}, {}, {}
        catalog.data.update(Npc={}, Object={}, Item={})
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

    def test_reference_matches_faction_label_without_changing_quest_id(self):
        catalog = self.catalog()
        catalog.data["guideNames"] = {"8856": "Desert Survival Kits (A)"}
        self.assertTrue(catalog.matches_quest_name(dict(questId=8856, questName="Desert Survival Kits")))
        self.assertFalse(catalog.matches_quest_name(dict(questId=8856, questName="Unclaimed Baggage")))

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

    def test_wowdb_reference_requires_matching_title_and_forever_items(self):
        catalog = self.catalog()
        catalog.data["Quest"]["783"]["10"] = {"3": {"1": {"1": 5770}}}
        reference = dict(questId=783, questName="A Threat Within", facts={},
                         objective=dict(kind="craft", items=[5770], text="Obtain the required robes."))
        self.assertTrue(catalog.reference(reference))
        self.assertEqual(catalog.reports["783"]["objective"]["items"], [5770])
        catalog.reports = {}
        reference["objective"]["items"] = [99999]
        self.assertFalse(catalog.reference(reference))
        self.assertNotIn("objective", catalog.reports["783"])
        reference["questName"] = "A Different Quest"
        self.assertFalse(catalog.reference(reference))

    def test_crafting_requirements_do_not_route_objectives_to_finisher(self):
        catalog = self.catalog()
        quest = catalog.data["Quest"]["783"]
        quest["10"] = {"3": {"1": {"1": 5770}}}
        catalog.data["Npc"]["197"] = {"1": "Finisher", "7": {"12": {"1": {"1": 48, "2": 42}}}}
        catalog.data["Item"]["5770"] = {"1": "Robes of Arcana"}
        catalog.reference(dict(questId=783, questName="A Threat Within", facts={},
                               objective=dict(kind="craft", items=[5770], text="Obtain the required robes.")))
        record = catalog.record(783)
        self.assertEqual(record["turnin"][0]["id"], 197)
        self.assertNotIn("objective", record)
        self.assertEqual(record["objectiveSource"], "WoWDB")

    def test_scripted_targets_resolve_reputation_and_flight_work(self):
        catalog = self.catalog()
        catalog.data["Npc"]["4653"] = {"1": "Enemy", "13": "A", "7": {"12": {"1": {"1": 48, "2": 42}}}}
        marker = {"2": 1, "5": {"1": {"1": "monster", "2": 4653}}}
        quest = {"29": {"1": marker}}
        point = catalog.objectives(quest)[0]
        self.assertEqual(point["kind"], "target")
        self.assertNotIn("faction", point)
        marker["2"] = 5
        point = catalog.objectives(quest)[0]
        self.assertEqual(point["kind"], "npc")
        self.assertEqual(point["faction"], "Alliance")

    def test_search_names_remove_instruction_labels_and_keep_real_colons(self):
        self.assertEqual(quest_name("Work on: Components for the Enchanted Gold Bloodrobe (1/5)"),
                         "Components for the Enchanted Gold Bloodrobe")
        self.assertEqual(quest_name("Pick up: Hail the Dragonslayer [H]"), "Hail the Dragonslayer")
        self.assertEqual(quest_name("Complete: Step Two: More Rock"), "Step Two: More Rock")
        catalog = self.catalog()
        self.assertTrue(catalog.matches_quest_name(dict(questId=783, questName="Work on: A Threat Within")))

    def test_item_started_quest_gets_loot_pickup_and_distinct_turnin(self):
        catalog = self.catalog()
        quest = catalog.data["Quest"]["783"]
        quest["10"] = {"3": {"1": {"1": 5770}}}
        catalog.data["Npc"].update({
            "823": {"1": "Starter"},
            "197": {"1": "Finisher", "7": {"12": {"1": {"1": 40, "2": 45}}}},
            "900": {"1": "Enemy", "13": "H", "7": {"12": {"1": {"1": 20, "2": 30}}}},
        })
        catalog.data["Item"]["5770"] = {"1": "Starter item"}
        catalog.reference(dict(questId=783, questName="A Threat Within", provider="Wowhead Forever", facts={},
            pickupItem=5770, pickupTargets=[dict(kind="Npc", id=900, name="Enemy")]))
        record = catalog.record(783)
        self.assertEqual(record["startItem"], 5770)
        self.assertEqual(record["pickup"][0]["id"], 900)
        self.assertEqual(record["pickup"][0]["kind"], "loot")
        self.assertNotIn("faction", record["pickup"][0])
        self.assertEqual(record["turnin"][0]["id"], 197)

    def test_target_names_need_unique_matching_entities_and_valid_world_points(self):
        catalog = self.catalog()
        catalog.data["Npc"]["900"] = {"1": "Enemy", "7": {"12": {"1": {"1": 20, "2": 30}}}}
        catalog.data["Npc"]["901"] = {"1": "Instance boss", "7": {"12": {"1": {"1": -1, "2": -1}}}}
        catalog.npc_names = {"Enemy": [900], "Ambiguous": [900, 901]}
        self.assertEqual(catalog.reference_targets([dict(kind="Npc", name="Enemy")], "Wowhead Forever")[0]["id"], 900)
        self.assertEqual(catalog.reference_targets([dict(kind="Npc", id=900, name="Different NPC")], "Wowhead Forever"), [])
        self.assertEqual(catalog.reference_targets([dict(kind="Npc", name="Ambiguous")], "Wowhead Forever"), [])
        self.assertEqual(catalog.reference_targets([dict(kind="Npc", id=901, name="Instance boss")], "Wowhead Forever"), [])

    def test_named_reference_cannot_change_known_forever_finisher_identity(self):
        catalog = self.catalog()
        catalog.data["Npc"] = {
            "197": {"1": "Native finisher"},
            "900": {"1": "Different finisher", "7": {"12": {"1": {"1": 20, "2": 30}}}},
        }
        catalog.npc_names = {"Different finisher": [900]}
        catalog.reference(dict(questId=783, questName="A Threat Within", facts={"Turned in to": "Different finisher"},
            provider="Wowhead Classic", objective=dict(kind="delivery", text="Deliver the item.",
            targets=[dict(kind="Npc", name="Different finisher")])))
        record = catalog.record(783)
        self.assertNotIn("turnin", record)
        self.assertNotIn("objective", record)
        self.assertNotIn("turninName", record)


if __name__ == "__main__":
    unittest.main()
