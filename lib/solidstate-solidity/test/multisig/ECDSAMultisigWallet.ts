import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeBehaviorOfECDSAMultisigWallet } from '@solidstate/spec';
import {
  ECDSAMultisigWalletMock,
  ECDSAMultisigWalletMock__factory,
} from '@solidstate/typechain-types';
import { ethers } from 'hardhat';

describe('ECDSAMultisigWallet', function () {
  const quorum = ethers.constants.One;
  let signers: SignerWithAddress[];
  let nonSigner: SignerWithAddress;
  let instance: ECDSAMultisigWalletMock;

  before(async function () {
    [nonSigner, ...signers] = (await ethers.getSigners()).slice(0, 4);
  });

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    instance = await new ECDSAMultisigWalletMock__factory(deployer).deploy(
      signers.map((s) => s.address),
      quorum,
    );
  });

  describeBehaviorOfECDSAMultisigWallet(async () => instance, {
    getSigners: async () => signers,
    getNonSigner: async () => nonSigner,
    quorum,
    getVerificationAddress: async () => instance.address,
  });

  describe('__internal', function () {
    describe('#_verifySignatures(bytes,(bytes,uint256)[])', function () {
      it('todo');
    });
  });
});
