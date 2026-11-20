# Detection rules

All rules live in [`rules/local_rules.xml`](../rules/local_rules.xml) in the
reserved local range (100100–100599). Each one is replayed through the real
Wazuh 4.12 engine by [`tests/`](../tests) on every push, so the table below is
verified, not aspirational.

| Rule | Level | MITRE ATT&CK | Fires when | Tested by |
|------|-------|--------------|------------|-----------|
| 100100 | 10 | T1110.001 Password Guessing | 6+ failed SSH passwords from one source IP in 60 s | `ssh-bruteforce` |
| 100101 | 10 | T1110.003 Spraying · T1087 Account Discovery | one source tries 5+ different invalid usernames in 300 s | `ssh-password-spraying` |
| 100102 | 14 | T1110 → T1078 Valid Accounts | a successful SSH login from an IP that was just brute forcing | `ssh-success-after-bruteforce` |
| 100103 | 12 | T1078.003 Local Accounts | a direct SSH login as `root` | `ssh-root-login` |
| 100200 | 10 | T1548.003 · T1059.004 | `sudo` used to launch a shell or interpreter as root | `sudo-root-shell`, `sudo-python` |
| 100201 | 12 | T1548.003 Sudo/Setuid | `sudo` shell escape through an allowed binary (GTFOBins) | `sudo-gtfobins-find` |
| 100202 | 10 | T1548.003 | repeated `sudo` by a user not in sudoers | `sudo-not-in-sudoers-repeated` |
| 100300 | 14 | T1136.001 · T1078.003 | a new account created with UID 0 (root-equivalent backdoor) | `backdoor-uid0-account` |
| 100301 | 12 | T1098 Account Manipulation | an account added to a privileged group via `usermod` | `usermod-add-to-sudo` |
| 100302 | 12 | T1098 | an account added to the sudo group via `gpasswd` | `gpasswd-add-to-sudo` |
| 100303 | 10 | T1053.003 Cron | root's crontab is changed | `root-crontab-changed` |
| 100310 | 12 | T1098.004 SSH Keys | `~/.ssh/authorized_keys` created or modified (FIM, realtime) | manual (needs agent FIM) |
| 100311 | 12 | T1548.003 | `/etc/sudoers*` changed (FIM, realtime) | manual (needs agent FIM) |
| 100400 | 12 | T1070.002 Clear Logs | an auth/system log is truncated | `auth-log-truncated` |
| 100500 | 8 | T1046 Service Discovery | repeated SSH probes with no handshake from one IP | `ssh-service-scan` |

Rules 100310 and 100311 depend on Wazuh File Integrity Monitoring, which only
runs with a live agent, so they are exercised in the running lab rather than in
the offline `wazuh-logtest` CI.

## How the rules build on the Wazuh ruleset

The custom rules deliberately sit on top of Wazuh's built-in SSH, sudo and
syslog decoders/rules (5700-series, 5400-series, 2960, 592, …) rather than
re-decoding raw logs. That keeps them short and makes the intent clear: e.g.
100102 is "a successful-login rule (5715) that correlates with a prior
brute-force alert (100100) from the *same* source IP". The correlation uses
Wazuh's `if_matched_sid`, `frequency`, `timeframe` and `same_srcip` so the
timing behaviour is handled by the engine, not re-implemented.
