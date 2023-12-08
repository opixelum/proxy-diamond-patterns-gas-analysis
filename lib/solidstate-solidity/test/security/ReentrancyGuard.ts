import { describeBehaviorOfReentrancyGuard } from '@solidstate/spec';
import {
  ReentrancyGuardMock,
  ReentrancyGuardMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('ReentrancyGuard', function () {
  let instance: ReentrancyGuardMock;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    instance = await new ReentrancyGuardMock__factory(deployer).deploy();
  });

  describeBehaviorOfReentrancyGuard(async () => instance, {});

  describe('__internal', function () {
    describe('nonReentrant() modifier', function () {
      it('does not revert non-reentrant call', async function () {
        await expect(instance['modifier_nonReentrant()']()).not.to.be.reverted;

        // test subsequent calls

        await expect(instance['modifier_nonReentrant()']()).not.to.be.reverted;

        await expect(
          instance['reentrancyTest()'](),
        ).to.be.revertedWithCustomError(
          instance,
          'ReentrancyGuard__ReentrantCall',
        );
      });

      describe('reverts if', function () {
        it('call is reentrant', async function () {
          await expect(
            instance['reentrancyTest()'](),
          ).to.be.revertedWithCustomError(
            instance,
            'ReentrancyGuard__ReentrantCall',
          );
        });

        it('call is cross-function reentrant', async function () {
          await expect(
            instance['crossFunctionReentrancyTest()'](),
          ).to.be.revertedWithCustomError(
            instance,
            'ReentrancyGuard__ReentrantCall',
          );

          // call function again with different contract state to avoid false-negative test coverage
          await instance.__lockReentrancyGuard();
          await expect(instance.crossFunctionReentrancyTest()).to.be.reverted;
        });
      });
    });

    describe('#_lockReentrancyGuard()', () => {
      it('causes nonReentrant functions to revert', async () => {
        await instance.__lockReentrancyGuard();

        await expect(
          instance.modifier_nonReentrant(),
        ).to.be.revertedWithCustomError(
          instance,
          'ReentrancyGuard__ReentrantCall',
        );
      });
    });

    describe('#_unlockReentrancyGuard()', () => {
      it('causes nonReentrant functions to pass', async () => {
        await instance.__lockReentrancyGuard();

        await instance.__unlockReentrancyGuard();

        await expect(instance.modifier_nonReentrant()).not.to.be.reverted;
      });
    });
  });
});
