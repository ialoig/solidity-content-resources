
# 📚 Solidity Content & Resources 
# 📝 Documentation

📕 Read the docs: https://docs.soliditylang.org

📙 [Solidity by example](https://solidity-by-example.org)

- [Primitive Data Types](https://solidity-by-example.org/primitives/)
- [Mappings](https://solidity-by-example.org/mapping/)
- [Structs](https://solidity-by-example.org/structs/)
- [Modifiers](https://solidity-by-example.org/function-modifier/)
- [Events](https://solidity-by-example.org/events/)
- [Inheritance](https://solidity-by-example.org/inheritance/)
- [Payable](https://solidity-by-example.org/payable/)
- [Fallback](https://solidity-by-example.org/fallback/)


# 💡 Helpful Resources
- 🧟 [Crypto Zombies](https://cryptozombies.io/)
- 🦄 [Buildspace](https://buildspace.so/)

# 🔷 Learning Solidity

## Function Declarations
A function declaration in solidity looks like the following:

```shell
function eatHamburgers(string memory _name, uint _amount) public {

}
```

This is a function named eatHamburgers that takes 2 parameters: a `string` and a `uint`. For now the body of the function is empty. Note that we're specifying the function visibility as public. We're also providing instructions about where the _name variable should be stored- in memory. This is required for all reference types such as arrays, structs, mappings, and strings.

What is a reference type you ask?

Well, there are two ways in which you can pass an argument to a Solidity function:

- By `value`, which means that the Solidity compiler creates a new copy of the parameter's value and passes it to your function. This allows your function to modify the value without worrying that the value of the initial parameter gets changed.
- By `reference`, which means that your function is called with a... reference to the original variable. Thus, if your function changes the value of the variable it receives, the value of the original variable gets changed.

> Note: It's convention (but not required) to start function parameter variable names with an underscore (_) in order to differentiate them from global variables. We'll use that convention throughout our tutorial.


## Function Visibility Specifiers

In Solidity, functions are `public` by default. This means anyone (or any other contract) can call your contract's function and execute its code.

Obviously this isn't always desirable, and can make your contract vulnerable to attacks. Thus it's good practice to mark your functions as `private` by default, and then only make `public` the functions you want to expose to the world.

We use the keyword `private` after the function name. And as with function parameters, it's convention to start private function names with an underscore (`_`).

```shell
uint[] numbers;

function _addToArray(uint _number) private {
    numbers.push(_number);
}
```

- `public`: visible externally and internally (creates a getter function for storage/state variables)

- `private`: only visible in the current contract

- `external`: only visible externally (only for functions) - i.e. can only be message-called (via this.func)

- `internal`: only visible internally

### Modifiers
- `pure` for functions: Disallows modification or access of state.

- `view` for functions: Disallows modification of state.

- `payable` for functions: Allows them to receive Ether together with a call.

- `constant` for state variables: Disallows assignment (except initialisation), does not occupy storage slot.

- `immutable` for state variables: Allows exactly one assignment at construction time and is constant afterwards. Is stored in code.

- `anonymous` for events: Does not store event signature as topic.

- `indexed` for event parameters: Stores the parameter as topic.

- `virtual` for functions and modifiers: Allows the function’s or modifier’s behaviour to be changed in derived contracts.

- `override`: States that this function, modifier or public state variable changes the behaviour of a function or modifier in a base contract.


## Working With Structs and Arrays
Creating New Structs
Remember our Person struct in the previous example?
```shell
struct Person {
  uint age;
  string name;
}

Person[] public people;
```
Now we're going to learn how to create new Persons and add them to our people array.

```shell
// create a New Person:
Person satoshi = Person(172, "Satoshi");

// Add that person to the Array:
people.push(satoshi);
```

We can also combine these together and do them in one line of code to keep things clean:

```shell
people.push(Person(16, "Vitalik"));
```
> Note that array.push() adds something to the end of the array, so the elements are in the order we added them.

## Events

`Events` are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.

Example:
```shell
// declare the event
event IntegersAdded(uint x, uint y, uint result);

function add(uint _x, uint _y) public returns (uint) {
  uint result = _x + _y;
  // fire an event to let the app know the function was called:
  emit IntegersAdded(_x, _y, result);
  return result;
}
```

Your app front-end could then listen for the event. A javascript implementation would look something like:

```shell
YourContract.IntegersAdded(function(error, result) {
  // do something with result
})
```

## Mappings
`Mappings` are another way of storing organized data in Solidity.

Defining a `mapping` looks like this:

```shell
// For a financial app, storing a uint that holds the user's account balance:
mapping (address => uint) public accountBalance;

// Or could be used to store / lookup usernames based on userId
mapping (uint => string) userIdToName;
```
A mapping is essentially a `key-value` store for storing and looking up data. In the first example, the key is an address and the value is a uint, and in the second example the key is a uint and the value a string.

## msg.sender
In Solidity, there are certain global variables that are available to all functions. One of these is `msg.sender`, which refers to the address of the person (or smart contract) who called the current function.

> Note: In Solidity, function execution always needs to start with an external caller. A contract will just sit on the blockchain doing nothing until someone calls one of its functions. So there will always be a `msg.sender`.

Here's an example of using msg.sender and updating a mapping:

```shell
mapping (address => uint) favoriteNumber;

function setMyNumber(uint _myNumber) public {
  // Update our `favoriteNumber` mapping to store `_myNumber` under `msg.sender`
  favoriteNumber[msg.sender] = _myNumber;
  // ^ The syntax for storing data in a mapping is just like with arrays
}

function whatIsMyNumber() public view returns (uint) {
  // Retrieve the value stored in the sender's address
  // Will be `0` if the sender hasn't called `setMyNumber` yet
  return favoriteNumber[msg.sender];
}
```

In this trivial example, anyone could call `setMyNumber` and store a `uint` in our contract, which would be tied to their address. Then when they called `whatIsMyNumber`, they would be returned the `uint` that they stored.

Using `msg.sender` gives you the security of the Ethereum blockchain — the only way someone can modify someone else's data would be to steal the private key associated with their Ethereum address.


## Inheritance
Rather than making one extremely long contract, sometimes it makes sense to split your code logic across multiple contracts to organize the code.

One feature of Solidity that makes this more manageable is contract `inheritance`:

```shell
contract Doge {
  function catchphrase() public returns (string memory) {
    return "So Wow CryptoDoge";
  }
}

contract BabyDoge is Doge {
  function anotherCatchphrase() public returns (string memory) {
    return "Such Moon BabyDoge";
  }
}
```

BabyDoge `inherits` from Doge. That means if you compile and deploy BabyDoge, it will have access to both catchphrase() and anotherCatchphrase() (and any other public functions we may define on Doge).

This can be used for logical inheritance (such as with a subclass, a Cat is an Animal). But it can also be used simply for organizing your code by grouping similar logic together into different contracts.

## Storage vs Memory (Data location)
In Solidity, there are two locations you can store variables — in `storage` and in `memory`.

- `Storage` refers to variables stored permanently on the blockchain. 
- `Memory` variables are temporary, and are erased between external function calls to your contract. Think of it like your computer's hard disk vs RAM.

Most of the time you don't need to use these keywords because Solidity handles them by default. State variables (variables declared outside of functions) are by default `storage` and written permanently to the blockchain, while variables declared inside functions are `memory` and will disappear when the function call ends.

However, there are times when you do need to use these keywords, namely when dealing with structs and arrays within functions:


```shell
contract SandwichFactory {
  struct Sandwich {
    string name;
    string status;
  }

  Sandwich[] sandwiches;

  function eatSandwich(uint _index) public {
    // Sandwich mySandwich = sandwiches[_index];

    // ^ Seems pretty straightforward, but solidity will give you a warning
    // telling you that you should explicitly declare `storage` or `memory` here.

    // So instead, you should declare with the `storage` keyword, like:
    Sandwich storage mySandwich = sandwiches[_index];
    // ...in which case `mySandwich` is a pointer to `sandwiches[_index]`
    // in storage, and...
    mySandwich.status = "Eaten!";
    // ...this will permanently change `sandwiches[_index]` on the blockchain.

    // If you just want a copy, you can use `memory`:
    Sandwich memory anotherSandwich = sandwiches[_index + 1];
    // ...in which case `anotherSandwich` will simply be a copy of the 
    // data in memory, and...
    anotherSandwich.status = "Eaten!";
    // ...will just modify the temporary variable and have no effect 
    // on `sandwiches[_index + 1]`. But you can do this:
    sandwiches[_index + 1] = anotherSandwich;
    // ...if you want to copy the changes back into blockchain storage.
  }
}
```
## Declaring arrays in memory
You can use the `memory` keyword with arrays to create a new array inside a function without needing to write anything to storage. The array will only exist until the end of the function call, and this is a lot cheaper gas-wise than updating an array in `storage` — free if it's a `view` function called externally.

Here's how to declare an array in memory:

```shell
function getArray() external pure returns(uint[] memory) {
  // Instantiate a new array in memory with a length of 3
  uint[] memory values = new uint[](3);

  // Put some values to it
  values[0] = 1;
  values[1] = 2;
  values[2] = 3;

  return values;
}
```

> Note: memory arrays must be created with a length argument (in this example, `3`). They currently cannot be resized like storage arrays can with `array.push()`, although this may be changed in a future version of Solidity.

# OpenZeppelin's Ownable contract
Below is the `Ownable` contract taken from the OpenZeppelin Solidity library. OpenZeppelin is a library of secure and community-vetted smart contracts that you can use in your own DApps. 

Give the contract below a read-through.


```shell
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
```

A few new things here we haven't seen before:

- Constructors: `constructor()` is a constructor, which is an optional special function that has the same name as the contract. It will get executed only one time, when the contract is first created.
- Function Modifiers: `modifier onlyOwner()`. Modifiers are kind of half-functions that are used to modify other functions, usually to check some requirements prior to execution. In this case, `onlyOwner` can be used to limit access so only the owner of the contract can run this function.

So the `Ownable` contract basically does the following:

1. When a contract is created, its constructor sets the `owner` to `msg.sender` (the person who deployed it)

2. It adds an `onlyOwner` modifier, which can restrict access to certain functions to only the `owner`

2. It allows you to transfer the contract to a new `owner`

`onlyOwner` is such a common requirement for contracts that most Solidity DApps start with a copy/paste of this Ownable contract, and then their first contract inherits from it.


## Function Modifiers
A function modifier looks just like a function, but uses the keyword `modifier` instead of the keyword function. And it can't be called directly like a function can — instead we can attach the modifier's name at the end of a function definition to change that function's behavior.

Let's take a closer look by examining `onlyOwner`:


```shell
pragma solidity >=0.5.0 <0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
```

Notice the `onlyOwner` modifier on the `renounceOwnership` function. When you call `renounceOwnership`, the code inside onlyOwner executes first. Then when it hits the `_; `statement in `onlyOwner`, it goes back and executes the code inside `renounceOwnership`.

So while there are other ways you can use modifiers, one of the most common use-cases is to add a quick `require` check before a function executes.

In the case of `onlyOwner`, adding this modifier to a function makes it so only the owner of the contract (you, if you deployed it) can call that function.

> Note: Giving the owner special powers over the contract like this is often necessary, but it could also be used maliciously. For example, the owner could add a backdoor function that would allow him to transfer anyone's zombies to himself!

> So it's important to remember that just because a DApp is on Ethereum does not automatically mean it's decentralized — you have to actually read the full source code to make sure it's free of special controls by the owner that you need to potentially worry about. There's a careful balance as a developer between maintaining control over a DApp such that you can fix potential bugs, and building an owner-less platform that your users can trust to secure their data.

## Function modifiers with arguments
Previously we looked at the simple example of onlyOwner. But function `modifiers` can also take `arguments`. For example:

```shell
// A mapping to store a user's age:
mapping (uint => uint) public age;

// Modifier that requires this user to be older than a certain age:
modifier olderThan(uint _age, uint _userId) {
  require(age[_userId] >= _age);
  _;
}

// Must be older than 16 to drive a car (in the US, at least).
// We can call the `olderThan` modifier with arguments like so:
function driveCar(uint _userId) public olderThan(16, _userId) {
  // Some function logic
}
```
You can see here that the `olderThan` modifier takes arguments just like a function does. And that the `driveCar` function passes its arguments to the modifier.


# ⛽ Gas


## Gas — the fuel Ethereum DApps run on
In Solidity, your users have to pay every time they execute a function on your DApp using a currency called `gas`. Users buy gas with Ether (the currency on Ethereum), so your users have to spend ETH in order to execute functions on your DApp.

How much gas is required to execute a function depends on how complex that function's logic is. Each individual operation has a `gas cost` based roughly on how much computing resources will be required to perform that operation (e.g. writing to storage is much more expensive than adding two integers).
The total `gas cost` of your function is the sum of the gas costs of all its individual operations.

Because running functions costs real money for your users, code optimization is much more important in Ethereum than in other programming languages. If your code is sloppy, your users are going to have to pay a premium to execute your functions — and this could add up to millions of dollars in unnecessary fees across thousands of users.

## Why is gas necessary?
Ethereum is like a big, slow, but extremely secure computer. When you execute a function, every single node on the network needs to run that same function to verify its output — thousands of nodes verifying every function execution is what makes Ethereum decentralized, and its data immutable and censorship-resistant.

The creators of Ethereum wanted to make sure someone couldn't clog up the network with an infinite loop, or hog all the network resources with really intensive computations. So they made it so transactions aren't free, and users have to pay for computation time as well as storage.

> Note: This isn't necessarily true for other blockchain, like the ones the CryptoZombies authors are building at Loom Network. It probably won't ever make sense to run a game like World of Warcraft directly on the Ethereum mainnet — the gas costs would be prohibitively expensive. But it could run on a blockchain with a different consensus algorithm. We'll talk more about what types of DApps you would want to deploy on Loom vs the Ethereum mainnet in a future lesson.

## Struct packing to save gas
In Solidity there are other types of uints: uint8, uint16, uint32, etc.

Normally there's no benefit to using these sub-types because Solidity reserves 256 bits of storage regardless of the uint size. For example, using uint8 instead of uint (uint256) won't save you any gas.

But there's an exception to this: inside structs.

If you have multiple uints inside a struct, using a smaller-sized uint when possible will allow Solidity to pack these variables together to take up less storage. For example:

```shell
struct NormalStruct {
  uint a;
  uint b;
  uint c;
}

struct MiniMe {
  uint32 a;
  uint32 b;
  uint c;
}

// `mini` will cost less gas than `normal` because of struct packing
NormalStruct normal = NormalStruct(10, 20, 30);
MiniMe mini = MiniMe(10, 20, 30); 
```

For this reason, inside a struct you'll want to use the smallest integer sub-types you can get away with.

You'll also want to cluster identical data types together (i.e. put them next to each other in the struct) so that Solidity can minimize the required storage space. For example, a struct with fields `uint c; uint32 a; uint32 b;` will cost less gas than a struct with fields `uint32 a; uint c; uint32 b;` because the `uint32` fields are clustered together.

## View functions don't cost gas
`view` functions don't cost any gas when they're called externally by a user.

This is because `view functions don't actually change anything on the blockchain – they only read the data`. So marking a function with `view` tells `web3.js` that it only needs to query your local Ethereum node to run the function, and it doesn't actually have to create a transaction on the blockchain (which would need to be run on every single node, and cost gas).

> Note: If a `view` function is called internally from another function in the same contract that is `not` a `view` function, it will still `cost gas`. This is because the other function creates a transaction on Ethereum, and will still need to be verified from every node. 
So `view` functions are only free when they're called externally.

##  Gas helpful resources

- [8 general guideline methods on contract optimization](https://medium.com/coinmonks/8-ways-of-reducing-the-gas-consumption-of-your-smart-contracts-9a506b339c0a)

- [Profiling Gas Leaks in Solidity Smart Contracts](https://arxiv.org/pdf/2008.05449.pdf)


# Time Units

Solidity provides some `native units` for dealing with `time`.

The variable `now` will return the current unix timestamp of the latest block (the number of seconds that have passed since January 1st 1970). The unix time as I write this is 1515527488.

> Note: Unix time is traditionally stored in a 32-bit number. This will lead to the "Year 2038" problem, when 32-bit unix timestamps will overflow and break a lot of legacy systems. So if we wanted our DApp to keep running 20 years from now, we could use a 64-bit number instead — but our users would have to spend more gas to use our DApp in the meantime. Design decisions!

Solidity also contains the time units `seconds, minutes, hours, days, weeks and years`. These will convert to a `uint` of the number of seconds in that length of time.
So 1 minutes is 60, 1 hours is 3600 (60 seconds x 60 minutes), 1 days is 86400 (24 hours x 60 minutes x 60 seconds), etc.

Here's an example of how these time units can be useful:

```shel
uint lastUpdated;

// Set `lastUpdated` to `now`
function updateTimestamp() public {
  lastUpdated = now;
}

// Will return `true` if 5 minutes have passed since `updateTimestamp` was 
// called, `false` if 5 minutes have not passed
function fiveMinutesHavePassed() public view returns (bool) {
  return (now >= (lastUpdated + 5 minutes));
}
```