// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GiftCardStorage.sol";

/**
 * @title GiftCardACL
 * @dev This contract is used to manage the access control list (ACL) of the gift card.
 * It is used to manage the admins and the card owners.
 */
contract GiftCardACL is GiftCardStorage {
    mapping(address => bool) internal admins;

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Not an admin");
        _;
    }

    modifier onlyCardOwner(uint256 _id) {
        require(ownerOf(_id) == msg.sender, "Not the owner");
        _;
    }

    function isAdmin() public view returns (bool) {
        return admins[msg.sender] == true;
    }

/**
     * @dev Function for the contract owner to add a new admin
     * @param _admin The address of the new admin
     */
    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    /**
     * @dev Function for the contract owner to remove an admin
     * @param _admin The address of the admin to remove
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    address public contractOwner;

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not the contract owner");
        _;
    }
}