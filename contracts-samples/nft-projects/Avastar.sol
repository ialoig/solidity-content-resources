/**
 *Submitted for verification at Etherscan.io on 2020-02-07
 */

// File: contracts/AvastarTypes.sol

// https://nft42.github.io/Avastars-Contracts/#/README
// https://github.com/NFT42/Avastars-Contracts/tree/be2d374926eed764f9f6c278f9d554bd5cb164d8/poc

pragma solidity 0.5.14;

/**
 * @title Avastar Data Types
 * @author Cliff Hall
 */
contract AvastarTypes {
    enum Generation {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Series {
        PROMO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Wave {
        PRIME,
        REPLICANT
    }

    enum Gene {
        SKIN_TONE,
        HAIR_COLOR,
        EYE_COLOR,
        BG_COLOR,
        BACKDROP,
        EARS,
        FACE,
        NOSE,
        MOUTH,
        FACIAL_FEATURE,
        EYES,
        HAIR_STYLE
    }

    enum Gender {
        ANY,
        MALE,
        FEMALE
    }

    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    struct Trait {
        uint256 id;
        Generation generation;
        Gender gender;
        Gene gene;
        Rarity rarity;
        uint8 variation;
        Series[] series;
        string name;
        string svg;
    }

    struct Prime {
        uint256 id;
        uint256 serial;
        uint256 traits;
        bool[12] replicated;
        Generation generation;
        Series series;
        Gender gender;
        uint8 ranking;
    }

    struct Replicant {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Gender gender;
        uint8 ranking;
    }

    struct Avastar {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Wave wave;
    }

    struct Attribution {
        Generation generation;
        string artist;
        string infoURI;
    }
}

// File: contracts/AvastarBase.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Base
 * @author Cliff Hall
 * @notice Utilities used by descendant contracts
 */
contract AvastarBase {
    /**
     * @notice Convert a `uint` value to a `string`
     * via OraclizeAPI - MIT licence
     * https://github.com/provable-things/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol#L896
     * @param _i the `uint` value to be converted
     * @return result the `string` representation of the given `uint` value
     */
    function uintToStr(uint256 _i)
        internal
        pure
        returns (string memory result)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        result = string(bstr);
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
}

// File: contracts/AvastarState.sol

pragma solidity 0.5.14;

/**
 * @title Avastar State
 * @author Cliff Hall
 * @notice This contract maintains the state variables for the Avastar Teleporter.
 */
contract AvastarState is AvastarBase, AvastarTypes, AccessControl, ERC721Full {
    /**
     * @notice Calls ERC721Full constructor with token name and symbol.
     */
    constructor() public ERC721Full(TOKEN_NAME, TOKEN_SYMBOL) {}

    string public constant TOKEN_NAME = "Avastar";
    string public constant TOKEN_SYMBOL = "AVASTAR";

    /**
     * @notice All Avastars across all Waves and Generations
     */
    Avastar[] internal avastars;

    /**
     * @notice List of all Traits across all Generations
     */
    Trait[] internal traits;

    /**
     * @notice  Retrieve Primes by Generation
     * Prime[] primes = primesByGeneration[uint8(_generation)]
     */
    mapping(uint8 => Prime[]) internal primesByGeneration;

    /**
     * @notice Retrieve Replicants by Generation
     * Replicant[] replicants = replicantsByGeneration[uint8(_generation)]
     */
    mapping(uint8 => Replicant[]) internal replicantsByGeneration;

    /**
     * @notice Retrieve Artist Attribution by Generation
     * Attribution attribution = attributionByGeneration[Generation(_generation)]
     */
    mapping(uint8 => Attribution) public attributionByGeneration;

    /**
     * @notice Retrieve the approved Trait handler for a given Avastar Prime by Token ID
     */
    mapping(uint256 => address) internal traitHandlerByPrimeTokenId;

    /**
     * @notice Is a given Trait Hash used within a given Generation
     * bool used = isHashUsedByGeneration[uint8(_generation)][uint256(_traits)]
     * This mapping ensures that within a Generation, a given Trait Hash is unique and can only be used once
     */
    mapping(uint8 => mapping(uint256 => bool)) public isHashUsedByGeneration;

    /**
     * @notice Retrieve Token ID for a given Trait Hash within a given Generation
     * uint256 tokenId = tokenIdByGenerationAndHash[uint8(_generation)][uint256(_traits)]
     * Since Token IDs start at 0 and empty mappings for uint256 return 0, check isHashUsedByGeneration first
     */
    mapping(uint8 => mapping(uint256 => uint256))
        public tokenIdByGenerationAndHash;

    /**
     * @notice Retrieve count of Primes and Promos by Generation and Series
     * uint16 count = primeCountByGenAndSeries[uint8(_generation)][uint8(_series)]
     */
    mapping(uint8 => mapping(uint8 => uint16)) public primeCountByGenAndSeries;

    /**
     * @notice Retrieve count of Replicants by Generation
     * uint16 count = replicantCountByGeneration[uint8(_generation)]
     */
    mapping(uint8 => uint16) public replicantCountByGeneration;

    /**
     * @notice Retrieve the Token ID for an Avastar by a given Generation, Wave, and Serial
     * uint256 tokenId = tokenIdByGenerationWaveAndSerial[uint8(_generation)][uint256(_wave)][uint256(_serial)]
     */
    mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256)))
        public tokenIdByGenerationWaveAndSerial;

    /**
     * @notice Retrieve the Trait ID for a Trait from a given Generation by Gene and Variation
     * uint256 traitId = traitIdByGenerationGeneAndVariation[uint8(_generation)][uint8(_gene)][uint8(_variation)]
     */
    mapping(uint8 => mapping(uint8 => mapping(uint8 => uint256)))
        public traitIdByGenerationGeneAndVariation;
}

// File: contracts/TraitFactory.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Trait Factory
 * @author Cliff Hall
 */
