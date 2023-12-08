import {
  MockContract,
  deployMockContract,
} from '@ethereum-waffle/mock-contract';
import { describeBehaviorOfManagedProxyOwnable } from '@solidstate/spec';
import {
  ManagedProxyOwnableMock,
  ManagedProxyOwnableMock__factory,
  OwnableMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('ManagedProxyOwnable', function () {
  let manager: MockContract;
  let instance: ManagedProxyOwnableMock;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();

    manager = await deployMockContract((await ethers.getSigners())[0], [
      'function getImplementation () external view returns (address)',
    ]);

    const implementationInstance = await new OwnableMock__factory(
      deployer,
    ).deploy(deployer.address);

    await manager.mock['getImplementation()'].returns(
      implementationInstance.address,
    );

    const selector = manager.interface.getSighash('getImplementation()');

    instance = await new ManagedProxyOwnableMock__factory(deployer).deploy(
      manager.address,
      selector,
    );
  });

  describeBehaviorOfManagedProxyOwnable(async () => instance, {
    implementationFunction: 'owner()',
    implementationFunctionArgs: [],
  });

  describe('__internal', function () {
    describe('#_getImplementation()', function () {
      it('returns implementation address');

      describe('reverts if', function () {
        it('manager is non-contract address', async function () {
          await instance['setOwner(address)'](ethers.constants.AddressZero);

          await expect(instance.callStatic.__getImplementation()).to.be
            .reverted;
        });

        it('manager fails to return implementation', async function () {
          await manager.mock['getImplementation()'].revertsWithReason('ERROR');

          await expect(
            instance.callStatic.__getImplementation(),
          ).to.be.revertedWithCustomError(
            instance,
            'ManagedProxy__FetchImplementationFailed',
          );
        });
      });
    });

    describe('#_getManager()', function () {
      it('returns address of ERC173 owner', async function () {
        expect(await instance.callStatic.__getManager()).to.equal(
          await instance.callStatic['getOwner()'](),
        );
      });
    });
  });
});
