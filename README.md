# soc-home-lab

![rule-tests](https://github.com/darkside0001/soc-home-lab/actions/workflows/tests.yml/badge.svg)
![Wazuh](https://img.shields.io/badge/Wazuh-4.12-blue)
![MITRE ATT&CK](https://img.shields.io/badge/MITRE%20ATT%26CK-mapped-red)
![License](https://img.shields.io/badge/license-MIT-green)

> **A full SSH kill chain, from recon to log clearing, caught by 15 custom Wazuh
> rules mapped to MITRE ATT&CK, with 19 engine-verified test cases run in CI on
> every push.**

## What this project demonstrates

| Skill | Evidence in this repo |
|-------|-----------------------|
| SIEM deployment | Wazuh manager + indexer + dashboard with an enrolled agent ([`lab/`](lab/)) |
| Detection engineering | 15 custom rules using correlation (`frequency`, `timeframe`, `if_matched_sid`, `same_srcip`) ([`rules/`](rules/local_rules.xml)) |
| MITRE ATT&CK mapping | every rule tagged with technique IDs ([`docs/detection-rules.md`](docs/detection-rules.md)) |
| Adversary emulation | scripted, repeatable attack chain ([`attacks/`](attacks/)) |
| Detection-as-code | true-positive *and* false-positive tests against the real engine in GitHub Actions ([`tests/`](tests/)) |
| Incident reporting | analyst-style incident report template ([`report/`](report/incident-report-template.md)) |

## Kill chain → detections

| # | Stage | Rules | ATT&CK |
|---|-------|-------|--------|
| 1 | Recon: SSH service scan | 100500 | T1046 |
| 2 | Password spraying / user enumeration | 100101 | T1110.003 · T1087 |
| 3 | Brute force | 100100 | T1110.001 |
| 4 | **Successful login after brute force** | **100102** (level 14), 100103 | T1110 → T1078 |
| 5 | Privilege escalation via sudo | 100200 · 100201 · 100202 | T1548.003 · T1059.004 |
| 6 | Persistence | 100300 · 100301 · 100302 · 100303 · 100310 · 100311 | T1136.001 · T1098 · T1098.004 · T1053.003 |
| 7 | Covering tracks: log truncation | 100400 | T1070.002 |

A reproducible **SOC home lab** built on [Wazuh](https://wazuh.com). It stands up
a small monitored network in Docker, runs a scripted SSH attack chain against a
deliberately weak host, and detects every step with **custom rules mapped to
MITRE ATT&CK**.

> **This is a lab you can run, not a record of real incidents.** Everything here
> is synthetic: the "attacks" run only against this lab's own container, on an
> isolated network, using throwaway credentials. The attack scripts refuse to
> run against any target outside `172.30.0.0/24`. Use it on systems you own.

## What's inside

```
rules/local_rules.xml     15 custom detection rules, each mapped to MITRE ATT&CK
tests/                    replays test cases through the real Wazuh engine (CI)
lab/                      docker-compose overlay: victim + attacker + Wazuh wiring
attacks/                  scripted kill chain (recon → spray → brute → privesc → persistence)
scripts/                  setup.sh / attack.sh / teardown.sh
docs/                     network diagram + detection-rules reference
report/                   incident-report template to write up a lab run
examples/sample-alerts.json  real alert output captured from the engine
```

## Topology

![network diagram](docs/network.svg)

- **wazuh.manager / indexer / dashboard** — the official single-node Wazuh stack.
- **victim** (`172.30.0.20`) — Ubuntu with sshd, a Wazuh agent, weak accounts and
  an over-permissive sudo rule. It is intentionally insecure.
- **attacker** (`172.30.0.66`) — Kali-style toolbox (hydra, nmap, sshpass).

## Requirements

- Docker + Docker Compose v2
- ~4 GB RAM free (the Wazuh indexer is the heavy part)
- Linux host with `vm.max_map_count=262144` (`sudo sysctl -w vm.max_map_count=262144`)

## Run it

```bash
# 1. Bring up Wazuh + the lab (clones the official wazuh-docker stack on first run)
scripts/setup.sh

# 2. Open the dashboard once it's healthy (2-3 min): https://localhost
#    login: admin / SecretPassword

# 3. Launch the attack chain and watch the alerts appear
scripts/attack.sh all          # or: recon | spray | brute | privesc | persist

# 4. Tear everything down
scripts/teardown.sh
```

Then open **Threat Hunting / Security Alerts** in the dashboard and filter on
rule groups `soc_lab` to see the detections, or write up the run with
[`report/incident-report-template.md`](report/incident-report-template.md).

## Detections

15 rules covering the chain. Full table with MITRE IDs and the test that proves
each one in [`docs/detection-rules.md`](docs/detection-rules.md). Highlights:

| Rule | MITRE | Detects |
|------|-------|---------|
| 100102 (level 14) | T1110 → T1078 | **successful SSH login right after a brute force** — the alert that matters most |
| 100100 | T1110.001 | SSH brute force from one source |
| 100101 | T1110.003 | password spraying / user enumeration |
| 100201 | T1548.003 | sudo → GTFOBins shell escape |
| 100300 | T1136.001 | UID 0 backdoor account |
| 100310 | T1098.004 | SSH key planted in `authorized_keys` (FIM) |
| 100400 | T1070.002 | auth log truncated to hide tracks |

Real output from the engine for the key alert (all 14 captured alerts are in
[`examples/sample-alerts.json`](examples/sample-alerts.json)):

```json
{
  "event": "Nov 20 10:16:10 victim sshd[2100]: Accepted password for alice from 172.30.0.66 port 50100 ssh2",
  "rule": {
    "id": "100102",
    "level": 14,
    "description": "SOC-LAB: Successful SSH login for alice from 172.30.0.66 after brute force - possible account compromise",
    "mitre": { "id": ["T1110", "T1078"], "technique": ["Brute Force", "Valid Accounts"] }
  }
}
```

A single failed login is noise. A successful login from the **same IP** that was
just brute forcing means the password was probably guessed, so 100102 correlates
the two and escalates to critical.

## Testing

The rules are verified against the real Wazuh 4.12 engine — no mocks. Each case
in [`tests/cases.json`](tests/cases.json) is replayed through `wazuh-logtest`
inside a throwaway manager container, so frequency/timeframe correlation (brute
force, spraying, success-after-brute-force) is evaluated exactly as in
production.

```bash
./tests/test_rules.sh      # needs only Docker; this is what CI runs
```

Every push runs this via GitHub Actions. Current suite: **19/19 cases**, covering
both true positives and quiet-on-benign cases (a single failed login, a normal
sudo command and a normal UID account must *not* alert).

## Why this exists

A SOC analyst's core skill is turning telemetry into detections. This lab shows
the full loop end to end: build a monitored environment, generate adversary
behaviour, write detection logic, map it to ATT&CK, and prove it fires with
automated tests. It is meant to be read, run and extended.

## License

MIT — see [LICENSE](LICENSE).

---

**Author:** Razim Kudaybergenov — MSc Cyber Security (APU / De Montfort University) ·
Fortinet NSE 1–3 · [Portfolio](https://darkside0001.github.io) · [GitHub](https://github.com/darkside0001)