contract TraitFactory is AvastarState {
    /**
     * @notice Event emitted when a new Trait is created.
     * @param id the Trait ID
     * @param generation the generation of the trait
     * @param gene the gene that the trait is a variation of
     * @param rarity the rarity level of this trait
     * @param variation variation of the gene the trait represents
     * @param name the name of the trait
     */
    event NewTrait(
        uint256 id,
        Generation generation,
        Gene gene,
        Rarity rarity,
        uint8 variation,
        string name
    );

    /**
     * @notice Event emitted when artist attribution is set for a generation.
     * @param generation the generation that attribution was set for
     * @param artist the artist who created the artwork for the generation
     * @param infoURI the artist's website / portfolio URI
     */
    event AttributionSet(Generation generation, string artist, string infoURI);

    /**
     * @notice Event emitted when a Trait's art is created.
     * @param id the Trait ID
     */
    event TraitArtExtended(uint256 id);

    /**
     * @notice Modifier to ensure no trait modification after a generation's
     * Avastar production has begun.
     * @param _generation the generation to check production status of
     */
    modifier onlyBeforeProd(Generation _generation) {
        require(
            primesByGeneration[uint8(_generation)].length == 0 &&
                replicantsByGeneration[uint8(_generation)].length == 0
        );
        _;
    }

    /**
     * @notice Get Trait ID by Generation, Gene, and Variation.
     * @param _generation the generation the trait belongs to
     * @param _gene gene the trait belongs to
     * @param _variation the variation of the gene
     * @return traitId the ID of the specified trait
     */
    function getTraitIdByGenerationGeneAndVariation(
        Generation _generation,
        Gene _gene,
        uint8 _variation
    ) external view returns (uint256 traitId) {
        return
            traitIdByGenerationGeneAndVariation[uint8(_generation)][
                uint8(_gene)
            ][_variation];
    }

    /**
     * @notice Retrieve a Trait's info by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return id the ID of the trait
     * @return generation generation of the trait
     * @return series list of series the trait may appear in
     * @return gender gender(s) the trait is valid for
     * @return gene gene the trait belongs to
     * @return variation variation of the gene the trait represents
     * @return rarity the rarity level of this trait
     * @return name name of the trait
     */
    function getTraitInfoById(uint256 _traitId)
        external
        view
        returns (
            uint256 id,
            Generation generation,
            Series[] memory series,
            Gender gender,
            Gene gene,
            Rarity rarity,
            uint8 variation,
            string memory name
        )
    {
        require(_traitId < traits.length);
        Trait memory trait = traits[_traitId];
        return (
            trait.id,
            trait.generation,
            trait.series,
            trait.gender,
            trait.gene,
            trait.rarity,
            trait.variation,
            trait.name
        );
    }

    /**
     * @notice Retrieve a Trait's name by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return name name of the trait
     */
    function getTraitNameById(uint256 _traitId)
        external
        view
        returns (string memory name)
    {
        require(_traitId < traits.length);
        name = traits[_traitId].name;
    }

    /**
     * @notice Retrieve a Trait's art by ID.
     * Only invokable by a system administrator.
     * @param _traitId the ID of the Trait to retrieve
     * @return art the svg layer representation of the trait
     */
    function getTraitArtById(uint256 _traitId)
        external
        view
        onlySysAdmin
        returns (string memory art)
    {
        require(_traitId < traits.length);
        Trait memory trait = traits[_traitId];
        art = trait.svg;
    }

    /**
     * @notice Get the artist Attribution info for a given Generation, combined into a single string.
     * @param _generation the generation to retrieve artist attribution for
     * @return attrib a single string with the artist and artist info URI
     */
    function getAttributionByGeneration(Generation _generation)
        external
        view
        returns (string memory attribution)
    {
        Attribution memory attrib = attributionByGeneration[uint8(_generation)];
        require(bytes(attrib.artist).length > 0);
        attribution = strConcat(attribution, attrib.artist);
        attribution = strConcat(attribution, " (");
        attribution = strConcat(attribution, attrib.infoURI);
        attribution = strConcat(attribution, ")");
    }

    /**
     * @notice Set the artist Attribution for a given Generation
     * @param _generation the generation to set artist attribution for
     * @param _artist the artist who created the art for the generation
     * @param _infoURI the URI for the artist's website / portfolio
     */
    function setAttribution(
        Generation _generation,
        string calldata _artist,
        string calldata _infoURI
    ) external onlySysAdmin onlyBeforeProd(_generation) {
        require(bytes(_artist).length > 0 && bytes(_infoURI).length > 0);
        attributionByGeneration[uint8(_generation)] = Attribution(
            _generation,
            _artist,
            _infoURI
        );
        emit AttributionSet(_generation, _artist, _infoURI);
    }

    /**
     * @notice Create a Trait
     * @param _generation the generation the trait belongs to
     * @param _series list of series the trait may appear in
     * @param _gender gender the trait is valid for
     * @param _gene gene the trait belongs to
     * @param _rarity the rarity level of this trait
     * @param _variation the variation of the gene the trait belongs to
     * @param _name the name of the trait
     * @param _svg svg layer representation of the trait
     * @return traitId the token ID of the newly created trait
     */
    function createTrait(
        Generation _generation,
        Series[] calldata _series,
        Gender _gender,
        Gene _gene,
        Rarity _rarity,
        uint8 _variation,
        string calldata _name,
        string calldata _svg
    )
        external
        onlySysAdmin
        whenNotPaused
        onlyBeforeProd(_generation)
        returns (uint256 traitId)
    {
        require(_series.length > 0);
        require(bytes(_name).length > 0);
        require(bytes(_svg).length > 0);

        // Get Trait ID
        traitId = traits.length;

        // Create and store trait
        traits.push(
            Trait(
                traitId,
                _generation,
                _gender,
                _gene,
                _rarity,
                _variation,
                _series,
                _name,
                _svg
            )
        );

        // Create generation/gene/variation to traitId mapping required by assembleArtwork
        traitIdByGenerationGeneAndVariation[uint8(_generation)][uint8(_gene)][
            uint8(_variation)
        ] = traitId;

        // Send the NewTrait event
        emit NewTrait(traitId, _generation, _gene, _rarity, _variation, _name);

        // Return the new Trait ID
        return traitId;
    }

    /**
     * @notice Extend a Trait's art.
     * Only invokable by a system administrator.
     * If successful, emits a `TraitArtExtended` event with the resultant artwork.
     * @param _traitId the ID of the Trait to retrieve
     * @param _svg the svg content to be concatenated to the existing svg property
     */
    function extendTraitArt(uint256 _traitId, string calldata _svg)
        external
        onlySysAdmin
        whenNotPaused
        onlyBeforeProd(traits[_traitId].generation)
    {
        require(_traitId < traits.length);
        string memory art = strConcat(traits[_traitId].svg, _svg);
        traits[_traitId].svg = art;
        emit TraitArtExtended(_traitId);
    }

    /**
     * @notice Assemble the artwork for a given Trait hash with art from the given Generation
     * @param _generation the generation the Avastar belongs to
     * @param _traitHash the Avastar's trait hash
     * @return svg the fully rendered SVG for the Avastar
     */
    function assembleArtwork(Generation _generation, uint256 _traitHash)
        internal
        view
        returns (string memory svg)
    {
        require(_traitHash > 0);
        string
            memory accumulator = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" height="1000px" width="1000px" viewBox="0 0 1000 1000">';
        uint256 slotConst = 256;
        uint256 slotMask = 255;
        uint256 bitMask;
        uint256 slottedValue;
        uint256 slotMultiplier;
        uint256 variation;
        uint256 traitId;
        Trait memory trait;

        // Iterate trait hash by Gene and assemble SVG sandwich
        for (uint8 slot = 0; slot <= uint8(Gene.HAIR_STYLE); slot++) {
            slotMultiplier = uint256(slotConst**slot); // Create slot multiplier
            bitMask = slotMask * slotMultiplier; // Create bit mask for slot
            slottedValue = _traitHash & bitMask; // Extract slotted value from hash
            if (slottedValue > 0) {
                variation = (slot > 0) // Extract variation from slotted value
                    ? slottedValue / slotMultiplier
                    : slottedValue;
                if (variation > 0) {
                    traitId = traitIdByGenerationGeneAndVariation[
                        uint8(_generation)
                    ][slot][uint8(variation)];
                    trait = traits[traitId];
                    accumulator = strConcat(accumulator, trait.svg);
                }
            }
        }

        return strConcat(accumulator, "</svg>");
    }
}

