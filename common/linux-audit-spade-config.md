# Linux Audit configuration for SPADE

Update auditd configuration.

In file `/etc/audit/auditd.conf`:

1. Set `max_log_file` to at least `1024`.
2. Set `num_logs` to at least `10`.
3. Set `disp_qos` to `lossless`.
4. Set `log_format` to `RAW`.

In file `/etc/audit/audit.rules`:

1. Add the line `-b 10000000`, if not present. Otherwise, update the value of `-b`.

If file `/etc/audisp/audispd.conf` is present then:

1. Set `q_depth` to `9999`.

In file `/etc/audisp/plugins.d/af_unix.conf`:

1. Set `active` to `yes`.

Stop `auditd` service, and archive (or cleanup, if not needed) any existing logs in `/var/log/audit`.

Restart `auditd` service, and validate that it is started successfully.