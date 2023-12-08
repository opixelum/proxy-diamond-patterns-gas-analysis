import { PANIC_CODES } from '@nomicfoundation/hardhat-chai-matchers/panic';
import {
  UintUtilsMock,
  UintUtilsMock__factory,
} from '@solidstate/typechain-types';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('UintUtils', function () {
  let instance: UintUtilsMock;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    instance = await new UintUtilsMock__factory(deployer).deploy();
  });

  describe('__internal', function () {
    describe('#add(uint256,int256)', function () {
      it('adds unsigned and signed integers', async () => {
        expect(await instance.callStatic.add(1, 1)).to.equal(2);
        expect(await instance.callStatic.add(1, -1)).to.equal(0);
      });

      describe('reverts if', () => {
        it('signed integer is negative and has absolute value greater than unsigned integer', async () => {
          await expect(instance.callStatic.add(0, -1)).to.be.revertedWithPanic(
            PANIC_CODES.ARITHMETIC_UNDER_OR_OVERFLOW,
          );
        });
      });
    });

    describe('#sub(uint256,int256)', function () {
      it('subtracts unsigned and signed integers', async () => {
        expect(await instance.callStatic.sub(1, 1)).to.equal(0);
        expect(await instance.callStatic.sub(1, -1)).to.equal(2);
      });

      describe('reverts if', () => {
        it('signed integer is negative and has absolute value greater than unsigned integer', async () => {
          await expect(instance.callStatic.sub(0, 1)).to.be.revertedWithPanic(
            PANIC_CODES.ARITHMETIC_UNDER_OR_OVERFLOW,
          );
        });
      });
    });

    describe('#toString(uint256)', function () {
      it('returns base-10 string representation of number', async function () {
        for (let i = 0; i < 12; i++) {
          const string = i.toString();
          const number = ethers.BigNumber.from(string);
          expect(
            await instance.callStatic['toString(uint256)'](number),
          ).to.equal(string);
        }

        expect(
          await instance.callStatic['toString(uint256)'](
            ethers.constants.MaxUint256,
          ),
        ).to.equal(ethers.constants.MaxUint256.toString());
      });
    });

    describe('#toHexString(uint256)', function () {
      it('returns 0 if input is 0', async () => {
        expect(
          await instance.callStatic['toHexString(uint256)'](
            ethers.constants.Zero,
          ),
        ).to.equal('0x00');
      });

      it('returns correct hexadecimal string representation of a number', async () => {
        const inputValues = ['1000', '1', '12345', '85746201361230', '999983'];
        const outputValues = [
          '0x03e8',
          '0x01',
          '0x3039',
          '0x4dfc57df7b4e',
          '0x0f422f',
        ];
        for (let i = 0; i < inputValues.length; i++) {
          expect(
            await instance.callStatic['toHexString(uint256)'](
              ethers.BigNumber.from(inputValues[i]),
            ),
          ).to.equal(outputValues[i]);
        }
      });
    });

    describe('#toHexString(uint256,uint256)', function () {
      it('returns hexadecimal string representation for matching value and length pairs', async () => {
        const inputValues = ['1000', '1', '12345', '85746201361230', '999983'];
        const inputLengths = ['2', '1', '2', '6', '3'];
        const outputValues = [
          '0x03e8',
          '0x01',
          '0x3039',
          '0x4dfc57df7b4e',
          '0x0f422f',
        ];

        for (let i = 0; i < inputValues.length; i++) {
          expect(
            await instance.callStatic['toHexString(uint256,uint256)'](
              ethers.BigNumber.from(inputValues[i]),
              ethers.BigNumber.from(inputLengths[i]),
            ),
          ).to.equal(outputValues[i]);
        }
      });

      describe('reverts if', () => {
        it('length input is 0 and value is nonzero', async () => {
          await expect(
            instance.callStatic['toHexString(uint256,uint256)'](
              ethers.BigNumber.from('100'),
              ethers.constants.Zero,
            ),
          ).to.be.revertedWithCustomError(
            instance,
            'UintUtils__InsufficientHexLength',
          );
        });
      });
    });
  });
});