// File: contracts/AvastarFactory.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Token Factory
 * @author Cliff Hall
 */
contract AvastarFactory is TraitFactory {
    /**
     * @notice Mint an Avastar.
     * Only invokable by descendant contracts when contract is not paused.
     * Adds new `Avastar` to `avastars` array.
     * Doesn't emit an event, the calling method does (`NewPrime` or `NewReplicant`).
     * Sets `isHashUsedByGeneration` mapping to true for `avastar.generation` and `avastar.traits`.
     * Sets `tokenIdByGenerationAndHash` mapping to `avastar.id` for `avastar.generation` and `avastar.traits`.
     * Sets `tokenIdByGenerationWaveAndSerial` mapping to `avastar.id` for `avastar.generation`, `avastar.wave`, and `avastar.serial`.
     * @param _owner the address of the new Avastar's owner
     * @param _serial the new Avastar's Prime or Replicant serial number
     * @param _traits the new Avastar's trait hash
     * @param _generation the new Avastar's generation
     * @param _wave the new Avastar's wave (Prime/Replicant)
     * @return tokenId the newly minted Prime's token ID
     */
    function mintAvastar(
        address _owner,
        uint256 _serial,
        uint256 _traits,
        Generation _generation,
        Wave _wave
    ) internal whenNotPaused returns (uint256 tokenId) {
        // Mapped Token Id for given generation and serial should always be 0 (uninitialized)
        require(
            tokenIdByGenerationWaveAndSerial[uint8(_generation)][uint8(_wave)][
                _serial
            ] == 0
        );

        // Serial should always be the current length of the primes or replicants array for the given generation
        if (_wave == Wave.PRIME) {
            require(_serial == primesByGeneration[uint8(_generation)].length);
        } else {
            require(
                _serial == replicantsByGeneration[uint8(_generation)].length
            );
        }

        // Get Token ID
        tokenId = avastars.length;

        // Create and store Avastar token
        Avastar memory avastar = Avastar(
            tokenId,
            _serial,
            _traits,
            _generation,
            _wave
        );

        // Store the avastar
        avastars.push(avastar);

        // Indicate use of Trait Hash within given generation
        isHashUsedByGeneration[uint8(avastar.generation)][
            avastar.traits
        ] = true;

        // Store token ID by Generation and Trait Hash
        tokenIdByGenerationAndHash[uint8(avastar.generation)][
            avastar.traits
        ] = avastar.id;

        // Create generation/wave/serial to tokenId mapping
        tokenIdByGenerationWaveAndSerial[uint8(avastar.generation)][
            uint8(avastar.wave)
        ][avastar.serial] = avastar.id;

        // Mint the token
        super._mint(_owner, tokenId);
    }

    /**
     * @notice Get an Avastar's Wave by token ID.
     * @param _tokenId the token id of the given Avastar
     * @return wave the Avastar's wave (Prime/Replicant)
     */
    function getAvastarWaveByTokenId(uint256 _tokenId)
        external
        view
        returns (Wave wave)
    {
        require(_tokenId < avastars.length);
        wave = avastars[_tokenId].wave;
    }

    /**
     * @notice Render the Avastar Prime or Replicant from the original on-chain art.
     * @param _tokenId the token ID of the Prime or Replicant
     * @return svg the fully rendered SVG representation of the Avastar
     */
    function renderAvastar(uint256 _tokenId)
        external
        view
        returns (string memory svg)
    {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        uint256 traits = (avastar.wave == Wave.PRIME)
            ? primesByGeneration[uint8(avastar.generation)][avastar.serial]
                .traits
            : replicantsByGeneration[uint8(avastar.generation)][avastar.serial]
                .traits;
        svg = assembleArtwork(avastar.generation, traits);
    }
}

// File: contracts/PrimeFactory.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Prime Factory
 * @author Cliff Hall
 */
