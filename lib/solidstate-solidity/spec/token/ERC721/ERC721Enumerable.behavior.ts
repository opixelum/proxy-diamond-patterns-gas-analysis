import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeFilter } from '@solidstate/library';
import { ERC721Enumerable } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { BigNumber, ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';

export interface ERC721EnumerableBehaviorArgs {
  mint: (address: string, tokenId: BigNumber) => Promise<ContractTransaction>;
  burn: (tokenId: BigNumber) => Promise<ContractTransaction>;
  supply: BigNumber;
}

export function describeBehaviorOfERC721Enumerable(
  deploy: () => Promise<ERC721Enumerable>,
  { mint, burn, supply }: ERC721EnumerableBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::ERC721Enumerable', function () {
    let instance: ERC721Enumerable;

    beforeEach(async function () {
      instance = await deploy();
    });

    describe('#totalSupply()', function () {
      it('returns total token supply', async function () {
        expect(await instance.totalSupply()).to.equal(supply);

        await mint(instance.address, ethers.constants.Two);
        expect(await instance.totalSupply()).to.equal(
          supply.add(ethers.constants.One),
        );

        await burn(ethers.constants.Two);
        expect(await instance.totalSupply()).to.equal(supply);
      });
    });

    describe('#tokenOfOwnerByIndex(address,uint256)', function () {
      it('returns token id held by given account at given index', async function () {
        // TODO: query balance to determine starting index

        await expect(
          instance.callStatic.tokenOfOwnerByIndex(
            instance.address,
            ethers.constants.Zero,
          ),
        ).to.be.revertedWithCustomError(
          instance,
          'EnumerableSet__IndexOutOfBounds',
        );

        await expect(
          instance.callStatic.tokenOfOwnerByIndex(
            instance.address,
            ethers.constants.One,
          ),
        ).to.be.revertedWithCustomError(
          instance,
          'EnumerableSet__IndexOutOfBounds',
        );

        await mint(instance.address, ethers.constants.One);
        await mint(instance.address, ethers.constants.Two);

        expect(
          await instance.callStatic.tokenOfOwnerByIndex(
            instance.address,
            ethers.constants.Zero,
          ),
        ).to.equal(ethers.constants.One);

        expect(
          await instance.callStatic.tokenOfOwnerByIndex(
            instance.address,
            ethers.constants.One,
          ),
        ).to.equal(ethers.constants.Two);
      });
    });

    describe('#tokenByIndex(uint256)', function () {
      it('returns token id held globally at given index', async function () {
        const index = await instance.callStatic.totalSupply();

        await expect(
          instance.callStatic.tokenByIndex(index.add(ethers.constants.Zero)),
        ).to.be.revertedWithCustomError(
          instance,
          'EnumerableMap__IndexOutOfBounds',
        );

        await expect(
          instance.callStatic.tokenByIndex(index.add(ethers.constants.One)),
        ).to.be.revertedWithCustomError(
          instance,
          'EnumerableMap__IndexOutOfBounds',
        );

        // TODO: mint to different addresses
        await mint(instance.address, ethers.constants.One);
        await mint(instance.address, ethers.constants.Two);

        expect(
          await instance.callStatic.tokenByIndex(
            index.add(ethers.constants.Zero),
          ),
        ).to.equal(ethers.constants.One);

        expect(
          await instance.callStatic.tokenByIndex(
            index.add(ethers.constants.One),
          ),
        ).to.equal(ethers.constants.Two);
      });
    });
  });
}
