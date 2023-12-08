import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { describeFilter, signData } from '@solidstate/library';
import { IECDSAMultisigWallet } from '@solidstate/typechain-types';
import { expect } from 'chai';
import { BigNumber, BigNumberish, BytesLike } from 'ethers';
import { ethers } from 'hardhat';

let currentNonce = ethers.constants.Zero;

const nextNonce = function () {
  currentNonce = currentNonce.add(ethers.constants.One);
  return currentNonce;
};

interface SignAuthorizationArgs {
  target: string;
  data: BytesLike;
  value: BigNumberish;
  delegate: boolean;
  nonce: BigNumberish;
  address: any;
}

interface Signature {
  data: Uint8Array;
  nonce: BigNumber;
}

const signAuthorization = async function (
  signer: SignerWithAddress,
  { target, data, value, delegate, nonce, address }: SignAuthorizationArgs,
) {
  return signData(signer, {
    values: [target, data, value, delegate],
    types: ['address', 'bytes', 'uint256', 'bool'],
    nonce,
    address,
  });
};

export interface ECDSAMultisigWalletBehaviorArgs {
  getSigners: () => Promise<SignerWithAddress[]>;
  getNonSigner: () => Promise<SignerWithAddress>;
  quorum: BigNumber;
  getVerificationAddress: () => Promise<string>;
}

