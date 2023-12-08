import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { describeBehaviorOfUpgradeableProxy } from '@solidstate/spec';
import {
  UpgradeableProxyMock,
  UpgradeableProxyMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('UpgradeableProxy', function () {
  let instance: UpgradeableProxyMock;

  beforeEach(async function () {
    const implementationFactory = await ethers.getContractFactory(
      'OwnableMock',
    );
    const implementationInstance = await implementationFactory.deploy(
      ethers.constants.AddressZero,
    );
    await implementationInstance.deployed();

    const [deployer] = await ethers.getSigners();
    instance = await new UpgradeableProxyMock__factory(deployer).deploy(
      implementationInstance.address,
    );
  });

  describeBehaviorOfUpgradeableProxy(async () => instance, {
    implementationFunction: 'owner()',
    implementationFunctionArgs: [],
  });

  describe('__internal', function () {
    describe('#_getImplementation()', function () {
      it('returns implementation address', async function () {
        expect(await instance.callStatic.__getImplementation()).to.be
          .properAddress;
      });
    });

    describe('#_setImplementation(address)', function () {
      it('updates implementation address', async function () {
        const address = instance.address;

        expect(await instance.callStatic.__getImplementation()).not.to.equal(
          address,
        );

        await instance.__setImplementation(address);

        expect(await instance.callStatic.__getImplementation()).to.equal(
          address,
        );
      });
    });
  });
});
