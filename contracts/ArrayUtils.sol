pragma solidity ^0.4.24;


contract MemberListCapable {
    // function addAddress(
    //     mapping(address => uint8) ids,
    //     address[] addresses,
    //     address account
    // ) internal returns(uint8) {
    //     return ids[account] = uint8(addresses.push(account));
    // }

    // function removeAddress(
    //     mapping(address => uint8) ids,
    //     address[] addresses,
    //     address account
    // ) internal returns(uint8) {
    //     uint8 id = ids[account];
    //     uint8 index = id - 1;
    //     if (index >= addresses.length) return;

    //     delete addresses[index];

    //     if (index > 0) {
    //         address lastAccount = addresses[addresses.length - 1];
    //         addresses[index] = lastAccount;
    //     }

    //     addresses.length--;

    //     return id;
    // }
}
