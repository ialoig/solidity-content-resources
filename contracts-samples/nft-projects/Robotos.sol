// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Robotos is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public _baseTokenURI;
    uint256 public _price = 0.05 ether;
    uint256 public _maxSupply = 9999;
    bool public _preSaleIsActive = false;
    bool public _saleIsActive = false;

    address a1 = 0x63989a803b61581683B54AB6188ffa0F4bAAdf28;
    address a2 = 0x273Dc0347CB3AbA026F8A4704B1E1a81a3647Cf3;
    address a3 = 0x81a76401a46FA740c911e374324E4046b84cFA33;

    constructor(string memory baseURI) ERC721("Robotos", "ROBO") {
        setBaseURI(baseURI);

        for (uint256 i = 0; i < 36; i++) {
            if (i < 16) {
                _safeMint(a1, i);
            } else if (i < 26) {
                _safeMint(a2, i);
            } else if (i < 36) {
                _safeMint(a3, i);
            }
        }
    }

    function preSaleMint() public payable {
        uint256 supply = totalSupply();

        require(_preSaleIsActive, "presale_not_active");
        require(balanceOf(msg.sender) == 0, "presale_wallet_limit_met");
        require(supply < 900, "max_token_supply_exceeded");
        require(msg.value >= _price, "insufficient_payment_value");

        _safeMint(msg.sender, supply);
    }

    function mint(uint256 mintCount) public payable {
        uint256 supply = totalSupply();

        require(_saleIsActive, "sale_not_active");
        require(mintCount <= 18, "max_mint_count_exceeded");
        require(supply + mintCount <= _maxSupply, "max_token_supply_exceeded");
        require(msg.value >= _price * mintCount, "insufficient_payment_value");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        if (supply + mintCount == _maxSupply) {
            withdrawAll();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function preSaleStart() public onlyOwner {
        _preSaleIsActive = true;
    }

    function preSaleStop() public onlyOwner {
        _preSaleIsActive = false;
    }

    function saleStart() public onlyOwner {
        _saleIsActive = true;
    }

    function saleStop() public onlyOwner {
        _saleIsActive = false;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(a1).send(_each));
        require(payable(a2).send(_each));
        require(payable(a3).send(_each));
    }
}
