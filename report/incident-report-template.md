# Incident report — SSH compromise of `victim`

> Template for writing up a run of this lab as if it were a real investigation.
> Replace the bracketed values with what you see in the Wazuh dashboard after
> running `scripts/attack.sh all`. This is a lab exercise, not a record of a
> real breach.

- **Report ID:** IR-[YYYY]-[NN]
- **Analyst:** [name]
- **Date/time (UTC):** [when you investigated]
- **Severity:** High
- **Status:** Contained (lab)

## 1. Summary

Between **[start]** and **[end]** UTC, host **victim (172.30.0.20)** was
targeted from **172.30.0.66**. The attacker enumerated accounts, brute forced
the `alice` account over SSH, logged in successfully, escalated to root through
a sudo misconfiguration, established persistence, and attempted to clear logs.
Wazuh raised **[N]** alerts across the chain, the highest being rule **100102
(level 14)** — a successful login following brute force.

## 2. Timeline (from Wazuh alerts)

| Time (UTC) | Rule | Level | MITRE | What happened |
|------------|------|-------|-------|----------------|
| [t0] | 100500 | 8 | T1046 | SSH service scan from 172.30.0.66 |
| [t1] | 100101 | 10 | T1110.003 | Username spraying |
| [t2] | 100100 | 10 | T1110.001 | Brute force of `alice` |
| [t3] | 100102 | 14 | T1110→T1078 | Successful login as `alice` after brute force |
| [t4] | 100201 | 12 | T1548.003 | Privilege escalation via `sudo find` |
| [t5] | 100300 | 14 | T1136.001 | UID 0 backdoor account `sysupdate` created |
| [t6] | 100310 | 12 | T1098.004 | SSH key planted in `/root/.ssh/authorized_keys` |
| [t7] | 100303 | 10 | T1053.003 | Root crontab modified |
| [t8] | 100301 | 12 | T1098 | `bob` added to sudo group |
| [t9] | 100400 | 12 | T1070.002 | `auth.log` truncated |

## 3. Impact

- Account `alice` compromised (weak password `sunshine1`).
- Root access obtained; integrity of `victim` can no longer be trusted.
- Persistence mechanisms left behind: UID 0 account, root SSH key, cron job,
  extra sudo member.

## 4. Root cause

1. Weak, guessable password on `alice`, with password authentication enabled.
2. Over-permissive sudo rule (`alice` → `/usr/bin/find`) allowing a GTFOBins
   shell escape.

## 5. Containment & eradication

- [ ] Disable/kill the attacker's sessions; block 172.30.0.66.
- [ ] Remove the `sysupdate` account and the planted root SSH key.
- [ ] Remove the malicious cron entry and revert `bob`'s group membership.
- [ ] Reset `alice`'s password; rotate any shared secrets on the host.
- [ ] Rebuild the host from a known-good image (root was compromised).

## 6. Recommendations

- Enforce key-based SSH auth; disable password auth; rate-limit with fail2ban.
- Remove the `find` sudo grant; audit all sudoers entries for GTFOBins risk.
- Ship logs off-host so truncation (T1070.002) cannot hide activity.
- Keep the FIM rules (100310/100311) active to catch key and sudoers changes.

## 7. Evidence

Attach the exported alerts (`examples/sample-alerts.json` shows the shape) and
relevant `auth.log` excerpts.