contract PrimeFactory is AvastarFactory {
    /**
     * @notice Maximum number of primes that can be minted in
     * any given series for any generation.
     */
    uint16 public constant MAX_PRIMES_PER_SERIES = 5000;
    uint16 public constant MAX_PROMO_PRIMES_PER_GENERATION = 200;

    /**
     * @notice Event emitted upon the creation of an Avastar Prime
     * @param id the token ID of the newly minted Prime
     * @param serial the serial of the Prime
     * @param generation the generation of the Prime
     * @param series the series of the Prime
     * @param gender the gender of the Prime
     * @param traits the trait hash of the Prime
     */
    event NewPrime(
        uint256 id,
        uint256 serial,
        Generation generation,
        Series series,
        Gender gender,
        uint256 traits
    );

    /**
     * @notice Get the Avastar Prime metadata associated with a given Generation and Serial.
     * Does not include the trait replication flags.
     * @param _generation the Generation of the Prime
     * @param _serial the Serial of the Prime
     * @return tokenId the Prime's token ID
     * @return serial the Prime's serial
     * @return traits the Prime's trait hash
     * @return replicated the Prime's trait replication indicators
     * @return generation the Prime's generation
     * @return series the Prime's series
     * @return gender the Prime's gender
     * @return ranking the Prime's ranking
     */
    function getPrimeByGenerationAndSerial(
        Generation _generation,
        uint256 _serial
    )
        external
        view
        returns (
            uint256 tokenId,
            uint256 serial,
            uint256 traits,
            Generation generation,
            Series series,
            Gender gender,
            uint8 ranking
        )
    {
        require(_serial < primesByGeneration[uint8(_generation)].length);
        Prime memory prime = primesByGeneration[uint8(_generation)][_serial];
        return (
            prime.id,
            prime.serial,
            prime.traits,
            prime.generation,
            prime.series,
            prime.gender,
            prime.ranking
        );
    }

    /**
     * @notice Get the Avastar Prime associated with a given Token ID.
     * Does not include the trait replication flags.
     * @param _tokenId the Token ID of the specified Prime
     * @return tokenId the Prime's token ID
     * @return serial the Prime's serial
     * @return traits the Prime's trait hash
     * @return generation the Prime's generation
     * @return series the Prime's series
     * @return gender the Prime's gender
     * @return ranking the Prime's ranking
     */
    function getPrimeByTokenId(uint256 _tokenId)
        external
        view
        returns (
            uint256 tokenId,
            uint256 serial,
            uint256 traits,
            Generation generation,
            Series series,
            Gender gender,
            uint8 ranking
        )
    {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        require(avastar.wave == Wave.PRIME);
        Prime memory prime = primesByGeneration[uint8(avastar.generation)][
            avastar.serial
        ];
        return (
            prime.id,
            prime.serial,
            prime.traits,
            prime.generation,
            prime.series,
            prime.gender,
            prime.ranking
        );
    }

    /**
     * @notice Get an Avastar Prime's replication flags by token ID.
     * @param _tokenId the token ID of the specified Prime
     * @return tokenId the Prime's token ID
     * @return replicated the Prime's trait replication flags
     */
    function getPrimeReplicationByTokenId(uint256 _tokenId)
        external
        view
        returns (uint256 tokenId, bool[12] memory replicated)
    {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        require(avastar.wave == Wave.PRIME);
        Prime memory prime = primesByGeneration[uint8(avastar.generation)][
            avastar.serial
        ];
        return (prime.id, prime.replicated);
    }

    /**
     * @notice Mint an Avastar Prime
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewPrime` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Prime's trait hash
     * @param _generation the new Prime's generation
     * @return _series the new Prime's series
     * @param _gender the new Prime's gender
     * @param _ranking the new Prime's rarity ranking
     * @return tokenId the newly minted Prime's token ID
     * @return serial the newly minted Prime's serial
     */
    function mintPrime(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Series _series,
        Gender _gender,
        uint8 _ranking
    )
        external
        onlyMinter
        whenNotPaused
        returns (uint256 tokenId, uint256 serial)
    {
        require(_owner != address(0));
        require(_traits != 0);
        require(isHashUsedByGeneration[uint8(_generation)][_traits] == false);
        require(_ranking > 0 && _ranking <= 100);
        uint16 count = primeCountByGenAndSeries[uint8(_generation)][
            uint8(_series)
        ];
        if (_series != Series.PROMO) {
            require(count < MAX_PRIMES_PER_SERIES);
        } else {
            require(count < MAX_PROMO_PRIMES_PER_GENERATION);
        }

        // Get Prime Serial and mint Avastar, getting tokenId
        serial = primesByGeneration[uint8(_generation)].length;
        tokenId = mintAvastar(_owner, serial, _traits, _generation, Wave.PRIME);

        // Create and store Prime struct
        bool[12] memory replicated;
        primesByGeneration[uint8(_generation)].push(
            Prime(
                tokenId,
                serial,
                _traits,
                replicated,
                _generation,
                _series,
                _gender,
                _ranking
            )
        );

        // Increment count for given Generation/Series
        primeCountByGenAndSeries[uint8(_generation)][uint8(_series)]++;

        // Send the NewPrime event
        emit NewPrime(tokenId, serial, _generation, _series, _gender, _traits);

        // Return the tokenId, serial
        return (tokenId, serial);
    }
}

// File: contracts/ReplicantFactory.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Replicant Factory
 * @author Cliff Hall
 */
