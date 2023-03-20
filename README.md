## 简介

BNBHero 学员项目 ERC20 代币及流动性挖矿

## 文件介绍

- 1_RewardToken.sol
  奖励代币合约，为流动性提供者提供奖励
- 2_StakeToken.sol
  质押代币
- 3_Stake.sol
  流动性挖矿合约

## 部署步骤

- 1、部署 StakeToken 和 RewardToken 两个代币合约。
- 2、部署 Stake 合约，并传入参数(质押代币合约地址,奖励代币合约地址,每秒奖励数量)。
- 3、调用 RewardToken 的 TransferOwnership 方法，并传入参数(流动性挖矿合约的地址)，让流动性挖矿合约拥有 mint 代币的权力。
