import { describeFilter } from '@solidstate/library';
import { IProxy } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

export interface ProxyBehaviorArgs {
  implementationFunction: string;
  implementationFunctionArgs: any[];
}

export function describeBehaviorOfProxy(
  deploy: () => Promise<IProxy>,
  { implementationFunction, implementationFunctionArgs }: ProxyBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::Proxy', function () {
    let instance: IProxy;

    beforeEach(async function () {
      instance = await deploy();
    });

    describe('fallback', function () {
      it('forwards data to implementation', async () => {
        let contract = new ethers.Contract(
          instance.address,
          [`function ${implementationFunction}`],
          (await ethers.getSigners())[0],
        );

        await expect(
          contract.callStatic[implementationFunction](
            ...implementationFunctionArgs,
          ),
        ).not.to.be.reverted;
      });
    });
  });
}
