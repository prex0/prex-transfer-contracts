import {Test} from "forge-std/Test.sol";
import "permit2/src/interfaces/IPermit2.sol";
import {Permit2} from "permit2/src/Permit2.sol";
import {TransferRequest, TransferRequestLib} from "src/transfer/TransferRequest.sol";
import {TransferRequestDispatcher} from "src/transfer/TransferRequestDispatcher.sol";
import {MockERC20} from "../MockERC20.sol";
import {TestUtils} from "../TestUtils.sol";

contract TestTransferRequestDispatcher is TestUtils {
    using TransferRequestLib for TransferRequest;

    TransferRequestDispatcher internal dispatcher;
    Permit2 permit2;
    bytes32 DOMAIN_SEPARATOR;
    MockERC20 token;

    uint256 internal privateKey = 12345;
    uint256 internal privateKey2 = 32156;
    uint256 internal recipientKey = 1230321;
    address internal sender = vm.addr(privateKey);
    address internal from2 = vm.addr(privateKey2);
    address internal recipient = vm.addr(recipientKey);

    function setUp() public virtual {
        permit2 = new Permit2();

        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        dispatcher = new TransferRequestDispatcher(address(permit2));

        token = new MockERC20("TestToken", "TestToken");

        token.mint(sender, 1e18);

        vm.prank(sender);
        token.approve(address(permit2), 1e20);
    }

    function _sign(TransferRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(dispatcher),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(TransferRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
