import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from engine_runner import command

class Tests(unittest.TestCase):
    def test_directions_and_validation(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            engine = root / 'engine'; engine.mkdir()
            (engine / 'dawvert_cmd.py').touch()
            python = root / 'python'; python.touch()
            for ext, out, incoming, outgoing in [('.flp', '.als', 'flp', 'ableton'), ('.als', '.flp', 'ableton', 'flp')]:
                inp = root / ('project' + ext); inp.touch()
                dest = root / ('converted' + out)
                cmd = command(engine, inp, dest, python)
                self.assertEqual(cmd[2:4], ['-it', incoming])
                self.assertEqual(cmd[6:8], ['-ot', outgoing])
                with self.assertRaises(ValueError): command(engine, inp, root / 'invalid.wav', python)
                dest.touch()
                with self.assertRaises(ValueError): command(engine, inp, dest, python)

if __name__ == '__main__': unittest.main()
