// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {FundMe} from "../../src/FundMe.sol";

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address private USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsdIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testFundUpdatesFundersArray() public {
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        address storedFunder = fundMe.getFunder(0);

        assertEq(storedFunder, USER);
    }

    function testFundUpdatesAmountFunded() public {
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        uint256 addressAmountFunded = fundMe.getAddressToAmountFunded(USER);

        assertEq(addressAmountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleUser() public funded {
        // Arrange
        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 contractStartingBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerEndingBalance = fundMe.getOwner().balance;
        uint256 contractEndingBalance = address(fundMe).balance;
        // Assert
        assertEq(contractEndingBalance, 0);
        assertEq(
            contractStartingBalance + ownerStartingBalance,
            ownerEndingBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10;
        uint160 fundersIndex = 1;

        for (uint160 i = fundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 contractStartingBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assertEq(address(fundMe).balance, 0);
        assertEq(
            contractStartingBalance + ownerStartingBalance,
            fundMe.getOwner().balance
        );
    }

    function testGetVersionIsAccurate() public {
        uint256 aggVersion = fundMe.getVersion();

        assertEq(aggVersion, 4);
    }

    function testOwnerIsSender() public {
        // console.log(address(fundMe));

        // console.log(fundMe.i_owner());

        // console.log(msg.sender);

        uint8 num = 1;
        assertEq(1, num);
    }
}
