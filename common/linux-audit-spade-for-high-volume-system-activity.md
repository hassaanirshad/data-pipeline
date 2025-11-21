# Using SPADE with Linux Audit for high-volume system activity

This README describes how to use SPADE to capture provenance from high-volume system activity such as containerized workloads. High-volume system activity generates large amounts of Linux Audit logs. These logs can overwhelm various buffers involved in the provenance capture data pipeline `(kauditd & spade-kernel-modules) -> auditd -> audispd -> SPADE(Audit reporter) -> SPADE(PostgreSQL storage)`. In case of buffer overwhelm, a loss of Linux Audit logs occurs. This loss can be minimized by splitting the data pipeline into two steps. In the first step, only the `(kauditd & spade-kernel-modules) -> auditd -> audispd` part of the data pipeline is employed to capture Linux Audit logs. In the second step, only the `SPADE(Audit reporter) -> SPADE(PostgreSQL storage)` part of the data pipeline is employed to capture provenance of the already collected Linux Audit logs. This decoupling reduces the capacity strain on buffers; hence minimizes the loss of Linux Audit records.

Rest of the README shows:

1. An example of real-time provenance capture using SPADE's Audit reporter. This is shown to contrast with the two-step approach.
2. The two-step approach to capture provenance of a hello-world containerized workload using SPADE's Audit reporter.

## A. Requirements

1. Ubuntu 24.04 (kernel between 5.4.0 and 6.8.0, x86_64).
2. Memory >= 16 GB.
3. Storage >= 100 GB.
4. [SPADE](https://github.com/ashish-gehani/SPADE/tree/master/) and its [requirements](https://github.com/ashish-gehani/SPADE/wiki/Requirements).
5. Follow [Linux Audit subsystem configuration](/common/linux-audit-spade-config.md).
6. Build SPADE with kernel modules:
```
$ pushd SPADE && \
    ./configure && \
    make KERNEL_MODULES=true && \
    ./bin/allowAuditAccess
```
7. Install PostgreSQL using SPADE's helper script:
```
$ pushd SPADE && \
    ./bin/installPostgres
```

## B. Example of real-time provenance capture

The following steps are sufficient to capture low levels of system activity using SPADE's Audit reporter without any Linux Audit record loss.

```
$ pushd SPADE
$ ./bin/spade start
$ ./bin/spade control
# Store provenance in Postgres database.
-> add storage PostgreSQL
# Since 'inputLog' argument is not specified, real-time provenance capture is done.
-> add reporter Audit
-> exit

###
# Perform system activity to capture provenance of.
###

$ ./bin/spade control
-> remove reporter Audit
-> remove storage PostgreSQL
-> exit
$ ./bin/spade stop
$ popd
```

## C. Two-step approach to capture provenance of a hello-world containerized workload

### C.1. Step 1: Workload log collection

In this step, we first start log collection and then run the hello-world container.

```
###
# 1. Stop audit service for existing log archiving.
###
$ sudo service auditd stop
$ sudo mkdir -p /var/log/audit/archived_audit_logs
$ sudo mv /var/log/audit/audit.log* /var/log/audit/archived_audit_logs/
$ sudo service auditd start

###
# 2. Start log collection, using SPADE, of all users except the current user.
###
$ pushd SPADE
$ ./bin/spade run-util ManageAuditKernelModules \
    --controller=./lib/kernel-modules/spade_audit_controller.ko \
    --main=./lib/kernel-modules/spade_audit.ko \
    --ignoreProcesses=auditd,kauditd,audispd \
    --ignoreParentProcesses=auditd,kauditd,audispd \
    --netIO=true \
    --namespaces=true \
    --nfNat=true

$ ./bin/spade run-util ManageAuditControlRules \
    --syscall=all \
    --ignoreProcesses=auditd,kauditd,audispd \
    --ignoreParentProcesses=auditd,kauditd,audispd \
    --excludeProctitle=true \
    --kernelModules=true \
    --netIO=true \
    --fileIO=true \
    --memory=true \
    --fsCred=true \
    --dirChange=true \
    --rootChange=true \
    --namespaces=true \
    --ipc=true

$ popd

###
# 3. Run hello-world container.
###
$ sudo docker run --rm hello-world

###
# 4. Check status of Linux Audit buffer.
###
$ sudo auditctl -s
# The value of key 'backlog' shows the current size of the Linux Audit buffer.
# The backlog size will rise and fall based on system activity since all users except current one are being audited.
# Waiting for the backlog size to stop spiking is generally a sign that the audit logs have been written to disk by Linux Audit.
# You can also check the lost audit logs by viewing the value of key 'lost' in 'auditctl -s' output.

###
# 5. Stop log collection.
###
$ pushd SPADE
$ ./bin/spade run-util ManageAuditKernelModules \
    --controller=./lib/kernel-modules/spade_audit_controller.ko \
    --remove=true

$ ./bin/spade run-util ManageAuditControlRules \
    --syscall=all \
    --remove=true

$ popd

###
# 6. Move collected logs to a non-root location for SPADE to process later.
###
$ pushd SPADE
$ mkdir -p ./hello-world-container-logs
$ sudo cp /var/log/audit/audit.log* ./hello-world-container-logs/
$ sudo chown ${USER}:${USER} ./hello-world-container-logs/*
$ popd
```

### C.2. Step 2: Provenance capture

In this step, we process the logs collected in C.1. using SPADE to capture provenance.

```
$ pushd SPADE
$ ./bin/spade start
$ ./bin/spade control
-> add storage PostgreSQL
-> add reporter Audit inputLog=./hello-world-container-logs/audit.log rotate=true fileIO=true netIO=true IPC=true namespaces=true unixSockets=true inode=true waitForLog=true handleNetworkAddressTranslation=true
# Wait for a few seconds and remove the reporter
-> remove reporter Audit
# The command, above, will not return until all the logs have been processed.
# Once the command returns, remove storage as well.
-> remove storage PostgreSQL
-> exit
$ ./bin/spade stop
$ popd
```

## D. Conclusion

The two-step provenance capture approach helps reduce audit log loss from high-volume system activity. By decoupling the log collection phase from the provenance capture phase, this method reduces the capacity strain on buffers that can occur during real-time processing. This technique is particularly useful for containerized workloads and other high-volume system activities. The two-step approach requires additional disk space for intermediate log storage and introduces a delay between activity and provenance capture. While this method minimizes audit log loss, it does not eliminate it entirely. Loss can still occur during the collection phase if system activity exceeds buffer capacity.

