// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/finance/VestingWallet.sol";

contract UrutokenV2 is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    address public constant MULTISIG_OWNER = 0x21F831882d744a5CBB44DF09dA1b6C1b6d0e08b8;
    address public constant ECOSYSTEM_WALLET = 0xdCeF9Fdeddef1376DA57622077fb950adC0c624d;
    address public constant DEVELOPMENT_WALLET = 0x0171F0C69C70538b32FeD9529FA0A9D5F4ED40D1;
    address public constant TEAM_BENEFICIARY = 0x0e0667DC12961c0220cD253329a62b959F1B8187;
    address public constant LIQUIDITY_WALLET = 0x2235a11939709969563A123AEf7984Ab893A35d2;
    address public constant RESERVE_BENEFICIARY = 0xF805aEf66B224Af754Ae575B9Ed3775fdF99C6bf;
    address public constant PRESALE_TOKEN_HOLDER = 0xa31def6f8717624dDcAe985420E122251Eb9B973;

    uint64 public constant PRESALE_START_TIMESTAMP = 1779667200; // May 25, 2026 00:00 UTC
    uint64 public constant VESTING_DURATION = 1095 days; // 3 years

    uint256 public constant ECOSYSTEM_AMOUNT = 350_000_000 * 10 ** 18;
    uint256 public constant PRESALE_AMOUNT = 150_000_000 * 10 ** 18;
    uint256 public constant DEVELOPMENT_AMOUNT = 150_000_000 * 10 ** 18;
    uint256 public constant TEAM_AMOUNT = 150_000_000 * 10 ** 18;
    uint256 public constant LIQUIDITY_AMOUNT = 100_000_000 * 10 ** 18;
    uint256 public constant RESERVE_AMOUNT = 100_000_000 * 10 ** 18;

    uint256 public maxTxAmount = 5_000_000 * 10 ** 18;
    uint256 public maxWalletAmount = 20_000_000 * 10 ** 18;

    VestingWallet public immutable teamVestingWallet;
    VestingWallet public immutable reserveVestingWallet;

    mapping(address => bool) public isExcludedFromLimits;

    event AllocationMinted(string allocationName, address indexed wallet, uint256 amount);
    event ExcludedFromLimitsUpdated(address indexed wallet, bool status);
    event MaxTxUpdated(uint256 newAmount);
    event MaxWalletUpdated(uint256 newAmount);

    constructor() ERC20("Urutoken", "URU") Ownable(MULTISIG_OWNER) {
        require(PRESALE_START_TIMESTAMP >= block.timestamp, "Presale time already passed");

        teamVestingWallet = new VestingWallet(
            TEAM_BENEFICIARY,
            PRESALE_START_TIMESTAMP,
            VESTING_DURATION
        );

        reserveVestingWallet = new VestingWallet(
            RESERVE_BENEFICIARY,
            PRESALE_START_TIMESTAMP,
            VESTING_DURATION
        );

        isExcludedFromLimits[MULTISIG_OWNER] = true;
        isExcludedFromLimits[ECOSYSTEM_WALLET] = true;
        isExcludedFromLimits[DEVELOPMENT_WALLET] = true;
        isExcludedFromLimits[LIQUIDITY_WALLET] = true;
        isExcludedFromLimits[PRESALE_TOKEN_HOLDER] = true;
        isExcludedFromLimits[address(teamVestingWallet)] = true;
        isExcludedFromLimits[address(reserveVestingWallet)] = true;

        _mint(ECOSYSTEM_WALLET, ECOSYSTEM_AMOUNT);
        _mint(PRESALE_TOKEN_HOLDER, PRESALE_AMOUNT);
        _mint(DEVELOPMENT_WALLET, DEVELOPMENT_AMOUNT);
        _mint(address(teamVestingWallet), TEAM_AMOUNT);
        _mint(LIQUIDITY_WALLET, LIQUIDITY_AMOUNT);
        _mint(address(reserveVestingWallet), RESERVE_AMOUNT);

        emit AllocationMinted("Ecosystem & Utility - 35%", ECOSYSTEM_WALLET, ECOSYSTEM_AMOUNT);
        emit AllocationMinted("Presale - 15%", PRESALE_TOKEN_HOLDER, PRESALE_AMOUNT);
        emit AllocationMinted("Development & Technology - 15%", DEVELOPMENT_WALLET, DEVELOPMENT_AMOUNT);
        emit AllocationMinted("Team & Operations Vesting - 15% - 3 Years", address(teamVestingWallet), TEAM_AMOUNT);
        emit AllocationMinted("Liquidity Support - 10%", LIQUIDITY_WALLET, LIQUIDITY_AMOUNT);
        emit AllocationMinted("Strategic Reserve Vesting - 10% - 3 Years", address(reserveVestingWallet), RESERVE_AMOUNT);

        require(totalSupply() == MAX_SUPPLY, "Supply mismatch");
    }

    function setExcludedFromLimits(address wallet, bool status) external onlyOwner {
        require(wallet != address(0), "Invalid wallet");
        isExcludedFromLimits[wallet] = status;
        emit ExcludedFromLimitsUpdated(wallet, status);
    }

    function setMaxTxAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= MAX_SUPPLY / 1000, "Too low");
        maxTxAmount = newAmount;
        emit MaxTxUpdated(newAmount);
    }

    function setMaxWalletAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= MAX_SUPPLY / 1000, "Too low");
        maxWalletAmount = newAmount;
        emit MaxWalletUpdated(newAmount);
    }

    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        if (
            from != address(0) &&
            to != address(0) &&
            !isExcludedFromLimits[from] &&
            !isExcludedFromLimits[to]
        ) {
            require(amount <= maxTxAmount, "Exceeds max transaction limit");
            require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds max wallet limit");
        }

        super._update(from, to, amount);
    }
}
