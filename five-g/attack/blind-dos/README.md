# 5G blind DOS attack data pipeline

This data pipeline uses:

1. [OAI-5G-Docker](https://github.com/5GSEC/OAI-5G-Docker) repository for running [5G Blind DOS attack](https://www.ieee-security.org/TC/SP2019/SP19-Slides-pdfs/Hongil_Kim_13_-_Touching_the_Untouchables.pdf),
2. [SPADE](https://github.com/ashish-gehani/spade) for data collection

## A. Requirements

1. Ubuntu 20.04 (kernel <= 5.4.0 x86_64)
2. Memory >= 16 GB
3. Storage >= 60 GB

**Note**: It is assumed that the requirements for the repositories used have been met.

## B. Setup

### B.1. Submodules

Make sure that submodules are up-to-date.
```
git submodule update --recursive --init .
```

### B.2. Auditd

Update auditd configuration.

In file `/etc/audit/auditd.conf`:

1. Set `max_log_file` to at least `1024`.
2. Set `num_logs` to at least `10`.
3. Set `disp_qos` to `lossless`.

In file `/etc/audit/audit.rules`:

1. Add the line `-b 10000000`, if not present. Otherwise, update the value of `-b`.

In file `/etc/audisp/audispd.conf`:

1. Set `q_depth` to `9999`.

In file `/etc/audisp/plugins.d/af_unix.conf`:

1. Set `active` to `yes`.

Stop `auditd` service, and archive (or cleanup, if not needed) any existing logs in `/var/log/audit`.

Restart `auditd` service, and validate that it is started successfully.

### B.3. SPADE

Execute the following commands successfully:

```
pushd SPADE
./configure
make KERNEL_MODULES=true
./bin/allowAuditAccess
popd
```

## C. Data collection

### C.1. Archive audit logs

Archive existing audit logs manually or use:

```
./bin/archive-audit-logs.sh
```

### C.2. Start auditing

Add audit control rules, and add kernel modules.

```
./bin/start-auditing.sh
```

### C.3. Run activity

Start, and stop activity i.e. the start the attack, wait for 'X' minutes, and stop the attack.

```
./bin/run-activity.sh
```

### C.4. Stop auditing

Stop auditing, and additionally get notified of any loss in audit records.

```
./bin/stop-auditing.sh
```

### C.5. Collect audit logs

Copy audit logs from `/var/log/audit` to `./logs/audit`.

```
./bin/collect-audit-logs.sh
```
