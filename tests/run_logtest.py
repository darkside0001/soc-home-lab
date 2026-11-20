#!/usr/bin/env python3
"""Replay test cases through the real Wazuh engine (wazuh-logtest socket).

Runs inside the wazuh-manager container:
    /var/ossec/framework/python/bin/python3 /tests/run_logtest.py /tests/cases.json

Every case gets its own logtest session, so frequency/timeframe rules
(brute force, spraying) are evaluated exactly as wazuh-analysisd would.
Standard library only.
"""
import json
import socket
import struct
import sys

SOCKET_PATH = "/var/ossec/queue/sockets/logtest"


def _call(payload):
    data = json.dumps(payload).encode()
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKET_PATH)
        s.sendall(struct.pack("<I", len(data)) + data)
        size = struct.unpack("<I", _recv_exact(s, 4))[0]
        return json.loads(_recv_exact(s, size))


def _recv_exact(s, n):
    buf = b""
    while len(buf) < n:
        chunk = s.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("logtest socket closed")
        buf += chunk
    return buf


def process(event, location, log_format, token=None):
    params = {"event": event, "log_format": log_format, "location": location}
    if token:
        params["token"] = token
    reply = _call({
        "version": 1,
        "origin": {"name": "soc-home-lab", "module": "tests"},
        "command": "log_processing",
        "parameters": params,
    })
    if reply.get("error"):
        raise RuntimeError(f"logtest error: {reply}")
    return reply["data"]


def close_session(token):
    try:
        _call({"version": 1, "origin": {"name": "soc-home-lab", "module": "tests"},
               "command": "remove_session", "parameters": {"token": token}})
    except Exception:
        pass


def run_case(case):
    token = None
    fired = []
    last = None
    hit = None
    expected = case.get("expect_rule")
    for event in case["events"]:
        data = process(event, case.get("location", "/var/log/auth.log"),
                       case.get("log_format", "syslog"), token)
        token = data.get("token", token)
        rule = data.get("output", {}).get("rule", {})
        last = rule
        if rule.get("id"):
            fired.append(rule["id"])
            if expected and str(rule["id"]) == str(expected) and hit is None:
                hit = (event, rule)
    if token:
        close_session(token)

    forbidden = case.get("forbid_rule")
    ok = True
    if expected and hit is None:
        ok = False
    if forbidden and str(forbidden) in fired:
        ok = False
    return ok, hit, last, fired


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "/tests/cases.json"
    alerts_out = sys.argv[2] if len(sys.argv) > 2 else None
    with open(path) as fh:
        cases = json.load(fh)

    failures = 0
    samples = []
    for case in cases:
        ok, hit, last, fired = run_case(case)
        status = "PASS" if ok else "FAIL"
        shown = hit[1] if hit else last
        got = f"{shown.get('id')} (level {shown.get('level')})" if shown else "none"
        print(f"[{status}] {case['name']}: rule {got} | {len(case['events'])} event(s)")
        if not ok:
            failures += 1
            print(f"       expected {case.get('expect_rule')} "
                  f"forbid {case.get('forbid_rule')} fired {fired}")
        elif hit:
            samples.append({
                "case": case["name"],
                "event": hit[0],
                "rule": {k: hit[1].get(k) for k in
                         ("id", "level", "description", "mitre", "groups", "firedtimes")
                         if k in hit[1]},
            })

    print(f"\n{len(cases) - failures}/{len(cases)} cases passed")
    if alerts_out:
        with open(alerts_out, "w") as fh:
            json.dump(samples, fh, indent=2)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
