import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeFilter } from '@solidstate/library';
import { IERC20Extended } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { BigNumber, ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';

export interface ERC20ExtendedBehaviorArgs {
  mint: (address: string, amount: BigNumber) => Promise<ContractTransaction>;
  burn: (address: string, amount: BigNumber) => Promise<ContractTransaction>;
  allowance: (holder: string, spender: string) => Promise<BigNumber>;
  supply: BigNumber;
}

export function describeBehaviorOfERC20Extended(
  deploy: () => Promise<IERC20Extended>,
  { mint, burn, allowance, supply }: ERC20ExtendedBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::ERC20Extended', function () {
    let deployer: SignerWithAddress;
    let holder: SignerWithAddress;
    let spender: SignerWithAddress;
    let instance: IERC20Extended;

    before(async function () {
      [deployer, holder, spender] = await ethers.getSigners();
    });

    beforeEach(async function () {
      instance = await deploy();
    });

    describe('#increaseAllowance(address,uint256)', function () {
      it('returns true', async () => {
        expect(
          await instance
            .connect(holder)
            .callStatic['increaseAllowance(address,uint256)'](
              instance.address,
              ethers.constants.Zero,
            ),
        ).to.be.true;
      });

      it('increases approval of spender with respect to holder by given amount', async function () {
        let amount = ethers.constants.Two;

        await instance
          .connect(holder)
          ['increaseAllowance(address,uint256)'](spender.address, amount);

        await expect(await allowance(holder.address, spender.address)).to.equal(
          amount,
        );

        await instance
          .connect(holder)
          ['increaseAllowance(address,uint256)'](spender.address, amount);

        await expect(await allowance(holder.address, spender.address)).to.equal(
          amount.add(amount),
        );

        // TODO: test case is no different from #allowance test; tested further by #transferFrom tests
      });

      it('emits Approval event', async function () {
        let amount = ethers.constants.Two;

        await expect(
          instance
            .connect(holder)
            ['increaseAllowance(address,uint256)'](spender.address, amount),
        )
          .to.emit(instance, 'Approval')
          .withArgs(holder.address, spender.address, amount);
      });

      describe('reverts if', function () {
        it('approval amount overflows uint256', async function () {
          await instance
            .connect(holder)
            ['increaseAllowance(address,uint256)'](
              spender.address,
              ethers.constants.MaxUint256,
            );

          await expect(
            instance
              .connect(holder)
              ['increaseAllowance(address,uint256)'](
                spender.address,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC20Extended__ExcessiveAllowance',
          );
        });
      });
    });

    describe('#decreaseAllowance(address,uint256)', function () {
      it('returns true', async () => {
        expect(
          await instance
            .connect(holder)
            .callStatic['decreaseAllowance(address,uint256)'](
              instance.address,
              ethers.constants.Zero,
            ),
        ).to.be.true;
      });

      it('decreases approval of spender with respect to holder by given amount', async function () {
        let amount = ethers.constants.Two;
        await instance
          .connect(holder)
          ['increaseAllowance(address,uint256)'](
            spender.address,
            amount.mul(ethers.constants.Two),
          );

        await instance
          .connect(holder)
          ['decreaseAllowance(address,uint256)'](spender.address, amount);

        await expect(await allowance(holder.address, spender.address)).to.equal(
          amount,
        );

        await instance
          .connect(holder)
          ['decreaseAllowance(address,uint256)'](spender.address, amount);

        await expect(await allowance(holder.address, spender.address)).to.equal(
          ethers.constants.Zero,
        );

        // TODO: test case is no different from #allowance test; tested further by #transferFrom tests
      });

      it('emits Approval event', async function () {
        let amount = ethers.constants.Two;
        await instance
          .connect(holder)
          ['increaseAllowance(address,uint256)'](spender.address, amount);

        await expect(
          instance
            .connect(holder)
            ['decreaseAllowance(address,uint256)'](spender.address, amount),
        )
          .to.emit(instance, 'Approval')
          .withArgs(holder.address, spender.address, ethers.constants.Zero);
      });

      describe('reverts if', function () {
        it('approval amount underflows uint256', async function () {
          await expect(
            instance
              .connect(holder)
              ['decreaseAllowance(address,uint256)'](
                spender.address,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC20Base__InsufficientAllowance',
          );
        });
      });
    });
  });
}