export function describeBehaviorOfECDSAMultisigWallet(
  deploy: () => Promise<IECDSAMultisigWallet>,
  {
    getSigners,
    getNonSigner,
    quorum,
    getVerificationAddress,
  }: ECDSAMultisigWalletBehaviorArgs,
  skips?: string[],
) {
  const describe = describeFilter(skips);

  describe('::ECDSAMultisigWallet', function () {
    let instance: IECDSAMultisigWallet;
    let signers: SignerWithAddress[];
    let nonSigner: SignerWithAddress;

    let verificationAddress: string;

    before(async function () {
      signers = await getSigners();
      nonSigner = await getNonSigner();

      expect(quorum).to.be.at.least(1);
      expect(signers.length).to.be.at.least(quorum);
    });

    beforeEach(async function () {
      instance = await deploy();
      verificationAddress = await getVerificationAddress();
    });

    describe('receive()', function () {
      it('accepts ether transfer', async function () {
        let [signer] = signers;
        let value = ethers.constants.One;

        await expect(() =>
          signer.sendTransaction({ to: instance.address, value }),
        ).to.changeEtherBalance(instance, value);
      });
    });

    describe('#verifyAndExecute((address,bytes,uint256,bool),(bytes,uint256))', function () {
      describe('with "call" opcode', function () {
        let delegate = false;

        it('calls function on target address');

        it('transfers value to target address', async function () {
          let mock = await deployMockContract(signers[0], [
            'function fn () external payable returns (bool)',
          ]);

          await mock.mock.fn.returns(true);

          let target = mock.address;
          const { data } = (await mock.populateTransaction.fn()) as {
            data: BytesLike;
          };
          let value = ethers.constants.One;
          let signatures: Signature[] = [];

          for (let signer of signers) {
            let nonce = nextNonce();
            let sig = await signAuthorization(signer, {
              target,
              data,
              value,
              delegate,
              nonce,
              address: verificationAddress,
            });

            signatures.push({ data: sig, nonce });
          }

          // the changeEtherBalances matcher requires a getAddress function to work
          const addressableMock = { getAddress: () => mock.address };

          await expect(() =>
            instance.verifyAndExecute(
              { target, data, value, delegate },
              signatures,
              { value },
            ),
          ).to.changeEtherBalances([addressableMock, instance], [value, 0]);
        });

        it('forwards return data from called function', async function () {
          let mock = await deployMockContract(signers[0], [
            'function fn () external payable returns (bool)',
          ]);

          await mock.mock.fn.returns(true);

          let target = mock.address;
          const { data } = (await mock.populateTransaction.fn()) as {
            data: BytesLike;
          };
          let value = ethers.constants.Zero;
          let signatures: Signature[] = [];

          for (let signer of signers) {
            let nonce = nextNonce();
            let sig = await signAuthorization(signer, {
              target,
              data,
              value,
              delegate,
              nonce,
              address: verificationAddress,
            });

            signatures.push({ data: sig, nonce });
          }

          expect(
            ethers.utils.defaultAbiCoder.decode(
              mock.interface.functions['fn()'].outputs ?? [],
              await instance.callStatic.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            )[0],
          ).to.be.true;
        });

        describe('reverts if', function () {
          it('target contract reverts', async function () {
            let mock = await deployMockContract(signers[0], [
              'function fn () external payable returns (bool)',
            ]);

            await mock.mock.fn.returns(true);

            let reason = 'revert: reason';
            await mock.mock.fn.revertsWithReason(reason);

            let target = mock.address;
            const { data } = (await mock.populateTransaction.fn()) as {
              data: BytesLike;
            };
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.callStatic.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWith(reason);
          });

          it('quorum is not reached', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers.concat([signers[0]])) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures.slice(0, quorum.toNumber() - 1),
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__QuorumNotReached',
            );
          });

          it('duplicate signer is found', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers.concat([signers[0]])) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__SignerAlreadySigned',
            );
          });

          it('recovered signer is not authorized', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers.concat([nonSigner])) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__RecoveredSignerNotAuthorized',
            );
          });

          it('nonce has been used', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await instance.verifyAndExecute(
              { target, data, value, delegate },
              signatures,
              { value },
            );

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__InvalidNonce',
            );
          });
        });
      });

      describe('with "delegatecall" opcode', function () {
        let delegate = true;

        it('delegatecalls function on target address');

        it('does not transfer value to target address', async function () {
          let receiver = new ethers.VoidSigner(
            ethers.constants.AddressZero,
            ethers.provider,
          );

          let target = receiver.address;
          let data = ethers.utils.randomBytes(0);
          let value = ethers.constants.One;
          let signatures: Signature[] = [];

          for (let signer of signers) {
            let nonce = nextNonce();
            let sig = await signAuthorization(signer, {
              target,
              data,
              value,
              delegate,
              nonce,
              address: verificationAddress,
            });

            signatures.push({ data: sig, nonce });
          }

          await expect(async function () {
            return instance.verifyAndExecute(
              { target, data, value, delegate },
              signatures,
              { value },
            );
          }).to.changeEtherBalances([receiver, instance], [0, value]);
        });

        it('forwards return data from called function', async function () {
          // TODO: test non-empty return data
          let target = ethers.constants.AddressZero;
          let data = ethers.utils.randomBytes(0);
          let value = ethers.constants.Zero;
          let signatures: Signature[] = [];

          for (let signer of signers) {
            let nonce = nextNonce();
            let sig = await signAuthorization(signer, {
              target,
              data,
              value,
              delegate,
              nonce,
              address: verificationAddress,
            });

            signatures.push({ data: sig, nonce });
          }

          expect(
            await instance.callStatic.verifyAndExecute(
              { target, data, value, delegate },
              signatures,
              { value },
            ),
          ).to.equal('0x');
        });

        describe('reverts if', function () {
          it('target contract reverts', async function () {
            let mock = await deployMockContract(signers[0], [
              'function fn () external payable returns (bool)',
            ]);

            let target = mock.address;
            const { data } = (await mock.populateTransaction.fn()) as {
              data: BytesLike;
            };
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            // revert message depends on waffle mock implementation

            await expect(
              instance.verifyAndExecute(
                { target, data, value: ethers.constants.Zero, delegate: true },
                signatures,
                {
                  value,
                },
              ),
            ).to.be.revertedWith('Mock on the method is not initialized');
          });

          it('quorum is not reached', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers.concat([signers[0]])) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures.slice(0, quorum.toNumber() - 1),
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__QuorumNotReached',
            );
          });

          it('duplicate signer is found', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers.concat([signers[0]])) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__SignerAlreadySigned',
            );
          });

          it('recovered signer is not authorized', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers.concat([nonSigner])) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__RecoveredSignerNotAuthorized',
            );
          });

          it('message value is incorrect', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                {
                  value: value.add(ethers.constants.One),
                },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__MessageValueMismatch',
            );
          });

          it('nonce has been used', async function () {
            let target = ethers.constants.AddressZero;
            let data = ethers.utils.randomBytes(32);
            let value = ethers.constants.Zero;
            let signatures: Signature[] = [];

            for (let signer of signers) {
              let nonce = nextNonce();
              let sig = await signAuthorization(signer, {
                target,
                data,
                value,
                delegate,
                nonce,
                address: verificationAddress,
              });

              signatures.push({ data: sig, nonce });
            }

            await instance.verifyAndExecute(
              { target, data, value, delegate },
              signatures,
              { value },
            );

            await expect(
              instance.verifyAndExecute(
                { target, data, value, delegate },
                signatures,
                { value },
              ),
            ).to.be.revertedWithCustomError(
              instance,
              'ECDSAMultisigWallet__InvalidNonce',
            );
          });
        });
      });
    });
  });
}
