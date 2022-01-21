/**
 *Submitted for verification at Etherscan.io on 2020-05-14
 */

pragma solidity 0.6.6;

contract MinterAccess is Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Sender is not a minter");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function addMinter(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function renounceMinter(address account) external {
        renounceRole(MINTER_ROLE, account);
    }

    function revokeMinter(address account) external {
        revokeRole(MINTER_ROLE, account);
    }
}

interface ISorareCards {
    function createCard(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    ) external returns (uint256);

    function getCard(uint256 _cardId)
        external
        view
        returns (
            uint256 playerId,
            uint16 season,
            uint256 scarcity,
            uint16 serialNumber,
            bytes memory metadata,
            uint16 clubId
        );

    function getPlayer(uint256 playerId)
        external
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        );

    function getClub(uint16 clubId)
        external
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        );

    function cardExists(uint256 cardId) external view returns (bool);
}

contract RelayRecipient is Ownable {
    address private _relayAddress;

    constructor(address relayAddress) public {
        require(relayAddress != address(0), "Custom relay address is required");
        _relayAddress = relayAddress;
    }

    function blockRelay() public onlyOwner {
        _relayAddress = address(this);
    }

    function getRelayAddress() public view returns (address) {
        return _relayAddress;
    }

    /**
     * @dev Replacement for msg.sender. Returns the actual sender of a transaction: msg.sender for regular transactions,
     * and the end-user for relayed calls (where msg.sender is actually `Relay` contract).
     *
     * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.sender`, and use {_msgSender} instead.
     */
    // prettier-ignore
    function _msgSender() internal override virtual view returns (address payable) {
        if (msg.sender != _relayAddress) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    /**
     * @dev Replacement for msg.data. Returns the actual calldata of a transaction: msg.data for regular transactions,
     * and a reduced version for relayed calls (where msg.data contains additional information).
     *
     * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.data`, and use {_msgData} instead.
     */
    // prettier-ignore
    function _msgData() internal override virtual view returns (bytes memory) {
        if (msg.sender != _relayAddress) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    function _getRelayedCallSender()
        private
        pure
        returns (address payable result)
    {
        // We need to read 20 bytes (an address) located at array index msg.data.length - 20. In memory, the array
        // is prefixed with a 32-byte length value, so we first add 32 to get the memory read index. However, doing
        // so would leave the address in the upper 20 bytes of the 32-byte word, which is inconvenient and would
        // require bit shifting. We therefore subtract 12 from the read index so the address lands on the lower 20
        // bytes. This can always be done due to the 32-byte prefix.

        // The final memory read index is msg.data.length - 20 + 32 - 12 = msg.data.length. Using inline assembly is the
        // easiest/most-efficient way to perform this operation.

        // These fields are not accessible from assembly
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            result := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
        // RelayHub appends the sender address at the end of the calldata, so in order to retrieve the actual msg.data,
        // we must strip the last 20 bytes (length of an address type) from it.

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

library NFTClient {
    bytes4 public constant interfaceIdERC721 = 0x80ac58cd;

    function requireERC721(address _candidate) public view {
        require(
            IERC721Enumerable(_candidate).supportsInterface(interfaceIdERC721),
            "IS_NOT_721_TOKEN"
        );
    }

    function transferTokens(
        IERC721Enumerable _nftContract,
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_tokenIds[index] == 0) {
                break;
            }

            _nftContract.safeTransferFrom(_from, _to, _tokenIds[index]);
        }
    }

    function transferAll(
        IERC721Enumerable _nftContract,
        address _sender,
        address _receiver
    ) public {
        uint256 balance = _nftContract.balanceOf(_sender);
        while (balance > 0) {
            _nftContract.safeTransferFrom(
                _sender,
                _receiver,
                _nftContract.tokenOfOwnerByIndex(_sender, balance - 1)
            );
            balance--;
        }
    }

    // /// @dev Pagination of owner tokens
    // /// @param owner - address of the token owner
    // /// @param page - page number
    // /// @param rows - number of rows per page
    function tokensOfOwner(
        address _nftContract,
        address owner,
        uint8 page,
        uint8 rows
    ) public view returns (uint256[] memory) {
        requireERC721(_nftContract);

        IERC721Enumerable nftContract = IERC721Enumerable(_nftContract);

        uint256 tokenCount = nftContract.balanceOf(owner);
        uint256 offset = page * rows;
        uint256 range = offset > tokenCount
            ? 0
            : min(tokenCount - offset, rows);
        uint256[] memory tokens = new uint256[](range);
        for (uint256 index = 0; index < range; index++) {
            tokens[index] = nftContract.tokenOfOwnerByIndex(
                owner,
                offset + index
            );
        }
        return tokens;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }
}

interface ISorareTokens {
    function createCardAndMintToken(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId,
        address to
    ) external returns (uint256);

    function mintToken(uint256 cardId, address to) external returns (uint256);
}

interface INextContract {
    function migrateTokens(uint256[] calldata tokenIds, address to) external;
}

contract SorareTokens is
    MinterAccess,
    RelayRecipient,
    ERC721("Sorare", "SOR"),
    ISorareTokens
{
    ISorareCards public sorareCards;
    INextContract public nextContract;

    constructor(address sorareCardsAddress, address relayAddress)
        public
        RelayRecipient(relayAddress)
    {
        require(
            sorareCardsAddress != address(0),
            "SorareCards address is required"
        );
        sorareCards = ISorareCards(sorareCardsAddress);
    }

    /// @dev Set the prefix for the tokenURIs.
    function setTokenURIPrefix(string memory prefix) public onlyOwner {
        _setBaseURI(prefix);
    }

    /// @dev Set the potential next version contract
    function setNextContract(address nextContractAddress) public onlyOwner {
        require(
            address(nextContract) == address(0),
            "NextContract already set"
        );
        nextContract = INextContract(nextContractAddress);
    }

    /// @dev Creates a new card in the Cards contract and mints the token
    // prettier-ignore
    function createCardAndMintToken(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId,
        address to
    ) public onlyMinter override returns (uint256) {
        uint256 cardId = sorareCards.createCard(
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        );

        _mint(to, cardId);
        return cardId;
    }

    /// @dev Mints a token for an existing card
    // prettier-ignore
    function mintToken(uint256 cardId, address to)
        public
        override
        onlyMinter
        returns (uint256)
    {
        require(sorareCards.cardExists(cardId), "Card does not exist");

        _mint(to, cardId);
        return cardId;
    }

    /// @dev Migrates tokens to a potential new version of this contract
    /// @param tokenIds - list of tokens to transfer
    function migrateTokens(uint256[] calldata tokenIds) external {
        require(address(nextContract) != address(0), "Next contract not set");

        for (uint256 index = 0; index < tokenIds.length; index++) {
            transferFrom(_msgSender(), address(this), tokenIds[index]);
        }

        nextContract.migrateTokens(tokenIds, _msgSender());
    }

    /// @dev Pagination of owner tokens
    /// @param owner - address of the token owner
    /// @param page - page number
    /// @param rows - number of rows per page
    function tokensOfOwner(
        address owner,
        uint8 page,
        uint8 rows
    ) public view returns (uint256[] memory) {
        return NFTClient.tokensOfOwner(address(this), owner, page, rows);
    }

    function getCard(uint256 tokenId)
        public
        view
        returns (
            uint256 playerId,
            uint16 season,
            uint256 scarcity,
            uint16 serialNumber,
            bytes memory metadata,
            uint16 clubId
        )
    {
        (
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        ) = sorareCards.getCard(tokenId);
    }

    function getPlayer(uint256 playerId)
        external
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        )
    {
        (name, yearOfBirth, monthOfBirth, dayOfBirth) = sorareCards.getPlayer(
            playerId
        );
    }

    // prettier-ignore
    function getClub(uint16 clubId)
        external
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        )
    {
        (name, country, city, yearFounded) = sorareCards.getClub(clubId);
    }

    // prettier-ignore
    function _msgSender() internal view override(RelayRecipient, Context) returns (address payable) {
        return RelayRecipient._msgSender();
    }

    // prettier-ignore
    function _msgData() internal view override(RelayRecipient, Context) returns (bytes memory) {
        return RelayRecipient._msgData();
    }
}