contract ReplicantFactory is PrimeFactory {
    /**
     * @notice Maximum number of Replicants that can be minted
     * in any given generation.
     */
    uint16 public constant MAX_REPLICANTS_PER_GENERATION = 25200;

    /**
     * @notice Event emitted upon the creation of an Avastar Replicant
     * @param id the token ID of the newly minted Replicant
     * @param serial the serial of the Replicant
     * @param generation the generation of the Replicant
     * @param gender the gender of the Replicant
     * @param traits the trait hash of the Replicant
     */
    event NewReplicant(
        uint256 id,
        uint256 serial,
        Generation generation,
        Gender gender,
        uint256 traits
    );

    /**
     * @notice Get the Avastar Replicant metadata associated with a given Generation and Serial
     * @param _generation the generation of the specified Replicant
     * @param _serial the serial of the specified Replicant
     * @return tokenId the Replicant's token ID
     * @return serial the Replicant's serial
     * @return traits the Replicant's trait hash
     * @return generation the Replicant's generation
     * @return gender the Replicant's gender
     * @return ranking the Replicant's ranking
     */
    function getReplicantByGenerationAndSerial(
        Generation _generation,
        uint256 _serial
    )
        external
        view
        returns (
            uint256 tokenId,
            uint256 serial,
            uint256 traits,
            Generation generation,
            Gender gender,
            uint8 ranking
        )
    {
        require(_serial < replicantsByGeneration[uint8(_generation)].length);
        Replicant memory replicant = replicantsByGeneration[uint8(_generation)][
            _serial
        ];
        return (
            replicant.id,
            replicant.serial,
            replicant.traits,
            replicant.generation,
            replicant.gender,
            replicant.ranking
        );
    }

    /**
     * @notice Get the Avastar Replicant associated with a given Token ID
     * @param _tokenId the token ID of the specified Replicant
     * @return tokenId the Replicant's token ID
     * @return serial the Replicant's serial
     * @return traits the Replicant's trait hash
     * @return generation the Replicant's generation
     * @return gender the Replicant's gender
     * @return ranking the Replicant's ranking
     */
    function getReplicantByTokenId(uint256 _tokenId)
        external
        view
        returns (
            uint256 tokenId,
            uint256 serial,
            uint256 traits,
            Generation generation,
            Gender gender,
            uint8 ranking
        )
    {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        require(avastar.wave == Wave.REPLICANT);
        Replicant memory replicant = replicantsByGeneration[
            uint8(avastar.generation)
        ][avastar.serial];
        return (
            replicant.id,
            replicant.serial,
            replicant.traits,
            replicant.generation,
            replicant.gender,
            replicant.ranking
        );
    }

    /**
     * @notice Mint an Avastar Replicant.
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewReplicant` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Replicant's trait hash
     * @param _generation the new Replicant's generation
     * @param _gender the new Replicant's gender
     * @param _ranking the new Replicant's rarity ranking
     * @return tokenId the newly minted Replicant's token ID
     * @return serial the newly minted Replicant's serial
     */
    function mintReplicant(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Gender _gender,
        uint8 _ranking
    )
        external
        onlyMinter
        whenNotPaused
        returns (uint256 tokenId, uint256 serial)
    {
        require(_traits != 0);
        require(isHashUsedByGeneration[uint8(_generation)][_traits] == false);
        require(_ranking > 0 && _ranking <= 100);
        require(
            replicantCountByGeneration[uint8(_generation)] <
                MAX_REPLICANTS_PER_GENERATION
        );

        // Get Replicant Serial and mint Avastar, getting tokenId
        serial = replicantsByGeneration[uint8(_generation)].length;
        tokenId = mintAvastar(
            _owner,
            serial,
            _traits,
            _generation,
            Wave.REPLICANT
        );

        // Create and store Replicant struct
        replicantsByGeneration[uint8(_generation)].push(
            Replicant(tokenId, serial, _traits, _generation, _gender, _ranking)
        );

        // Increment count for given Generation
        replicantCountByGeneration[uint8(_generation)]++;

        // Send the NewReplicant event
        emit NewReplicant(tokenId, serial, _generation, _gender, _traits);

        // Return the tokenId, serial
        return (tokenId, serial);
    }
}

// File: contracts/IAvastarMetadata.sol

pragma solidity 0.5.14;

/**
 * @title Identification interface for Avastar Metadata generator contract
 * @author Cliff Hall
 * @notice Used by `AvastarTeleporter` contract to validate the address of the contract.
 */
interface IAvastarMetadata {
    /**
     * @notice Acknowledge contract is `AvastarMetadata`
     * @return always true
     */
    function isAvastarMetadata() external pure returns (bool);

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the Avastar's off-chain JSON metadata URI
     */
    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory uri);
}

// File: contracts/AvastarTeleporter.sol

pragma solidity 0.5.14;

/**
 * @title AvastarTeleporter
 * @author Cliff Hall
 * @notice Management of Avastar Primes, Replicants, and Traits
 */
