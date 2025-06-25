# DeFi Hacks Reproduce - Foundry, Web3 Security Course

**Disclaimer:** This content serves solely as a proof of concept showcasing past DeFi hacking incidents. It is strictly intended for educational purposes and should not be interpreted as encouraging or endorsing any form of illegal activities or actual hacking attempts. The provided information is for informational and learning purposes only, and any actions taken based on this content are solely the responsibility of the individual. The usage of this information should adhere to applicable laws, regulations, and ethical standards.

All credits for the templates and base PoC code goes to contributors over at https://github.com/SunWeb3Sec/DeFiHackLabs

## Getting Started

- Follow the [instructions](https://getfoundry.sh/introduction/installation) to install [Foundry](https://github.com/foundry-rs/foundry).
- Clone the existing repository with `git clone <repo_url>`

There are a total of 3 exercises here covering
1. Access Control
2. Business Logic
3. Re-entrancy 

For each of them the relevant information and instructions will be located in the _test.sol file within the folder.

Navigate to the src/test folder starting with [01_AccessControl/ROI_test.sol](src/test/01_AccessControl/ROI_test.sol) to begin

## List of DeFi Hacks & POCs

### 20220908 Ragnarok Online Invasion - Broken Access Control

#### Lost: 157.98 BNB (~44,000 US$)

Testing

```sh
forge test --match-contract ROI_exp -vvv
```

#### Contract

[ROI_exp.sol](src/test/solution/ROI_exp.sol)

#### Link reference

https://twitter.com/BlockSecTeam/status/1567746825616236544

https://twitter.com/CertiKAlert/status/1567754904663429123

https://www.panewslab.com/zh_hk/articledetails/mbzalpdi.html

https://medium.com/quillhash/decoding-ragnarok-online-invasion-44k-exploit-quillaudits-261b7e23b55

---

### 20240926 Bedrock_DeFi - Swap ETH/BTC 1/1 in mint function

### Lost: 27.83925883 BTC (~$1.7M USD)

```sh
forge test --match-contract Bedrock_DeFi_exp -vvv
```

#### Contract

[Bedrock_DeFi_exp.sol](src/test/solution/Bedrock_DeFi_exp.sol)

### Link reference

https://x.com/certikalert/status/1839403126694326374

---

### 20240903 Penpiexyz_io - Reentrancy and Reward Manipulation

### Lost: 11,113.6 ETH (~$27,348,259 USD)

```sh
forge test --match-contract Penpiexyz_io_exp -vvv --evm-version shanghai
```
#### Contract

[Penpiexyzio_exp.sol](src/test/solution/Penpiexyzio_exp.sol)

### Link reference

https://x.com/peckshield/status/1831072098669953388

https://x.com/AnciliaInc/status/1831080555292856476

https://x.com/hackenclub/status/1831383106554573099

post-morten: https://x.com/Penpiexyz_io/status/1831462760787452240

---
