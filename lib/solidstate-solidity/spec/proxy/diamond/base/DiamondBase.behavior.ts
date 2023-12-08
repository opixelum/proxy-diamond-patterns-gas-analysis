import { describeFilter } from '@solidstate/library';
import { IDiamondBase } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

export interface DiamondBaseBehaviorArgs {
  facetFunction: string;
  facetFunctionArgs: string[];
}

export function describeBehaviorOfDiamondBase(
  deploy: () => Promise<IDiamondBase>,
  { facetFunction, facetFunctionArgs }: DiamondBaseBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::DiamondBase', function () {
    let instance: IDiamondBase;

    beforeEach(async function () {
      instance = await deploy();
    });

    describe('fallback()', function () {
      it('forwards data with matching selector call to facet', async function () {
        expect((instance as any)[facetFunction]).to.be.undefined;

        let contract = new ethers.Contract(
          instance.address,
          [`function ${facetFunction}`],
          ethers.provider,
        );

        await expect(contract.callStatic[facetFunction](...facetFunctionArgs))
          .not.to.be.reverted;
      });

      it('forwards data without matching selector to fallback contract');

      describe('reverts if', function () {
        it('no selector matches data', async function () {
          let contract = new ethers.Contract(
            instance.address,
            ['function function()'],
            ethers.provider,
          );

          await expect(
            contract.callStatic['function()'](),
          ).to.be.revertedWithCustomError(
            instance,
            'Proxy__ImplementationIsNotContract',
          );
        });
      });
    });
  });
}