contract AvastarTeleporter is ReplicantFactory {
    /**
     * @notice Event emitted when a handler is approved to manage Trait replication.
     * @param handler the address being approved to Trait replication
     * @param primeIds the array of Avastar Prime tokenIds the handler can use
     */
    event TraitAccessApproved(address indexed handler, uint256[] primeIds);

    /**
     * @notice Event emitted when a handler replicates Traits.
     * @param handler the address marking the Traits as used
     * @param primeId the token id of the Prime supplying the Traits
     * @param used the array of flags representing the Primes resulting Trait usage
     */
    event TraitsUsed(address indexed handler, uint256 primeId, bool[12] used);

    /**
     * @notice Event emitted when AvastarMetadata contract address is set
     * @param contractAddress the address of the new AvastarMetadata contract
     */
    event MetadataContractAddressSet(address contractAddress);

    /**
     * @notice Address of the AvastarMetadata contract
     */
    address private metadataContractAddress;

    /**
     * @notice Acknowledge contract is `AvastarTeleporter`
     * @return always true
     */
    function isAvastarTeleporter() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Set the address of the `AvastarMetadata` contract.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `MetadataContractAddressSet` event.
     * @param _address address of AvastarTeleporter contract
     */
    function setMetadataContractAddress(address _address)
        external
        onlySysAdmin
        whenPaused
        whenNotUpgraded
    {
        // Cast the candidate contract to the IAvastarMetadata interface
        IAvastarMetadata candidateContract = IAvastarMetadata(_address);

        // Verify that we have the appropriate address
        require(candidateContract.isAvastarMetadata());

        // Set the contract address
        metadataContractAddress = _address;

        // Emit the event
        emit MetadataContractAddressSet(_address);
    }

    /**
     * @notice Get the current address of the `AvastarMetadata` contract.
     * return contractAddress the address of the `AvastarMetadata` contract
     */
    function getMetadataContractAddress()
        external
        view
        returns (address contractAddress)
    {
        return metadataContractAddress;
    }

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * Reverts if given token id is not a valid Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the Avastar's off-chain JSON metadata URI
     */
    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory uri)
    {
        require(_tokenId < avastars.length);
        return IAvastarMetadata(metadataContractAddress).tokenURI(_tokenId);
    }

    /**
     * @notice Approve a handler to manage Trait replication for a set of Avastar Primes.
     * Accepts up to 256 primes for approval per call.
     * Reverts if caller is not owner of all Primes specified.
     * Reverts if no Primes are specified.
     * Reverts if given handler already has approval for all Primes specified.
     * If successful, emits a `TraitAccessApproved` event.
     * @param _handler the address approved for Trait access
     * @param _primeIds the token ids for which to approve the handler
     */
    function approveTraitAccess(address _handler, uint256[] calldata _primeIds)
        external
    {
        require(_primeIds.length > 0 && _primeIds.length <= 256);
        uint256 primeId;
        bool approvedAtLeast1 = false;
        for (uint8 i = 0; i < _primeIds.length; i++) {
            primeId = _primeIds[i];
            require(primeId < avastars.length);
            require(
                msg.sender == super.ownerOf(primeId),
                "Must be token owner"
            );
            if (traitHandlerByPrimeTokenId[primeId] != _handler) {
                traitHandlerByPrimeTokenId[primeId] = _handler;
                approvedAtLeast1 = true;
            }
        }
        require(approvedAtLeast1, "No unhandled primes specified");

        // Emit the event
        emit TraitAccessApproved(_handler, _primeIds);
    }

    /**
     * @notice Mark some or all of an Avastar Prime's traits used.
     * Caller must be the token owner OR the approved handler.
     * Caller must send all 12 flags with those to be used set to true, the rest to false.
     * The position of each flag in the `_traitFlags` array corresponds to a Gene, of which Traits are variations.
     * The flag order is: [ SKIN_TONE, HAIR_COLOR, EYE_COLOR, BG_COLOR, BACKDROP, EARS, FACE, NOSE, MOUTH, FACIAL_FEATURE, EYES, HAIR_STYLE ].
     * Reverts if no usable traits are indicated.
     * If successful, emits a `TraitsUsed` event.
     * @param _primeId the token id for the Prime whose Traits are to be used
     * @param _traitFlags an array of no more than 12 booleans representing the Traits to be used
     */
    function useTraits(uint256 _primeId, bool[12] calldata _traitFlags)
        external
    {
        // Make certain token id is valid
        require(_primeId < avastars.length);

        // Make certain caller is token owner OR approved handler
        require(
            msg.sender == super.ownerOf(_primeId) ||
                msg.sender == traitHandlerByPrimeTokenId[_primeId],
            "Must be token owner or approved handler"
        );

        // Get the Avastar and make sure it's a Prime
        Avastar memory avastar = avastars[_primeId];
        require(avastar.wave == Wave.PRIME);

        // Get the Prime
        Prime storage prime = primesByGeneration[uint8(avastar.generation)][
            avastar.serial
        ];

        // Set the flags.
        bool usedAtLeast1;
        for (uint8 i = 0; i < 12; i++) {
            if (_traitFlags.length > i) {
                if (!prime.replicated[i] && _traitFlags[i]) {
                    prime.replicated[i] = true;
                    usedAtLeast1 = true;
                }
            } else {
                break;
            }
        }

        // Revert if no flags changed
        require(usedAtLeast1, "No reusable traits specified");

        // Clear trait handler
        traitHandlerByPrimeTokenId[_primeId] = address(0);

        // Emit the TraitsUsed event
        emit TraitsUsed(msg.sender, _primeId, prime.replicated);
    }
}

pragma solidity 0.5.14;

import "./IAvastarTeleporter.sol";
import "./AvastarTypes.sol";
import "./AvastarBase.sol";
import "./AccessControl.sol";

/**
 * @title Avastar Metadata Generator
 * @author Cliff Hall
 * @notice Generate Avastar metadata from on-chain data.
 * Refers to the `AvastarTeleporter` for raw data to generate
 * the human and machine readable metadata for a given Avastar token Id.
 */
