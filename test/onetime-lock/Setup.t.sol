// SPDX-License-Identifier: UNLICENSED
import "../../src/onetime-lock/OnetimeLockRequestDispatcher.sol";
import {TestRequestDispatcher} from "../transferWithSecret/Setup.t.sol";

contract TestOnetimeLockRequestDispatcher is TestRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    OnetimeLockRequestDispatcher internal ontimeLockDispatcher;

    function setUp() public virtual override(TestRequestDispatcher) {
        super.setUp();

        ontimeLockDispatcher = new OnetimeLockRequestDispatcher(address(permit2));
    }

    function _sign(TransferWithSecretRequest memory request, uint256 fromPrivateKey)
        internal
        view
        override(TestRequestDispatcher)
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(ontimeLockDispatcher),
            TransferWithSecretRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }
}
