"""Pre-QA public beta must disclose known ForeverDB gaps and QA status."""
import os
import subprocess
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
CHECK=ROOT/"scripts/check_forever_beta_readiness.py"
VALID="""# WayForth Forever beta

## Known limitations
- **Engineering:** verified recipe gap 52–54 (#55).
- **First Aid:** verified recipe gaps 45–49 and 75–79 (#56).
- **in-game QA pending:** this is a pre-QA beta.
"""


class ForeverBetaGateTests(unittest.TestCase):
    def invoke(self, notes):
        env=dict(os.environ,CHANGELOG=notes)
        return subprocess.run([sys.executable,str(CHECK)],cwd=ROOT,env=env,
                              capture_output=True,text=True,check=False)

    def test_complete_disclosure_allows_a_beta(self):
        result=self.invoke(VALID)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn("NOT an in-game QA approval",result.stdout)

    def test_missing_qa_disclosure_blocks_release(self):
        self.assertNotEqual(self.invoke(VALID.replace("in-game QA pending","QA completed")).returncode,0)

    def test_undisclosed_known_issue_blocks_release(self):
        self.assertNotEqual(self.invoke(VALID.replace("75–79","")).returncode,0)
        self.assertNotEqual(self.invoke(VALID.replace("#55","")).returncode,0)


if __name__=="__main__":
    unittest.main()
