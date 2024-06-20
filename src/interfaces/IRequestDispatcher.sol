// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRequestDispatcher {
    error InvalidDispatcher();
    error DeadlinePassed();
    error RequestExpired();
    error RequestAlreadyExists();
}
