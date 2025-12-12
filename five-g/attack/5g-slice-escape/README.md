# 5G slice escape attack data pipeline

This README describes how to capture OS activity for 5G slice escape attack scripts, and do analysis on the captured data.

This data pipeline uses:

1. [SPADE](https://github.com/ashish-gehani/spade) for data collection,
2. [srsRAN](https://github.com/srsRAN/srsRAN_Project.git) for 5G CU & DU,
* [srsRAN with K8s](https://docs.srsran.com/projects/project/en/latest/tutorials/source/k8s/source/index.html) deploy srsRAN with emulated RU.
3. [Open5GS](https://github.com/open5gs/open5gs) for 5G core and EPC.

## A. Requirements

1. Ubuntu 24.04 (kernel <= 6.8.0 x86_64)
2. Memory >= 16 GB
3. Storage >= 100 GB

**Note**: It is assumed that the requirements for the repositories used have been met.

## B. Setup

### B.1. Submodules

Make sure that submodules are up-to-date.
```
pushd ./five-g/attack/5g-slice-escape
git submodule update --recursive --init .
```

### B.2. Auditd

See the [Linux Audit Configuration](../../../common/linux-audit-spade-config.md) for details.

### B.3. SPADE

Execute the following commands successfully:

```
pushd SPADE
./configure
make KERNEL_MODULES=true
./bin/allowAuditAccess
popd
```

### B.4. srsRAN

This section follows the official documentation from [here](https://docs.srsran.com/projects/project/en/latest/tutorials/source/k8s/source/index.html).

1. Install K3s (Defaults used)
```
curl -sfL https://get.k3s.io | sh -
```

2. Install Realtime Kernel
```
# Register here (https://ubuntu.com/pro)
sudo pro attach <your-token>
sudo pro enable realtime-kernel
sudo reboot
```

3. Install TuneD as mentioned [here](https://docs.srsran.com/projects/project/en/latest/tutorials/source/tuning/source/index.html#tuning)

4. Install DPDK as mentioned [here](https://docs.srsran.com/projects/project/en/latest/tutorials/source/dpdk/source/index.html#dpdk-tutorial)
* Deviations:
```
# a. If 'intel_iommu=on iommu=pt' doesn't appear in '/proc/cmdline' or 
# TuneD kernel boot params are missing then copy TuneD variables in 
# '/etc/default/grub' to '/etc/default/grub.d/99-realtime.cfg'. This
# is based on the distro that you are using.

# b. SKIPPED FOR NOW BECAUSE OF HARDWARE ISSUES. [TODO]
```

5. Setup PTP synchronization AFTER DPDK is properly setup [TODO]
```
# Install helm (https://helm.sh/docs/intro/install/#from-apt-debianubuntu).
# Do as sudo... for convenience.
# 'sudo' kubectl and helm setup below:
sudo mkdir -p /root/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
sudo helm repo add srsran https://srsran.github.io/srsRAN_Project_helm/
# Get config required for installation.
sudo wget https://raw.githubusercontent.com/srsran/srsRAN_Project_helm/main/charts/linuxptp/values.yaml -O linuxptp_values.yaml
# Update the 'values.yaml' to use the available 'softwareradiosystems/linuxptp' image on docker hub.
# Since the tag 'softwareradiosystems/linuxptp:v4.4_1.2.0' is not present and the latest is available is
# 'softwareradiosystems/linuxptp:v4.4_1.1.3', update the 'values.yaml'.
# Update the interface name in 'linuxptp_values.yaml' as well.
sudo helm install ptp4l srsran/linuxptp -f linuxptp_values.yaml
```

6. Open5GS installation
```
# Get MongoDB k8s volume config.
wget https://raw.githubusercontent.com/srsran/srsRAN_Project_helm/refs/heads/main/charts/open5gs/open5gs-pv-pvc.yaml -O open5gs-pv-pvc.yaml
mkdir -p /mnt/data/vol
chown -R 1001:1001 /mnt/data/vol
sudo kubectl apply -f open5gs-pv-pvc.yaml
# Update 'open5gs-pv-pvc.yaml' to set 'storage' to the size suitable for your disk.
# Get charts for open5gs locally in 'open5gs' subdir.
sudo helm pull oci://registry-1.docker.io/gradiant/open5gs --version 2.2.5 --untar
# Make changes, if necessary, and execute the following:
sudo helm install open5gs ./open5gs -f 5gSA-values.yaml -n open5gs --create-namespace
# TODO
# Multiple pod deployments fail... images not found and some other undiagnosed errors.
# Example: MongoDB deployment fails because of image mismatch... image tag specified in chart
# '5.0.9-debian-10-r11' but not available here (https://hub.docker.com/r/bitnami/mongodb/tags).
```