contract AvastarMetadata is AvastarBase, AvastarTypes, AccessControl {
    string public constant INVALID_TOKEN_ID = "Invalid Token ID";

    /**
     * @notice Event emitted when AvastarTeleporter contract is set
     * @param contractAddress the address of the AvastarTeleporter contract
     */
    event TeleporterContractSet(address contractAddress);

    /**
     * @notice Event emitted when TokenURI base changes
     * @param tokenUriBase the base URI for tokenURI calls
     */
    event TokenUriBaseSet(string tokenUriBase);

    /**
     * @notice Event emitted when the `mediaUriBase` is set.
     * Only emitted when the `mediaUriBase` is set after contract deployment.
     * @param mediaUriBase the new URI
     */
    event MediaUriBaseSet(string mediaUriBase);

    /**
     * @notice Event emitted when the `viewUriBase` is set.
     * Only emitted when the `viewUriBase` is set after contract deployment.
     * @param viewUriBase the new URI
     */
    event ViewUriBaseSet(string viewUriBase);

    /**
     * @notice Address of the AvastarTeleporter contract
     */
    IAvastarTeleporter private teleporterContract;

    /**
     * @notice The base URI for an Avastar's off-chain metadata
     */
    string internal tokenUriBase;

    /**
     * @notice Base URI for an Avastar's off-chain image
     */
    string private mediaUriBase;

    /**
     * @notice Base URI to view an Avastar on the Avastars website
     */
    string private viewUriBase;

    /**
     * @notice Set the address of the `AvastarTeleporter` contract.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * To be used if the Teleporter contract has to be upgraded and a new instance deployed.
     * If successful, emits an `TeleporterContractSet` event.
     * @param _address address of `AvastarTeleporter` contract
     */
    function setTeleporterContract(address _address)
        external
        onlySysAdmin
        whenPaused
        whenNotUpgraded
    {
        // Cast the candidate contract to the IAvastarTeleporter interface
        IAvastarTeleporter candidateContract = IAvastarTeleporter(_address);

        // Verify that we have the appropriate address
        require(candidateContract.isAvastarTeleporter());

        // Set the contract address
        teleporterContract = IAvastarTeleporter(_address);

        // Emit the event
        emit TeleporterContractSet(_address);
    }

    /**
     * @notice Acknowledge contract is `AvastarMetadata`
     * @return always true
     */
    function isAvastarMetadata() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Set the base URI for creating `tokenURI` for each Avastar.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `TokenUriBaseSet` event.
     * @param _tokenUriBase base for the ERC721 tokenURI
     */
    function setTokenUriBase(string calldata _tokenUriBase)
        external
        onlySysAdmin
        whenPaused
        whenNotUpgraded
    {
        // Set the base for metadata tokenURI
        tokenUriBase = _tokenUriBase;

        // Emit the event
        emit TokenUriBaseSet(_tokenUriBase);
    }

    /**
     * @notice Set the base URI for the image of each Avastar.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `MediaUriBaseSet` event.
     * @param _mediaUriBase base for the mediaURI shown in metadata for each Avastar
     */
    function setMediaUriBase(string calldata _mediaUriBase)
        external
        onlySysAdmin
        whenPaused
        whenNotUpgraded
    {
        // Set the base for metadata tokenURI
        mediaUriBase = _mediaUriBase;

        // Emit the event
        emit MediaUriBaseSet(_mediaUriBase);
    }

    /**
     * @notice Set the base URI for the image of each Avastar.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `MediaUriBaseSet` event.
     * @param _viewUriBase base URI for viewing an Avastar on the Avastars website
     */
    function setViewUriBase(string calldata _viewUriBase)
        external
        onlySysAdmin
        whenPaused
        whenNotUpgraded
    {
        // Set the base for metadata tokenURI
        viewUriBase = _viewUriBase;

        // Emit the event
        emit ViewUriBaseSet(_viewUriBase);
    }

    /**
     * @notice Get view URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the off-chain URI to view the Avastar on the Avastars website
     */
    function viewURI(uint256 _tokenId) public view returns (string memory uri) {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);
        uri = strConcat(viewUriBase, uintToStr(_tokenId));
    }

    /**
     * @notice Get media URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the off-chain URI to the Avastar image
     */
    function mediaURI(uint256 _tokenId)
        public
        view
        returns (string memory uri)
    {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);
        uri = strConcat(mediaUriBase, uintToStr(_tokenId));
    }

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the Avastar's off-chain JSON metadata URI
     */
    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory uri)
    {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);
        uri = strConcat(tokenUriBase, uintToStr(_tokenId));
    }

    /**
     * @notice Get human-readable metadata for a given Avastar by Token ID.
     * @param _tokenId the token id of the given Avastar
     * @return metadata the Avastar's human-readable metadata
     */
    function getAvastarMetadata(uint256 _tokenId)
        external
        view
        returns (string memory metadata)
    {
        require(_tokenId < teleporterContract.totalSupply(), INVALID_TOKEN_ID);

        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Wave wave;
        Series series;
        Gender gender;
        uint8 ranking;
        string memory attribution;

        // Get the Avastar
        wave = teleporterContract.getAvastarWaveByTokenId(_tokenId);

        // Get Prime or Replicant info depending on Avastar's Wave
        if (wave == Wave.PRIME) {
            (
                id,
                serial,
                traits,
                generation,
                series,
                gender,
                ranking
            ) = teleporterContract.getPrimeByTokenId(_tokenId);
        } else {
            (
                id,
                serial,
                traits,
                generation,
                gender,
                ranking
            ) = teleporterContract.getReplicantByTokenId(_tokenId);
        }

        // Get artist attribution
        attribution = teleporterContract.getAttributionByGeneration(generation);
        attribution = strConcat("Original art by: ", attribution);

        // Name
        metadata = strConcat('{\n  "name": "Avastar #', uintToStr(uint256(id)));
        metadata = strConcat(metadata, '",\n');

        // Description: Generation
        metadata = strConcat(metadata, '  "description": "Generation ');
        metadata = strConcat(metadata, uintToStr(uint8(generation) + 1));

        // Description: Series (if 1-5)
        if (wave == Wave.PRIME && series != Series.PROMO) {
            metadata = strConcat(metadata, " Series ");
            metadata = strConcat(metadata, uintToStr(uint8(series)));
        }

        // Description: Gender
        metadata = strConcat(
            metadata,
            (gender == Gender.MALE) ? " Male " : " Female "
        );

        // Description: Founder, Exclusive, Prime, or Replicant
        if (wave == Wave.PRIME && series == Series.PROMO) {
            metadata = strConcat(
                metadata,
                (serial < 100) ? "Founder. " : "Exclusive. "
            );
        } else {
            metadata = strConcat(
                metadata,
                (wave == Wave.PRIME) ? "Prime. " : "Replicant. "
            );
        }
        metadata = strConcat(metadata, attribution);
        metadata = strConcat(metadata, '",\n');

        // View URI
        metadata = strConcat(metadata, '  "external_url": "');
        metadata = strConcat(metadata, viewURI(_tokenId));
        metadata = strConcat(metadata, '",\n');

        // Media URI
        metadata = strConcat(metadata, '  "image": "');
        metadata = strConcat(metadata, mediaURI(_tokenId));
        metadata = strConcat(metadata, '",\n');

        // Attributes (ala OpenSea)
        metadata = strConcat(metadata, '  "attributes": [\n');

        // Gender
        metadata = strConcat(metadata, "    {\n");
        metadata = strConcat(metadata, '      "trait_type": "gender",\n');
        metadata = strConcat(metadata, '      "value": "');
        metadata = strConcat(
            metadata,
            (gender == Gender.MALE) ? 'male"' : 'female"'
        );
        metadata = strConcat(metadata, "\n    },\n");

        // Wave
        metadata = strConcat(metadata, "    {\n");
        metadata = strConcat(metadata, '      "trait_type": "wave",\n');
        metadata = strConcat(metadata, '      "value": "');
        metadata = strConcat(
            metadata,
            (wave == Wave.PRIME) ? 'prime"' : 'replicant"'
        );
        metadata = strConcat(metadata, "\n    },\n");

        // Generation
        metadata = strConcat(metadata, "    {\n");
        metadata = strConcat(metadata, '      "display_type": "number",\n');
        metadata = strConcat(metadata, '      "trait_type": "generation",\n');
        metadata = strConcat(metadata, '      "value": ');
        metadata = strConcat(metadata, uintToStr(uint8(generation) + 1));
        metadata = strConcat(metadata, "\n    },\n");

        // Series
        if (wave == Wave.PRIME) {
            metadata = strConcat(metadata, "    {\n");
            metadata = strConcat(metadata, '      "display_type": "number",\n');
            metadata = strConcat(metadata, '      "trait_type": "series",\n');
            metadata = strConcat(metadata, '      "value": ');
            metadata = strConcat(metadata, uintToStr(uint8(series)));
            metadata = strConcat(metadata, "\n    },\n");
        }

        // Serial
        metadata = strConcat(metadata, "    {\n");
        metadata = strConcat(metadata, '      "display_type": "number",\n');
        metadata = strConcat(metadata, '      "trait_type": "serial",\n');
        metadata = strConcat(metadata, '      "value": ');
        metadata = strConcat(metadata, uintToStr(serial));
        metadata = strConcat(metadata, "\n    },\n");

        // Ranking
        metadata = strConcat(metadata, "    {\n");
        metadata = strConcat(metadata, '      "display_type": "number",\n');
        metadata = strConcat(metadata, '      "trait_type": "ranking",\n');
        metadata = strConcat(metadata, '      "value": ');
        metadata = strConcat(metadata, uintToStr(ranking));
        metadata = strConcat(metadata, "\n    },\n");

        // Level
        metadata = strConcat(metadata, "    {\n");
        metadata = strConcat(metadata, '      "trait_type": "level",\n');
        metadata = strConcat(metadata, '      "value": "');
        metadata = strConcat(metadata, getRankingLevel(ranking));
        metadata = strConcat(metadata, '"\n    },\n');

        // Traits
        metadata = strConcat(
            metadata,
            assembleTraitMetadata(generation, traits)
        );

        // Finish JSON object
        metadata = strConcat(metadata, "  ]\n}");
    }

    /**
     * @notice Get the rarity level for a given Avastar Rank
     * @param ranking the ranking level (1-100)
     * @return level the rarity level (Common, Uncommon, Rare, Epic, Legendary)
     */
    function getRankingLevel(uint8 ranking)
        internal
        pure
        returns (string memory level)
    {
        require(ranking > 0 && ranking <= 100);
        uint8[4] memory breaks = [33, 41, 50, 60];
        if (ranking < breaks[0]) {
            level = "Common";
        } else if (ranking < breaks[1]) {
            level = "Uncommon";
        } else if (ranking < breaks[2]) {
            level = "Rare";
        } else if (ranking < breaks[3]) {
            level = "Epic";
        } else {
            level = "Legendary";
        }
    }

    /**
     * @notice Assemble the human-readable metadata for a given Trait hash.
     * Used internally by
     * @param _generation the generation the Avastar belongs to
     * @param _traitHash the Avastar's trait hash
     * @return metdata the JSON trait metadata for the Avastar
     */
    function assembleTraitMetadata(Generation _generation, uint256 _traitHash)
        internal
        view
        returns (string memory metadata)
    {
        require(_traitHash > 0);
        uint256 slotConst = 256;
        uint256 slotMask = 255;
        uint256 bitMask;
        uint256 slottedValue;
        uint256 slotMultiplier;
        uint256 variation;
        uint256 traitId;

        // Iterate trait hash by Gene and assemble trait attribute data
        for (uint8 slot = 0; slot <= uint8(Gene.HAIR_STYLE); slot++) {
            slotMultiplier = uint256(slotConst**slot); // Create slot multiplier
            bitMask = slotMask * slotMultiplier; // Create bit mask for slot
            slottedValue = _traitHash & bitMask; // Extract slotted value from hash
            if (slottedValue > 0) {
                variation = (slot > 0) // Extract variation from slotted value
                    ? slottedValue / slotMultiplier
                    : slottedValue;
                if (variation > 0) {
                    traitId = teleporterContract
                        .getTraitIdByGenerationGeneAndVariation(
                            _generation,
                            Gene(slot),
                            uint8(variation)
                        );
                    metadata = strConcat(metadata, "    {\n");
                    metadata = strConcat(metadata, '      "trait_type": "');
                    if (slot == uint8(Gene.SKIN_TONE)) {
                        metadata = strConcat(metadata, "skin_tone");
                    } else if (slot == uint8(Gene.HAIR_COLOR)) {
                        metadata = strConcat(metadata, "hair_color");
                    } else if (slot == uint8(Gene.EYE_COLOR)) {
                        metadata = strConcat(metadata, "eye_color");
                    } else if (slot == uint8(Gene.BG_COLOR)) {
                        metadata = strConcat(metadata, "background_color");
                    } else if (slot == uint8(Gene.BACKDROP)) {
                        metadata = strConcat(metadata, "backdrop");
                    } else if (slot == uint8(Gene.EARS)) {
                        metadata = strConcat(metadata, "ears");
                    } else if (slot == uint8(Gene.FACE)) {
                        metadata = strConcat(metadata, "face");
                    } else if (slot == uint8(Gene.NOSE)) {
                        metadata = strConcat(metadata, "nose");
                    } else if (slot == uint8(Gene.MOUTH)) {
                        metadata = strConcat(metadata, "mouth");
                    } else if (slot == uint8(Gene.FACIAL_FEATURE)) {
                        metadata = strConcat(metadata, "facial_feature");
                    } else if (slot == uint8(Gene.EYES)) {
                        metadata = strConcat(metadata, "eyes");
                    } else if (slot == uint8(Gene.HAIR_STYLE)) {
                        metadata = strConcat(metadata, "hair_style");
                    }
                    metadata = strConcat(metadata, '",\n');
                    metadata = strConcat(metadata, '      "value": "');
                    metadata = strConcat(
                        metadata,
                        teleporterContract.getTraitNameById(traitId)
                    );
                    metadata = strConcat(metadata, '"\n    }');
                    if (slot < uint8(Gene.HAIR_STYLE))
                        metadata = strConcat(metadata, ",");
                    metadata = strConcat(metadata, "\n");
                }
            }
        }
    }
}
