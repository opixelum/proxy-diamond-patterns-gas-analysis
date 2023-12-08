import {
  describeBehaviorOfOwnable,
  OwnableBehaviorArgs,
} from './Ownable.behavior';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeFilter } from '@solidstate/library';
import { ISafeOwnable } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'ethers';

export interface SafeOwnableBehaviorArgs extends OwnableBehaviorArgs {
  getNomineeOwner: () => Promise<SignerWithAddress>;
}

export function describeBehaviorOfSafeOwnable(
  deploy: () => Promise<ISafeOwnable>,
  { getOwner, getNomineeOwner, getNonOwner }: SafeOwnableBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::SafeOwnable', function () {
    let instance: ISafeOwnable;
    let owner: SignerWithAddress;
    let nomineeOwner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    beforeEach(async function () {
      instance = await deploy();
      owner = await getOwner();
      nomineeOwner = await getNomineeOwner();
      nonOwner = await getNonOwner();
    });

    describeBehaviorOfOwnable(
      deploy,
      {
        getOwner,
        getNonOwner,
      },
      ['#transferOwnership(address)', ...(skips ?? [])],
    );

    describe('#nomineeOwner()', function () {
      it('returns address of nominee owner', async function () {
        expect(await instance.callStatic['nomineeOwner()']()).to.equal(
          ethers.constants.AddressZero,
        );
        await instance
          .connect(owner)
          ['transferOwnership(address)'](nomineeOwner.address);
        expect(await instance.callStatic['nomineeOwner()']()).to.equal(
          nomineeOwner.address,
        );
      });
    });

    describe('#transferOwnership(address)', function () {
      it('does not set new owner', async function () {
        await instance
          .connect(owner)
          ['transferOwnership(address)'](nomineeOwner.address);
        expect(await instance.callStatic['owner()']()).to.equal(owner.address);
      });

      describe('reverts if', function () {
        it('sender is not owner', async function () {
          await expect(
            instance
              .connect(nonOwner)
              ['transferOwnership(address)'](nonOwner.address),
          ).to.be.revertedWithCustomError(instance, 'Ownable__NotOwner');
        });
      });
    });

    describe('#acceptOwnership()', function () {
      it('sets new owner', async function () {
        await instance
          .connect(owner)
          ['transferOwnership(address)'](nomineeOwner.address);

        await instance.connect(nomineeOwner)['acceptOwnership()']();
        expect(await instance.callStatic['owner()']()).to.equal(
          nomineeOwner.address,
        );
      });

      it('emits OwnershipTransferred event', async function () {
        await instance
          .connect(owner)
          ['transferOwnership(address)'](nomineeOwner.address);

        await expect(instance.connect(nomineeOwner)['acceptOwnership()']())
          .to.emit(instance, 'OwnershipTransferred')
          .withArgs(owner.address, nomineeOwner.address);
      });
    });

    describe('reverts if', function () {
      it('sender is not nominee owner', async function () {
        await expect(
          instance.connect(nonOwner)['acceptOwnership()'](),
        ).to.be.revertedWithCustomError(
          instance,
          'SafeOwnable__NotNomineeOwner',
        );
      });
    });
  });
}
