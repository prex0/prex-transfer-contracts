import {Test} from "forge-std/Test.sol";
import {ECDSA} from "permit2/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "permit2/src/interfaces/IPermit2.sol";
import {Permit2} from "permit2/src/Permit2.sol";
import {
    TokenDistributeSubmitRequest,
    TokenDistributeSubmitRequestLib
} from "src/distributor/TokenDistributeSubmitRequest.sol";
import {
    TokenDistributeDepositRequest,
    TokenDistributeDepositRequestLib
} from "src/distributor/TokenDistributeDepositRequest.sol";
import {TokenDistributor} from "src/distributor/TokenDistributor.sol";
import {MockERC20} from "../MockERC20.sol";
import {TestUtils} from "../TestUtils.sol";

contract TestTokenDistributorSetup is TestUtils {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;
    using TokenDistributeDepositRequestLib for TokenDistributeDepositRequest;

    TokenDistributor internal distributor;
    Permit2 permit2;
    bytes32 DOMAIN_SEPARATOR;
    MockERC20 token;

    uint256 internal privateKey = 12345;
    uint256 internal privateKey2 = 32156;
    uint256 internal privateKey3 = 654321;
    address internal sender = vm.addr(privateKey);
    address internal facilitator = vm.addr(privateKey2);
    address internal recipient = vm.addr(privateKey3);

    uint256 constant MINT_AMOUNT = 1e20;

    function setUp() public virtual {
        permit2 = new Permit2();

        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        distributor = new TokenDistributor(address(permit2), address(this));

        distributor.addFacilitator(facilitator);

        token = new MockERC20("TestToken", "TestToken");

        token.mint(sender, MINT_AMOUNT);

        vm.prank(sender);
        token.approve(address(permit2), 1e20);
    }

    function _sign(TokenDistributeSubmitRequest memory request, uint256 fromPrivateKey)
        internal
        view
        virtual
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(distributor),
            TokenDistributeSubmitRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _sign(TokenDistributeDepositRequest memory request, address _token, uint256 fromPrivateKey)
        internal
        view
        virtual
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request, _token),
            address(distributor),
            TokenDistributeDepositRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(TokenDistributeSubmitRequest memory request)
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

    function _toPermit(TokenDistributeDepositRequest memory request, address _token)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: _token, amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }

    function _getRecipientData(
        bytes32 _requestId,
        uint256 _nonce,
        uint256 _deadline,
        address _recipient,
        uint256 _privateKey
    ) internal view returns (TokenDistributor.RecipientData memory) {
        bytes32 messageHash = keccak256(abi.encode(address(distributor), _nonce, _deadline, _recipient));

        return TokenDistributor.RecipientData({
            requestId: _requestId,
            recipient: _recipient,
            nonce: _nonce,
            deadline: _deadline,
            sig: _signMessage(_privateKey, messageHash)
        });
    }
}
