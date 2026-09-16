import hashlib
import os
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "skills/apple-mail/apple-mail.sh"


class AppleMailTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="apple-mail-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.mail = self.home / "Library/Mail"
        self.version = self.mail / "V10"
        self.db = self.version / "MailData/Envelope Index"
        self.db.parent.mkdir(parents=True)
        (self.mail / "V9").mkdir()
        (self.mail / "Version-other").mkdir()
        self.tmp = self.home / "tmp"
        self.tmp.mkdir()
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "TMPDIR": str(self.tmp),
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "TZ": "UTC",
        }
        self.env.pop("BASH_ENV", None)
        with sqlite3.connect(self.db) as db:
            db.executescript("""
                CREATE TABLE mailboxes (url TEXT, total_count INTEGER, unread_count INTEGER);
                CREATE TABLE addresses (address TEXT, comment TEXT);
                CREATE TABLE subjects (subject TEXT);
                CREATE TABLE summaries (summary TEXT);
                CREATE TABLE messages (sender INTEGER, subject INTEGER, mailbox INTEGER,
                    summary INTEGER, date_received INTEGER, date_sent INTEGER, size INTEGER,
                    read INTEGER, flagged INTEGER, deleted INTEGER);
                CREATE TABLE recipients (message INTEGER, address INTEGER, type INTEGER, position INTEGER);
                CREATE TABLE attachments (message INTEGER, attachment_id TEXT, name TEXT);
                INSERT INTO mailboxes VALUES ('imap://test/INBOX', 3, 1);
                INSERT INTO addresses VALUES ('alice@example.com', 'Alice'), ('me@example.com', 'Me');
                INSERT INTO subjects VALUES ('Research meeting'), ('Other'), ('Deleted');
                INSERT INTO summaries VALUES ('Summary preview'), ('Other preview'), ('Deleted preview');
                INSERT INTO messages (ROWID, sender, subject, mailbox, summary, date_received,
                    date_sent, size, read, flagged, deleted) VALUES
                    (12345, 1, 1, 1, 1, 1767225600, 1767225600, 100, 0, 1, 0),
                    (7, 1, 2, 1, 2, 1767312000, 1767312000, 100, 1, 0, 0),
                    (8, 1, 3, 1, 3, 1767398400, 1767398400, 100, 0, 0, 1);
                INSERT INTO recipients VALUES (12345, 2, 0, 0);
                INSERT INTO attachments VALUES (12345, '1', 'report.txt'), (12345, '2', 'report.txt');
            """)
        self.raw = b"From: alice@example.com\r\nSubject: Test\r\n\r\nBody: \xe4\xbd\xa0\xe5\xa5\xbd\r\n"
        self.make_message(12345, self.raw)
        self.make_message(7, self.raw, partial=True)
        self.attachment_dir = self.version / "account/INBOX.mbox/Data/2/1/Attachments/12345"
        for part, content in [("1", "first"), ("2", "second")]:
            directory = self.attachment_dir / part
            directory.mkdir(parents=True)
            (directory / "report.txt").write_text(content)
        self.original = self.snapshot()

    def tearDown(self):
        self.assertEqual(self.snapshot(), self.original, "Mail source files changed")

    def snapshot(self):
        return {str(p.relative_to(self.mail)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.mail.rglob("*") if p.is_file() and not p.is_symlink()}

    def make_message(self, message_id, body, partial=False, header=None):
        prefix = str(message_id)[:-3]
        folder = self.version / "account/INBOX.mbox/Data"
        for digit in reversed(prefix):
            folder /= digit
        folder /= "Messages"
        folder.mkdir(parents=True, exist_ok=True)
        file = folder / f"{message_id}{'.partial' if partial else ''}.emlx"
        file.write_bytes((header if header is not None else str(len(body)).encode() + b"\n")
                         + body + b"<plist>not email</plist>")
        return file

    def run_helper(self, *args, ok=True, env=None):
        result = subprocess.run(["/bin/bash", str(SCRIPT), *args], env=env or self.env,
                                capture_output=True, timeout=10)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr.decode())
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout.decode())
        return result

    def test_help_without_mail_access(self):
        env = {**self.env, "HOME": str(self.home / "missing")}
        self.assertIn(b"Search emails", self.run_helper("help", env=env).stdout)
        self.assertIn(b"Search emails", self.run_helper(env=env).stdout)
        self.assertIn(b"Full Disk Access", self.run_helper("mailboxes", env=env, ok=False).stderr)

    def test_search_filters_and_date_boundaries(self):
        result = self.run_helper("search", "--from", "alice@", "--to", "me@",
                                 "--subject", "meeting", "--body", "preview", "--mailbox", "INBOX",
                                 "--unread", "--flagged", "--has-attachment", "--limit", "5",
                                 "--after", "2026-01-01", "--before", "2026-01-02")
        self.assertIn(b"12345|alice@example.com", result.stdout)
        self.assertNotIn(b"Deleted", self.run_helper("search").stdout)
        self.assertNotIn(b"12345|", self.run_helper("search", "--before", "2026-01-01").stdout)
        self.assertNotIn(b"12345|", self.run_helper("search", "--after", "2026-01-02").stdout)

    def test_rejects_bad_ids_limits_and_missing_arguments(self):
        for command in ["info", "read", "attachment"]:
            for value in ["1; DELETE FROM messages;", "0", "-1", "../1", "1 OR 1=1"]:
                with self.subTest(command=command, value=value):
                    self.assertIn(b"positive integer", self.run_helper(command, value, ok=False).stderr)
            self.run_helper(command, ok=False)
        for value in ["1; DELETE FROM messages;", "0", "-1", "1001", "01", "1.5"]:
            self.run_helper("search", "--limit", value, ok=False)
        for option in ["--from", "--to", "--subject", "--body", "--mailbox", "--after", "--before", "--limit"]:
            self.assertIn(b"requires a value", self.run_helper("search", option, ok=False).stderr)
        self.run_helper("info", "7", "extra", ok=False)
        self.run_helper("search", "--after", "2026-02-30", ok=False)
        self.run_helper("search", "--after", "bad-date", ok=False)

    def test_text_injection_is_only_a_search_string(self):
        self.assertNotIn(b"12345|", self.run_helper("search", "--subject", "' OR 1=1; --").stdout)
        self.assertNotIn(b"12345|", self.run_helper("search", "--from", "O'Brien").stdout)

    def test_info_and_mailboxes(self):
        self.assertIn(b"imap://test/INBOX", self.run_helper("mailboxes").stdout)
        output = self.run_helper("info", "12345").stdout
        for text in [b"alice@example.com", b"me@example.com", b"report.txt", b"Summary preview"]:
            self.assertIn(text, output)

    def test_emlx_exact_bytes_and_partial_warning(self):
        self.assertEqual(self.run_helper("read", "12345").stdout, self.raw)
        result = self.run_helper("read", "7")
        self.assertEqual(result.stdout, self.raw)
        self.assertIn(b"partial download", result.stderr)

    def test_emlx_crlf_large_payload_and_invalid_header(self):
        large = self.raw * 10000
        self.make_message(42, large, header=str(len(large)).encode() + b"\r\n")
        self.make_message(43, self.raw, header=b"invalid\n")
        self.make_message(44, self.raw, header=b"999999\n")
        self.original = self.snapshot()
        self.assertEqual(self.run_helper("read", "42").stdout, large)
        self.assertIn(b"Invalid .emlx", self.run_helper("read", "43", ok=False).stderr)
        self.assertIn(b"Truncated", self.run_helper("read", "44", ok=False).stderr)
        self.run_helper("read", "99999", ok=False)

    def test_attachment_copies_keep_duplicate_names_and_private_permissions(self):
        (self.attachment_dir / "1/symlink.txt").symlink_to(self.db)
        result = self.run_helper("attachment", "12345", "report.txt")
        destination = Path(result.stdout.decode().strip())
        self.assertTrue(destination.is_relative_to(self.tmp))
        self.assertEqual(destination.stat().st_mode & 0o777, 0o700)
        self.assertEqual((destination / "files/1/report.txt").read_text(), "first")
        self.assertEqual((destination / "files/2/report.txt").read_text(), "second")
        self.assertEqual(list(destination.rglob("symlink.txt")), [])

    def test_attachment_missing_filter_cleans_temp_directory(self):
        self.run_helper("attachment", "12345", "../../outside", ok=False)
        self.assertEqual(list(self.tmp.iterdir()), [])
        self.run_helper("attachment", "7", ok=False)

    def test_sqlite_ignores_user_initialization(self):
        sentinel = self.home / "sqliterc-executed"
        (self.home / ".sqliterc").write_text(f".shell touch '{sentinel}'\n")
        self.run_helper("search")
        self.assertFalse(sentinel.exists())

    def test_sqlite_connection_actually_refuses_writes(self):
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        probe = bin_dir / "sqlite3"
        probe.write_text("""#!/bin/bash
set -eu
args=()
while [[ $# -gt 1 ]]; do args+=("$1"); shift; done
exec /usr/bin/sqlite3 "${args[@]}" 'UPDATE messages SET read = 1;'
""")
        probe.chmod(0o700)
        result = self.run_helper("search", env={**self.env, "PATH": f"{bin_dir}:/usr/bin:/bin"}, ok=False)
        self.assertIn(b"readonly", result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
