// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./interfaces/IUniswapV3.sol";

contract UniV3Helper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    struct Tick {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        int24 index; // tick index
    }

    function getTicks(IUniswapV3 pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        (,int24 tick,,,,,) = pool.slot0();

        int24 fromTick = tick - (tickSpacing * tickRange);
        int24 toTick = tick + (tickSpacing * tickRange);
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / tickSpacing)));

        uint256 counter = 0;
        for (int24 tickNum = (fromTick / tickSpacing * tickSpacing); tickNum <=  (toTick / tickSpacing * tickSpacing); tickNum += (256 * tickSpacing)) {
            int16 pos = int16((tickNum / tickSpacing) >> 8);
            uint256 bm = pool.tickBitmap(pos);

             while (bm != 0) {
                 uint8 bit = _mostSignificantBit(bm);
                 initTicks[counter] = (int24(pos) * 256 + int24(uint24(bit))) * tickSpacing;

                 counter += 1;
                 bm ^= 1 << bit;
             }

        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                uint256 feeGrowthOutside0X128,
                uint256 feeGrowthOutside1X128
                , // int56 tickCumulativeOutside,
                , // secondsPerLiquidityOutsideX128
                , // uint32 secondsOutside
                , // init
            ) = pool.ticks(initTicks[i]);

             ticks[i] = abi.encodePacked(
                 liquidityGross,
                 liquidityNet,
                 feeGrowthOutside0X128,
                 feeGrowthOutside1X128,
                 // tickCumulativeOutside,
                 // secondsPerLiquidityOutsideX128,
                 // secondsOutside,
                 initTicks[i]
             );
        }
    }

    function _mostSignificantBit(uint256 x) private pure returns (uint8 r) {
        require(x > 0, "x is 0");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}
