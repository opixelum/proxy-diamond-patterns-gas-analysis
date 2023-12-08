import { describeBehaviorOfERC165Base } from '../../introspection';
import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeFilter } from '@solidstate/library';
import { IERC1155Base } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { BigNumber, ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';

export interface ERC1155BaseBehaviorArgs {
  mint: (
    address: string,
    id: BigNumber,
    amount: BigNumber,
  ) => Promise<ContractTransaction>;
  burn: (
    address: string,
    id: BigNumber,
    amount: BigNumber,
  ) => Promise<ContractTransaction>;
  tokenId?: BigNumber;
}

export function describeBehaviorOfERC1155Base(
  deploy: () => Promise<IERC1155Base>,
  { mint, burn, tokenId }: ERC1155BaseBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::ERC1155Base', function () {
    let holder: SignerWithAddress;
    let spender: SignerWithAddress;
    let instance: IERC1155Base;

    before(async function () {
      [holder, spender] = await ethers.getSigners();
    });

    beforeEach(async function () {
      instance = await deploy();
    });

    // TODO: nonstandard usage
    describeBehaviorOfERC165Base(
      deploy,
      {
        interfaceIds: ['0xd9b67a26'],
      },
      skips,
    );

    describe('#balanceOf(address,uint256)', function () {
      it('returns the balance of given token held by given address', async function () {
        const id = tokenId ?? ethers.constants.Zero;
        expect(
          await instance.callStatic['balanceOf(address,uint256)'](
            holder.address,
            id,
          ),
        ).to.equal(0);

        const amount = ethers.constants.Two;
        await mint(holder.address, id, amount);

        expect(
          await instance.callStatic['balanceOf(address,uint256)'](
            holder.address,
            id,
          ),
        ).to.equal(amount);

        await burn(holder.address, id, amount);

        expect(
          await instance.callStatic['balanceOf(address,uint256)'](
            holder.address,
            id,
          ),
        ).to.equal(0);
      });

      describe('reverts if', function () {
        it('balance of zero address is queried', async function () {
          await expect(
            instance.callStatic['balanceOf(address,uint256)'](
              ethers.constants.AddressZero,
              ethers.constants.Zero,
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__BalanceQueryZeroAddress',
          );
        });
      });
    });

    describe('#balanceOfBatch(address[],uint256[])', function () {
      it('returns the balances of given tokens held by given addresses', async function () {
        expect(
          await instance.callStatic['balanceOfBatch(address[],uint256[])'](
            [holder.address],
            [ethers.constants.Zero],
          ),
        ).to.have.deep.members([ethers.constants.Zero]);
        // TODO: test delta
      });

      describe('reverts if', function () {
        it('input array lengths do not match', async function () {
          await expect(
            instance.callStatic['balanceOfBatch(address[],uint256[])'](
              [holder.address],
              [],
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__ArrayLengthMismatch',
          );
        });

        it('balance of zero address is queried', async function () {
          await expect(
            instance.callStatic['balanceOfBatch(address[],uint256[])'](
              [ethers.constants.AddressZero],
              [ethers.constants.Zero],
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__BalanceQueryZeroAddress',
          );
        });
      });
    });

    describe('#isApprovedForAll(address,address)', function () {
      it('returns whether given operator is approved to spend tokens of given account', async function () {
        expect(
          await instance.callStatic['isApprovedForAll(address,address)'](
            holder.address,
            spender.address,
          ),
        ).to.be.false;

        await instance
          .connect(holder)
          ['setApprovalForAll(address,bool)'](spender.address, true);

        expect(
          await instance.callStatic['isApprovedForAll(address,address)'](
            holder.address,
            spender.address,
          ),
        ).to.be.true;
      });
    });

    describe('#setApprovalForAll(address,bool)', function () {
      it('approves given operator to spend tokens on behalf of sender', async function () {
        await instance
          .connect(holder)
          ['setApprovalForAll(address,bool)'](spender.address, true);

        expect(
          await instance.callStatic['isApprovedForAll(address,address)'](
            holder.address,
            spender.address,
          ),
        ).to.be.true;

        // TODO: test case is no different from #isApprovedForAll test; tested further by #safeTransferFrom and #safeBatchTransferFrom tests
      });

      describe('reverts if', function () {
        it('given operator is sender', async function () {
          await expect(
            instance
              .connect(holder)
              ['setApprovalForAll(address,bool)'](holder.address, true),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__SelfApproval',
          );
        });
      });
    });

    describe('#safeTransferFrom(address,address,uint256,uint256,bytes)', function () {
      it('sends amount from A to B', async function () {
        const id = tokenId ?? ethers.constants.Zero;
        const amount = ethers.constants.Two;

        await mint(spender.address, id, amount);

        expect(
          await instance.callStatic['balanceOf(address,uint256)'](
            spender.address,
            id,
          ),
        ).to.equal(amount);

        await instance
          .connect(spender)
          ['safeTransferFrom(address,address,uint256,uint256,bytes)'](
            spender.address,
            holder.address,
            id,
            amount,
            ethers.utils.randomBytes(0),
          );

        expect(
          await instance.callStatic['balanceOf(address,uint256)'](
            spender.address,
            id,
          ),
        ).to.equal(ethers.constants.Zero);
        expect(
          await instance.callStatic['balanceOf(address,uint256)'](
            holder.address,
            id,
          ),
        ).to.equal(amount);
      });

      describe('reverts if', function () {
        it('sender has insufficient balance', async function () {
          const id = tokenId ?? ethers.constants.Zero;
          const amount = ethers.constants.Two;

          await expect(
            instance
              .connect(spender)
              ['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                spender.address,
                holder.address,
                id,
                amount,
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__TransferExceedsBalance',
          );
        });

        it('operator is not approved to act on behalf of sender', async function () {
          await expect(
            instance
              .connect(holder)
              ['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                spender.address,
                holder.address,
                ethers.constants.Zero,
                ethers.constants.Zero,
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__NotOwnerOrApproved',
          );
        });

        it('receiver is invalid ERC1155Receiver', async function () {
          const mock = await deployMockContract(holder, [
            /* no functions */
          ]);

          await expect(
            instance
              .connect(spender)
              ['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                spender.address,
                mock.address,
                ethers.constants.Zero,
                ethers.constants.Zero,
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWith('Mock on the method is not initialized');
        });

        it('receiver rejects transfer', async function () {
          const mock = await deployMockContract(holder, [
            'function onERC1155Received (address, address, uint, uint, bytes) external view returns (bytes4)',
          ]);

          await mock.mock.onERC1155Received.returns('0x00000000');

          await expect(
            instance
              .connect(spender)
              ['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                spender.address,
                mock.address,
                ethers.constants.Zero,
                ethers.constants.Zero,
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__ERC1155ReceiverRejected',
          );
        });
      });
    });

    describe('#safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)', function () {
      it('sends amount from A to B, batch version', async function () {
        const id = tokenId ?? ethers.constants.Zero;
        const amount = ethers.constants.Two;

        await mint(spender.address, id, amount);

        expect(
          await instance.callStatic['balanceOfBatch(address[],uint256[])'](
            [spender.address],
            [id],
          ),
        ).to.have.deep.members([amount]);

        await instance
          .connect(spender)
          ['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
            spender.address,
            holder.address,
            [id],
            [amount],
            ethers.utils.randomBytes(0),
          );

        expect(
          await instance.callStatic['balanceOfBatch(address[],uint256[])'](
            [spender.address],
            [id],
          ),
        ).to.have.deep.members([ethers.constants.Zero]);
        expect(
          await instance.callStatic['balanceOfBatch(address[],uint256[])'](
            [holder.address],
            [id],
          ),
        ).to.have.deep.members([amount]);
      });

      describe('reverts if', function () {
        it('sender has insufficient balance', async function () {
          const id = tokenId ?? ethers.constants.Zero;
          const amount = ethers.constants.Two;

          await expect(
            instance
              .connect(spender)
              [
                'safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'
              ](
                spender.address,
                holder.address,
                [id],
                [amount],
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__TransferExceedsBalance',
          );
        });

        it('operator is not approved to act on behalf of sender', async function () {
          await expect(
            instance
              .connect(holder)
              [
                'safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'
              ](
                spender.address,
                holder.address,
                [],
                [],
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__NotOwnerOrApproved',
          );
        });

        it('receiver is invalid ERC1155Receiver', async function () {
          const mock = await deployMockContract(holder, [
            /* no functions */
          ]);

          await expect(
            instance
              .connect(spender)
              [
                'safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'
              ](
                spender.address,
                mock.address,
                [],
                [],
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWith('Mock on the method is not initialized');
        });

        it('receiver rejects transfer', async function () {
          const mock = await deployMockContract(holder, [
            'function onERC1155BatchReceived (address, address, uint[], uint[], bytes) external view returns (bytes4)',
          ]);

          await mock.mock.onERC1155BatchReceived.returns('0x00000000');

          await expect(
            instance
              .connect(spender)
              [
                'safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'
              ](
                spender.address,
                mock.address,
                [],
                [],
                ethers.utils.randomBytes(0),
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC1155Base__ERC1155ReceiverRejected',
          );
        });
      });
    });
  });
}
