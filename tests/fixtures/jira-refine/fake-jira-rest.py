#!/usr/bin/env python3
"""A fake Jira REST v2 server for exercising `RestTransport` in jira-apply.py.

    fake-jira-rest.py --port 8791 --seed issues.json

Serves the same five endpoints `RestTransport` calls against `/rest/api/2`:
GET/PUT issue, POST issueLink, POST issue, GET field. State lives in memory,
seeded once from a JSON file shaped like `issues.json` (issue key -> issue as
the v2 API returns it), and every mutating request appends one JSON line to
`$FAKE_JIRA_LOG`. A GET is never a write and is never logged — that asymmetry
is what lets a smoke test assert "the second run touches the log not at all"
without also asserting "the second run makes no requests", which would be a
much more fragile claim about a caller that legitimately re-reads an issue
before deciding to skip it.

`RestTransport._request` treats a 404 as "no issue" for every verb, not only
GET, so a PUT or POST against an unknown key also returns 404 here rather than
inventing a row — a fake that autovivified rows would make every run look
idempotent, which is exactly what this fixture exists to catch elsewhere.

The link shape stored on an issue is chosen to match the one consumer that
reads it back, `linked_dependencies` in jira-apply.py: it scans an issue's own
`issuelinks` for entries with `inwardIssue.key`, treating that key as the
dependency. `create_link`'s request body instead names the *current* issue as
`inwardIssue` and the dependency as `outwardIssue` (matching real Jira's
"outward issue blocks inward issue" convention for a `Blocks`-type link). This
fake stores the entry in the shape the reader expects rather than the shape
the writer sent, because a round trip through the wrong shape would make
`create_link` followed by a second `update` create the same link twice —
the "already-present" idempotency rule 5 exists to prevent.

Standard library only, so the fixture stays copy-in portable like the script
it stands in for.
"""
import argparse
import json
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

API_PREFIX = "/rest/api/2/"


class State:
    """In-memory issue table plus the counter `create_issue` mints keys from."""

    def __init__(self, seed_path):
        with open(seed_path, "r", encoding="utf-8") as f:
            self.issues = json.load(f)
        self.lock = threading.Lock()
        self.next_id = 1000


def log_write(log_path, record):
    """Append one JSON line describing a mutating request, or do nothing.

    A GET never calls this. The log is the smoke test's only window into "did
    a second run write anything", so a write that skipped this call would be
    invisible to the thing checking idempotency, not merely under-reported."""
    if not log_path:
        return
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")


class Handler(BaseHTTPRequestHandler):
    state = None
    log_path = None

    def log_message(self, format, *args):
        # http.server's default access log would interleave with jira-apply's
        # own stderr report lines in a test harness capturing both; the
        # smoke test cares about $FAKE_JIRA_LOG, not this stream.
        pass

    # -- helpers --------------------------------------------------------

    def _send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8") if payload is not None else b""
        self.send_response(status)
        self.send_header("Content-Length", str(len(body)))
        if body:
            self.send_header("Content-Type", "application/json")
        self.end_headers()
        if body:
            self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get("Content-Length") or 0)
        if not length:
            return {}
        raw = self.rfile.read(length)
        if not raw:
            return {}
        return json.loads(raw.decode("utf-8"))

    def _rest_path(self):
        """The path under `/rest/api/2/`, or None when it doesn't match.

        `RestTransport` sends `Authorization: Basic ...` on every request; it
        is read here only to the extent of not existing — the contract says
        the fake accepts and ignores it, so there is no check at all."""
        parsed = urlparse(self.path)
        if not parsed.path.startswith(API_PREFIX):
            return None
        return parsed.path[len(API_PREFIX):]

    # -- verbs ------------------------------------------------------------

    def do_GET(self):
        rest = self._rest_path()
        if rest is None:
            self._send_json(404, {"errorMessages": ["not found"]})
            return
        if rest.startswith("issue/"):
            key = unquote(rest[len("issue/"):].split("?", 1)[0])
            with self.state.lock:
                issue = self.state.issues.get(key)
            if issue is None:
                self._send_json(404, {"errorMessages": [f"{key} does not exist"]})
                return
            # RestTransport.get_issue asks for a `fields` subset via the query
            # string, but every consumer only reads the named keys it wants
            # out of whatever comes back, so serving the full stored issue is
            # observationally identical and one fewer thing to keep in sync
            # with the caller's field list.
            self._send_json(200, issue)
            return
        if rest.split("?", 1)[0] == "field":
            # cmd_fields's discovery path. This fixture seeds no custom-field
            # metadata, so there is nothing to find; still answering 200 with
            # an empty list (rather than 404) keeps `fields` a "no field
            # matched", not "no such endpoint".
            self._send_json(200, [])
            return
        self._send_json(404, {"errorMessages": ["not found"]})

    def do_PUT(self):
        rest = self._rest_path()
        if rest is None or not rest.startswith("issue/"):
            self._send_json(404, {"errorMessages": ["not found"]})
            return
        key = unquote(rest[len("issue/"):].split("?", 1)[0])
        payload = self._read_json()
        fields = payload.get("fields") or {}
        with self.state.lock:
            issue = self.state.issues.get(key)
            if issue is None:
                self._send_json(404, {"errorMessages": [f"{key} does not exist"]})
                return
            issue.setdefault("fields", {}).update(fields)
        log_write(self.log_path, {"method": "PUT", "path": f"issue/{key}", "body": payload})
        self._send_json(204, None)

    def do_POST(self):
        rest = self._rest_path()
        if rest is None:
            self._send_json(404, {"errorMessages": ["not found"]})
            return
        path = rest.split("?", 1)[0]
        payload = self._read_json()

        if path == "issueLink":
            inward_key = (payload.get("inwardIssue") or {}).get("key")
            outward_key = (payload.get("outwardIssue") or {}).get("key")
            link_type = (payload.get("type") or {}).get("name")
            with self.state.lock:
                issue = self.state.issues.get(inward_key)
                if issue is None:
                    self._send_json(404, {"errorMessages": [f"{inward_key} does not exist"]})
                    return
                # See the module docstring: stored keyed by `inwardIssue` to
                # match `linked_dependencies`, the only reader.
                issue.setdefault("fields", {}).setdefault("issuelinks", []).append(
                    {"type": {"name": link_type}, "inwardIssue": {"key": outward_key}}
                )
            log_write(self.log_path, {"method": "POST", "path": "issueLink", "body": payload})
            self._send_json(201, {})
            return

        if path == "issue":
            fields = payload.get("fields") or {}
            project = (fields.get("project") or {}).get("key") or "PROJ"
            with self.state.lock:
                self.state.next_id += 1
                key = f"{project}-{self.state.next_id}"
                self.state.issues[key] = {"key": key, "fields": dict(fields)}
            log_write(self.log_path, {"method": "POST", "path": "issue", "body": payload})
            self._send_json(201, {"key": key})
            return

        self._send_json(404, {"errorMessages": ["not found"]})


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--port", type=int, required=True)
    ap.add_argument("--seed", required=True, metavar="PATH")
    args = ap.parse_args(argv)

    state = State(args.seed)
    log_path = os.environ.get("FAKE_JIRA_LOG")

    handler = type("BoundHandler", (Handler,), {"state": state, "log_path": log_path})
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
