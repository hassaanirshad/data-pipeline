# 5GLatte attack data pipeline

This README describes how to capture OS activity for 5GLatte attack scripts, and do analysis on the captured data.

This data pipeline uses:

1. [5GLatte](https://arxiv.org/abs/2312.01681) attack scripts for running 5G attacks,
2. [SPADE](https://github.com/ashish-gehani/spade) for data collection,
3. [srsRan](https://github.com/srsRAN/srsRAN_Project.git) for 5G instance.
4. [Open5GS](https://github.com/open5gs/open5gs)
<!-- 3. [PIDSMaker](https://github.com/ubc-provenance/PIDSMaker.git) for data analysis -->

## A. Requirements

1. Ubuntu 24.04 (kernel <= 6.8.0 x86_64)
2. Memory >= 16 GB
3. Storage >= 100 GB

**Note**: It is assumed that the requirements for the repositories used have been met.

## B. Setup

### B.1. Submodules

Make sure that submodules are up-to-date.
```
pushd ./five-g/attack/5glatte
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