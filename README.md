# Proxy and Diamond Patterns Gas Analysis

We will compare the gas cost of each operation (deploy, upgrade, call) for each,
and also the complexity of the code. Also, we use the
[Yul-based optimizer](https://docs.soliditylang.org/en/v0.8.21/internals/optimizer.html)
with a
[runs](https://docs.soliditylang.org/en/v0.8.21/internals/optimizer.html#optimizer-parameter-runs)
value of 2,000,000 in order to have the best gas cost possible.

IMPORTANT: here we use the smart contract development framework **Foundry**,
which runs tests on a local blockchain, which may differ a bit from the real EVM
ones. Also, new EIPs are coming, which will change the gas cost of some
operations.

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Installation

1. Clone the repo.

Using SSH:

```console
git clone ssh://git@freyja.intra.cea.fr:7222/AB272349/pattern-comparison.git
```

Using HTTPS:

```console
git clone https://freyja.intra.cea.fr/AB272349/pattern-comparison.git
```

2. Go to the repo.

```console
cd pattern-comparison
```

3. Install dependencies.

```console
forge install
```

### Usage

- Compile contracts.

```console
forge build
```

- Run tests.

```console
forge test
```

- Run tests with gas reports.

```console
forge test --gas-report
```

- Run tests with traces.

```console
forge test --vvvvv
  ```
