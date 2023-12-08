import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeBehaviorOfERC721Base } from '@solidstate/spec';
import {
  ERC721Base,
  ERC721BaseMock,
  ERC721BaseMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('ERC721Base', function () {
  let sender: SignerWithAddress;
  let receiver: SignerWithAddress;
  let holder: SignerWithAddress;
  let spender: SignerWithAddress;
  let instance: ERC721BaseMock;

  before(async function () {
    [sender, receiver, holder, spender] = await ethers.getSigners();
  });

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    instance = await new ERC721BaseMock__factory(deployer).deploy();
  });

  describeBehaviorOfERC721Base(async () => instance, {
    supply: ethers.constants.Zero,
    mint: (recipient, tokenId) => instance.mint(recipient, tokenId),
    burn: (tokenId) => instance.burn(tokenId),
  });

  describe('__internal', function () {
    describe('#_balanceOf(address)', function () {
      it('todo');
    });

    describe('#_ownerOf(uint256)', function () {
      it('todo');
    });

    describe('#_getApproved(uint256)', function () {
      it('todo');
    });

    describe('#_isApprovedForAll(address,address)', function () {
      it('todo');
    });

    describe('#_isApprovedOrOwner(address,uint256)', function () {
      it('returns true if given spender is approved for given token', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(holder.address, tokenId);

        await instance.connect(holder).approve(spender.address, tokenId);

        expect(
          await instance.callStatic.isApprovedOrOwner(spender.address, tokenId),
        ).to.be.true;
      });

      it('returns true if given spender is approved for all tokens held by owner', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(holder.address, tokenId);

        await instance.connect(holder).setApprovalForAll(spender.address, true);

        expect(
          await instance.callStatic.isApprovedOrOwner(spender.address, tokenId),
        ).to.be.true;
      });

      it('returns true if given spender is owner of given token', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(holder.address, tokenId);

        expect(
          await instance.callStatic.isApprovedOrOwner(holder.address, tokenId),
        ).to.be.true;
      });

      it('returns false if given spender is neither owner of given token nor approved to spend it', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(holder.address, tokenId);

        expect(
          await instance.callStatic.isApprovedOrOwner(spender.address, tokenId),
        ).to.be.false;
      });

      describe('reverts if', function () {
        it('token does not exist', async function () {
          const tokenId = ethers.constants.Two;

          await expect(
            instance.callStatic.isApprovedOrOwner(
              ethers.constants.AddressZero,
              tokenId,
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__NonExistentToken',
          );
        });
      });
    });

    describe('#_mint(address,uint256)', function () {
      it('creates token with given id for given account', async function () {
        const tokenId = ethers.constants.Two;
        await expect(instance.callStatic.ownerOf(tokenId)).to.be.reverted;

        await instance.mint(holder.address, tokenId);
        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          holder.address,
        );
      });

      it('increases balance of given account by one', async function () {
        const tokenId = ethers.constants.Two;

        await expect(() =>
          instance.mint(receiver.address, tokenId),
        ).to.changeTokenBalance(instance, receiver, ethers.constants.One);
      });

      it('emits Transfer event', async function () {
        const tokenId = ethers.constants.Two;

        await expect(instance.mint(receiver.address, tokenId))
          .to.emit(instance, 'Transfer')
          .withArgs(ethers.constants.AddressZero, receiver.address, tokenId);
      });

      describe('reverts if', function () {
        it('given account is zero address', async function () {
          await expect(
            instance.mint(ethers.constants.AddressZero, ethers.constants.Zero),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__MintToZeroAddress',
          );
        });

        it('given token already exists', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(instance.address, tokenId);

          await expect(
            instance.mint(instance.address, tokenId),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__TokenAlreadyMinted',
          );
        });
      });
    });

    describe('#_safeMint(address,uint256)', function () {
      it('creates token with given id for given account', async function () {
        const tokenId = ethers.constants.Two;
        await expect(instance.callStatic.ownerOf(tokenId)).to.be.reverted;

        await instance['safeMint(address,uint256)'](holder.address, tokenId);
        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          holder.address,
        );
      });

      it('increases balance of given account by one', async function () {
        const tokenId = ethers.constants.Two;

        await expect(() =>
          instance['safeMint(address,uint256)'](receiver.address, tokenId),
        ).to.changeTokenBalance(instance, receiver, ethers.constants.One);
      });

      it('emits Transfer event', async function () {
        const tokenId = ethers.constants.Two;

        await expect(
          instance['safeMint(address,uint256)'](receiver.address, tokenId),
        )
          .to.emit(instance, 'Transfer')
          .withArgs(ethers.constants.AddressZero, receiver.address, tokenId);
      });

      it('does not revert if given account is ERC721Receiver implementer', async function () {
        const receiverContract = await deployMockContract(sender, [
          'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
        ]);

        await receiverContract.mock.onERC721Received.returns('0x150b7a02');

        await expect(
          instance['safeMint(address,uint256)'](
            receiverContract.address,
            ethers.constants.Two,
          ),
        ).not.to.be.reverted;
      });

      describe('reverts if', function () {
        it('given account is zero address', async function () {
          await expect(
            instance['safeMint(address,uint256)'](
              ethers.constants.AddressZero,
              ethers.constants.Zero,
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__MintToZeroAddress',
          );
        });

        it('given token already exists', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(instance.address, tokenId);

          await expect(
            instance['safeMint(address,uint256)'](instance.address, tokenId),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__TokenAlreadyMinted',
          );
        });

        it('recipient is not ERC721Receiver implementer', async function () {
          // TODO: test against contract other than self

          await expect(
            instance['safeMint(address,uint256)'](
              instance.address,
              ethers.constants.Two,
            ),
          ).to.be.revertedWith(
            'ERC721: transfer to non ERC721Receiver implementer',
          );
        });

        it('recipient is ERC721Receiver implementer but does not accept transfer', async function () {
          const receiverContract = await deployMockContract(sender, [
            'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
          ]);

          await receiverContract.mock.onERC721Received.returns(
            ethers.utils.randomBytes(4),
          );

          await expect(
            instance['safeMint(address,uint256)'](
              receiverContract.address,
              ethers.constants.Two,
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__ERC721ReceiverNotImplemented',
          );
        });
      });
    });

    describe('#_safeMint(address,uint256,bytes)', function () {
      it('creates token with given id for given account', async function () {
        const tokenId = ethers.constants.Two;
        await expect(instance.callStatic.ownerOf(tokenId)).to.be.reverted;

        await instance['safeMint(address,uint256,bytes)'](
          holder.address,
          tokenId,
          '0x',
        );
        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          holder.address,
        );
      });

      it('increases balance of given account by one', async function () {
        const tokenId = ethers.constants.Two;

        await expect(() =>
          instance['safeMint(address,uint256,bytes)'](
            receiver.address,
            tokenId,
            '0x',
          ),
        ).to.changeTokenBalance(instance, receiver, ethers.constants.One);
      });

      it('emits Transfer event', async function () {
        const tokenId = ethers.constants.Two;

        await expect(
          instance['safeMint(address,uint256,bytes)'](
            receiver.address,
            tokenId,
            '0x',
          ),
        )
          .to.emit(instance, 'Transfer')
          .withArgs(ethers.constants.AddressZero, receiver.address, tokenId);
      });

      it('does not revert if given account is ERC721Receiver implementer', async function () {
        const receiverContract = await deployMockContract(sender, [
          'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
        ]);

        await receiverContract.mock.onERC721Received.returns('0x150b7a02');

        await expect(
          instance['safeMint(address,uint256,bytes)'](
            receiverContract.address,
            ethers.constants.Two,
            '0x',
          ),
        ).not.to.be.reverted;
      });

      describe('reverts if', function () {
        it('given account is zero address', async function () {
          await expect(
            instance['safeMint(address,uint256,bytes)'](
              ethers.constants.AddressZero,
              ethers.constants.Zero,
              '0x',
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__MintToZeroAddress',
          );
        });

        it('given token already exists', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(instance.address, tokenId);

          await expect(
            instance['safeMint(address,uint256,bytes)'](
              instance.address,
              tokenId,
              '0x',
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__TokenAlreadyMinted',
          );
        });

        it('recipient is not ERC721Receiver implementer', async function () {
          // TODO: test against contract other than self

          await expect(
            instance['safeMint(address,uint256,bytes)'](
              instance.address,
              ethers.constants.Two,
              '0x',
            ),
          ).to.be.revertedWith(
            'ERC721: transfer to non ERC721Receiver implementer',
          );
        });

        it('recipient is ERC721Receiver implementer but does not accept transfer', async function () {
          const receiverContract = await deployMockContract(sender, [
            'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
          ]);

          await receiverContract.mock.onERC721Received.returns(
            ethers.utils.randomBytes(4),
          );

          await expect(
            instance['safeMint(address,uint256,bytes)'](
              receiverContract.address,
              ethers.constants.Two,
              '0x',
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__ERC721ReceiverNotImplemented',
          );
        });
      });
    });

    describe('#_burn(uint256)', function () {
      it('destroys given token', async function () {
        const tokenId = ethers.constants.Two;

        await instance.mint(holder.address, tokenId);
        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          holder.address,
        );

        await instance.burn(tokenId);
        await expect(instance.callStatic.ownerOf(tokenId)).to.be.reverted;
      });

      it('decreases balance of owner by one', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(receiver.address, tokenId),
          await expect(() => instance.burn(tokenId)).to.changeTokenBalance(
            instance,
            receiver,
            -ethers.constants.One,
          );
      });

      it('emits Transfer event', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(receiver.address, tokenId);

        await expect(instance['burn(uint256)'](tokenId))
          .to.emit(instance, 'Transfer')
          .withArgs(receiver.address, ethers.constants.AddressZero, tokenId);
      });
    });

    describe('#_transfer(address,address,uint256)', function () {
      it('decreases balance of sender and increases balance of recipient by one', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(sender.address, tokenId);

        await expect(() =>
          instance.transfer(sender.address, receiver.address, tokenId),
        ).to.changeTokenBalances(
          instance,
          [sender, receiver],
          [ethers.constants.NegativeOne, ethers.constants.One],
        );
      });

      it('updates owner of token', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(sender.address, tokenId);

        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          sender.address,
        );

        await instance.transfer(sender.address, receiver.address, tokenId);

        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          receiver.address,
        );
      });

      it('emits Transfer event', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(sender.address, tokenId);

        await expect(
          instance
            .connect(sender)
            .transfer(sender.address, receiver.address, tokenId),
        )
          .to.emit(instance, 'Transfer')
          .withArgs(sender.address, receiver.address, tokenId);
      });

      describe('reverts if', function () {
        it('sender is not token owner', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(sender.address, tokenId);

          await expect(
            instance
              .connect(sender)
              .transfer(ethers.constants.AddressZero, sender.address, tokenId),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__NotTokenOwner',
          );
        });

        it('receiver is the zero address', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(sender.address, tokenId);

          await expect(
            instance
              .connect(sender)
              .transfer(sender.address, ethers.constants.AddressZero, tokenId),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__TransferToZeroAddress',
          );
        });
      });
    });

    describe('#_safeTransfer(address,address,uint256,bytes)', function () {
      it('decreases balance of sender and increases balance of recipient by one', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(sender.address, tokenId);

        await expect(() =>
          instance.safeTransfer(
            sender.address,
            receiver.address,
            tokenId,
            '0x',
          ),
        ).to.changeTokenBalances(
          instance,
          [sender, receiver],
          [ethers.constants.NegativeOne, ethers.constants.One],
        );
      });

      it('updates owner of token', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(sender.address, tokenId);

        await instance.safeTransfer(
          sender.address,
          receiver.address,
          tokenId,
          '0x',
        );

        expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
          receiver.address,
        );
      });

      it('emits Transfer event', async function () {
        const tokenId = ethers.constants.Two;
        await instance.mint(sender.address, tokenId);

        await expect(
          instance
            .connect(sender)
            .safeTransfer(sender.address, receiver.address, tokenId, '0x'),
        )
          .to.emit(instance, 'Transfer')
          .withArgs(sender.address, receiver.address, tokenId);
      });

      describe('reverts if', function () {
        it('sender is not token owner', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(sender.address, tokenId);

          await expect(
            instance
              .connect(sender)
              .safeTransfer(
                ethers.constants.AddressZero,
                sender.address,
                tokenId,
                '0x',
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__NotTokenOwner',
          );
        });

        it('receiver is the zero address', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(sender.address, tokenId);

          await expect(
            instance
              .connect(sender)
              .safeTransfer(
                sender.address,
                ethers.constants.AddressZero,
                tokenId,
                '0x',
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__TransferToZeroAddress',
          );
        });

        it('recipient is not ERC721Receiver implementer', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(sender.address, tokenId);

          // TODO: test against contract other than self

          await expect(
            instance.safeTransfer(
              sender.address,
              instance.address,
              tokenId,
              '0x',
            ),
          ).to.be.revertedWith(
            'ERC721: transfer to non ERC721Receiver implementer',
          );
        });

        it('recipient is ERC721Receiver implementer but does not accept transfer', async function () {
          const tokenId = ethers.constants.Two;
          await instance.mint(sender.address, tokenId);

          const receiverContract = await deployMockContract(sender, [
            'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
          ]);

          await receiverContract.mock.onERC721Received.returns(
            ethers.utils.randomBytes(4),
          );

          await expect(
            instance.safeTransfer(
              sender.address,
              receiverContract.address,
              tokenId,
              '0x',
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'ERC721Base__ERC721ReceiverNotImplemented',
          );
        });
      });
    });

    describe('#_checkOnERC721Received(address,address,uint256,bytes)', function () {
      it('returns true if recipient is not a contract', async function () {
        expect(
          await instance.callStatic.checkOnERC721Received(
            ethers.constants.AddressZero,
            receiver.address,
            ethers.constants.Zero,
            '0x',
          ),
        ).to.be.true;
      });

      it('returns true if recipient returns IERC721Receiver interface ID', async function () {
        const receiverContract = await deployMockContract(sender, [
          'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
        ]);

        await receiverContract.mock.onERC721Received.returns('0x150b7a02');

        expect(
          await instance.callStatic.checkOnERC721Received(
            ethers.constants.AddressZero,
            receiverContract.address,
            ethers.constants.Zero,
            '0x',
          ),
        ).to.be.true;
      });

      it('returns false if recipient does not return ERC721Receiver interface id', async function () {
        const receiverContract = await deployMockContract(sender, [
          'function onERC721Received (address, address, uint256, bytes) returns (bytes4)',
        ]);

        await receiverContract.mock.onERC721Received.returns(
          ethers.utils.randomBytes(4),
        );

        expect(
          await instance.callStatic.checkOnERC721Received(
            ethers.constants.AddressZero,
            receiverContract.address,
            ethers.constants.Zero,
            '0x',
          ),
        ).to.be.false;
      });

      describe('reverts if', function () {
        it('recipient is not ERC721Receiver implementer', async function () {
          // TODO: test against contract other than self

          await expect(
            instance.callStatic.checkOnERC721Received(
              ethers.constants.AddressZero,
              instance.address,
              ethers.constants.Zero,
              '0x',
            ),
          ).to.be.revertedWith(
            'ERC721: transfer to non ERC721Receiver implementer',
          );
        });
      });
    });

    describe('#_beforeTokenTransfer(address,address,uint256)', function () {
      it('todo');
    });
  });
});
