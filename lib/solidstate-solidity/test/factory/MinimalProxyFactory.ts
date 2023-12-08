import { describeBehaviorOfMinimalProxyFactory } from '@solidstate/spec';
import {
  MinimalProxyFactoryMock,
  MinimalProxyFactoryMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('MinimalProxyFactory', function () {
  let instance: MinimalProxyFactoryMock;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    instance = await new MinimalProxyFactoryMock__factory(deployer).deploy();
  });

  describeBehaviorOfMinimalProxyFactory(async () => instance, {});

  describe('__internal', function () {
    describe('#_deployMinimalProxy(address)', function () {
      it('deploys minimal proxy and returns deployment address', async function () {
        const target = instance.address;

        const address = await instance.callStatic[
          '__deployMinimalProxy(address)'
        ](target);
        expect(address).to.be.properAddress;

        await instance['__deployMinimalProxy(address)'](target);

        expect(await ethers.provider.getCode(address)).to.equal(
          '0x' +
            [
              '363d3d373d3d3d363d73',
              target.replace('0x', '').toLowerCase(),
              '5af43d82803e903d91602b57fd5bf3',
            ].join(''),
        );
      });

      describe('reverts if', function () {
        it('contract creation fails');
      });
    });

    describe('#_deployMinimalProxy(address,bytes32)', function () {
      it('deploys minimal proxy and returns deployment address', async function () {
        const target = instance.address;
        const salt = ethers.utils.randomBytes(32);

        const address = await instance.callStatic[
          '__deployMinimalProxy(address,bytes32)'
        ](target, salt);
        expect(address).to.be.properAddress;

        await instance['__deployMinimalProxy(address,bytes32)'](target, salt);

        expect(await ethers.provider.getCode(address)).to.equal(
          '0x' +
            [
              '363d3d373d3d3d363d73',
              target.replace('0x', '').toLowerCase(),
              '5af43d82803e903d91602b57fd5bf3',
            ].join(''),
        );
      });

      describe('reverts if', function () {
        it('contract creation fails');

        it('salt has already been used', async function () {
          const target = instance.address;
          const salt = ethers.utils.randomBytes(32);

          await instance['__deployMinimalProxy(address,bytes32)'](target, salt);

          await expect(
            instance['__deployMinimalProxy(address,bytes32)'](target, salt),
          ).to.be.revertedWithCustomError(
            instance,
            'Factory__FailedDeployment',
          );
        });
      });
    });

    describe('#_calculateMinimalProxyDeploymentAddress(address,bytes32)', function () {
      it('returns address of not-yet-deployed contract', async function () {
        const target = instance.address;
        const initCode =
          await instance.callStatic.__generateMinimalProxyInitCode(target);
        const initCodeHash = ethers.utils.keccak256(initCode);
        const salt = ethers.utils.randomBytes(32);

        expect(
          await instance.callStatic.__calculateMinimalProxyDeploymentAddress(
            target,
            salt,
          ),
        ).to.equal(ethers.utils.getCreate2Address(target, salt, initCodeHash));
      });
    });

    describe('#_generateMinimalProxyInitCode(address)', function () {
      it('returns packed encoding of initialization code prefix, target address, and initialization code suffix', async function () {
        const target = instance.address;
        const initCode =
          await instance.callStatic.__generateMinimalProxyInitCode(target);

        expect(initCode).to.equal(
          '0x' +
            [
              '3d602d80600a3d3981f3363d3d373d3d3d363d73',
              target.replace('0x', '').toLowerCase(),
              '5af43d82803e903d91602b57fd5bf3',
            ].join(''),
        );
      });
    });
  });
});
