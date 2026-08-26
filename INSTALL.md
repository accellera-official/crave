# Installation Notes for the CRAVE2UVM prototype

This project contains a prototypical integration of CRAVE with UVM-SystemC to provide access to constrained randomization and coverage.
For demonstration, we ported the SystemVerilog example UBUS to UVM-SystemC and included it in this distribution.

## Requirements

Base tools:

* CMake (at least v3.20)
* GNU Make
* Ninja (recommended)
* g++ (at least v4.7.2)
* zlib development libraries (e.g. zlib1g-dev)

Dependencies (SystemC, UVM-SystemC, Boost):

You have two options:

1) **Use system installations** (recommended when downloads are restricted). Set env vars to point to your installs:
   * `BOOST_ROOT`
   * `SYSTEMC_HOME`
   * `UVM_SYSTEMC_HOME`

2) **Let CMake fetch/build them** (recommended for a clean, self-contained build):
   * Use `-DFETCH_ALL_DEPS=ON` or per-dependency flags.

## Installation

Configure with a preset, then build and install. The build directory is `build/<PRESET>`.

### Usage Examples

The default configuration enables CUDD and Z3. Additional metaSMT solver backends are optional and can be enabled with the `All` preset.

* **Default configuration (CUDD and Z3):**

  ```sh
  cmake --preset Default
  cmake --build --preset Default --target install
  ```

* **Default configuration plus optional solvers (all available metaSMT backends):**

  ```sh
  cmake --preset All
  cmake --build --preset All --target install
  ```

* **Default configuration plus optional solvers, including fetching Boost, SystemC, and UVM-SystemC:**

  ```sh
  cmake --preset All -DFETCH_ALL_DEPS=ON
  cmake --build --preset All --target install
  ```

* **Fetch prerequisites selectively:**

  * Fetch only Boost, use system SystemC/UVM-SystemC:

    ```sh
    cmake --preset All -DFETCH_BOOST=ON
    cmake --build --preset All --target install
    ```

  * Fetch only SystemC and UVM-SystemC, use system Boost:

    ```sh
    cmake --preset All -DFETCH_SYSTEMC=ON -DFETCH_UVM_SC=ON
    cmake --build --preset All --target install
    ```

  * Fetch only UVM-SystemC (use system Boost and SystemC):

    ```sh
    cmake --preset All -DFETCH_UVM_SC=ON
    cmake --build --preset All --target install
    ```

### Offline metaSMT Build

The metaSMT solver backends can be prepared on an online machine and then reused in an offline environment through `METASMT_DEPS_DIR`.
Run `metasmt-export-deps` once online to create `metasmt-deps.tar.gz`, unpack that archive on the offline machine, and configure the same preset again with `-DMETASMT_DEPS_DIR=<unpacked bundle>`.

Example:

```sh
cmake --preset All
cmake --build build/All --target metasmt-export-deps

mkdir offline_deps
tar xzf build/All/metasmt-deps.tar.gz -C offline_deps

cmake --preset All -DMETASMT_DEPS_DIR="$(realpath offline_deps)"
cmake --build build/All --target install
```

When `METASMT_DEPS_DIR` is set, all enabled metaSMT backends must be present in that directory and no backend downloads are attempted. The bundle also contains required internal build dependencies such as `help2man`, `gperf`, `boolector-*`, and `cvc4-antlr`.


### Notes

* Dependency resolution order: env var -> system search -> fetch/build.
* To force downloading/building use `-DFETCH_ALL_DEPS=ON` or per-dependency flags:
  `-DFETCH_BOOST=ON`, `-DFETCH_SYSTEMC=ON`, `-DFETCH_UVM_SC=ON`.
* When fetching UVM-SystemC, the tarball URL is controlled by `UVM_SYSTEMC_URL` (preset or `-DUVM_SYSTEMC_URL=...`).
* For CVC4 support, ensure Python’s `toml` package is installed:

  ```sh
  pip install toml
  ```

### Running Tests

Tests are registered in subdirectories of the build directory.

```sh
ctest --test-dir build/All/crave/tests
ctest --test-dir build/All/crave/metaSMT/tests
ctest --test-dir build/All/crave/examples
```

## Tested OS

This distribution has been tested on the following 64-bit Linux (x86_64) systems:

* CentOS7 gcc 7.3.0
* Rocky Linux 9.5 gcc 13.3.1

## Contact

For bug reports and feedback: <https://github.com/accellera-official/crave/issues>
