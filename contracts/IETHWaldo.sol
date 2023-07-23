// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IETHWaldo {
    function setReadyToRelease(uint256 _dealId, uint256 _views) external;
}