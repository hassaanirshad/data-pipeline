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

Install dependencies:
```
sudo apt-get install cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev ccache
```

Install srsRAN:
```
pushd srsRAN_Project

git checkout tags/release_25_10

mkdir build
pushd build
cmake ../
make -j $(nproc)
mkdir install
make install DESTDIR=${PWD}/install
export PATH="${PWD}/install/usr/local/bin:${PATH}"
popd
popd
```

### B.5. Open5GS

Install for your Ubuntu release by following the steps [here](https://open5gs.org/open5gs/docs/guide/02-building-open5gs-from-sources/).