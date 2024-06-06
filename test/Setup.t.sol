import {Test} from "forge-std/Test.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {TransferRequest, TransferRequestLib} from "../src/TransferRequest.sol";
import "../lib/permit2/src/interfaces/IPermit2.sol";
import {RequestDispatcher} from "../src/RequestDispatcher.sol";
import {MockERC20} from "./MockERC20.sol";

contract TestRequestDispatcher is Test {
    using TransferRequestLib for TransferRequest;

    string constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    bytes32 internal constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    RequestDispatcher internal dispatcher;
    bytes32 DOMAIN_SEPARATOR;
    MockERC20 token;

    uint256 internal privateKey = 12345;
    address internal sender = vm.addr(privateKey);

    function setUp() public virtual {
        dispatcher = new RequestDispatcher();

        DOMAIN_SEPARATOR = dispatcher.DOMAIN_SEPARATOR();

        token = new MockERC20("TestToken", "TestToken");

        token.mint(sender, 1e18);

        vm.prank(sender);
        token.approve(address(dispatcher), 1e20);
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


    function _toPermit(TransferRequest memory request) internal pure returns (ISignatureTransfer.PermitTransferFrom memory) {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }

    function _hashTokenPermissions(ISignatureTransfer.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }

    function getPermit2Signature(
        uint256 privateKey,
        ISignatureTransfer.PermitTransferFrom memory permit,
        address spender,
        string memory witnessTypeHash,
        bytes32 witness,
        bytes32 domainSeparator
    ) internal pure returns (bytes memory sig) {
        bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeHash));

        bytes32 msgHash = MessageHashUtils.toTypedDataHash(
            domainSeparator,
            keccak256(
                abi.encode(
                    typeHash, _hashTokenPermissions(permit.permitted), spender, permit.nonce, permit.deadline, witness
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }

    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    function _getPermitVer1Signature(
        uint256 privateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        bytes32 domainSeparator
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 msgHash = MessageHashUtils.toTypedDataHash(
            domainSeparator, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))
        );

        (v, r, s) = vm.sign(privateKey, msgHash);
    }
}
