import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import normalize_images as norm
from PIL import Image


class TestNormalizeImages(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.pics_dir = Path(self.temp_dir.name)

    def test_detect_png_disguised_as_jpg(self):
        bad_file = self.pics_dir / "12345678.jpg"
        bad_file.write_bytes(norm.MAGIC_PNG + b"\x00" * 32)

        issues = norm.scan_images(self.pics_dir)
        self.assertEqual(len(issues), 1)
        self.assertEqual(issues[0].issue_type, "MISMATCH")
        self.assertEqual(issues[0].detected_format, "PNG")
        self.assertEqual(issues[0].expected_extension, ".png")

        count, logs = norm.fix_mismatch_renames(issues, dry_run=False)
        self.assertEqual(count, 1)
        self.assertFalse(bad_file.exists())
        self.assertTrue((self.pics_dir / "12345678.png").exists())

    def test_detect_jpeg_disguised_as_png(self):
        bad_file = self.pics_dir / "87654321.png"
        bad_file.write_bytes(norm.MAGIC_JPEG + b"\xe0\x00\x10JFIF\x00")

        issues = norm.scan_images(self.pics_dir)
        self.assertEqual(len(issues), 1)
        self.assertEqual(issues[0].issue_type, "MISMATCH")
        self.assertEqual(issues[0].detected_format, "JPEG")
        self.assertEqual(issues[0].expected_extension, ".jpg")

        count, logs = norm.fix_mismatch_renames(issues, dry_run=False)
        self.assertEqual(count, 1)
        self.assertFalse(bad_file.exists())
        self.assertTrue((self.pics_dir / "87654321.jpg").exists())

    def test_convert_to_jpg(self):
        # Create a real PNG with RGBA mode
        png_file = self.pics_dir / "11112222.png"
        img = Image.new("RGBA", (100, 100), (255, 0, 0, 128))
        img.save(png_file, "PNG")

        issues = norm.scan_images(self.pics_dir, target_jpg_only=True)
        self.assertEqual(len(issues), 1)
        self.assertEqual(issues[0].issue_type, "NON_JPG")

        count, logs = norm.fix_issues_to_jpg(issues, dry_run=False)
        self.assertEqual(count, 1)
        self.assertFalse(png_file.exists())
        
        jpg_file = self.pics_dir / "11112222.jpg"
        self.assertTrue(jpg_file.exists())
        fmt, err = norm.detect_file_format(jpg_file)
        self.assertEqual(fmt, "JPEG")


if __name__ == "__main__":
    unittest.main()
