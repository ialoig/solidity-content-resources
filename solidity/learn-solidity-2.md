# 🔷 Learning Solidity - part 2

# Random Numbers

How do we generate random numbers in Solidity?

The real answer here is, you can't. Well, at least you can't do it safely.

Let's look at why.

## Random number generation via `keccak256`

The best source of randomness we have in Solidity is the keccak256 hash function.

We could do something like the following to generate a random number:

```shell
// Generate a random number between 1 and 100:
uint randNonce = 0;
uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
randNonce++;
uint random2 = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
```

What this would do is take the timestamp of `now`, the `msg.sender`, and an incrementing `nonce` (a number that is only ever used once, so we don't run the same hash function with the same input parameters twice).

It would then "pack" the inputs and use `keccak` to convert them to a random hash. Next, it would convert that hash to a `uint`, and then use `% 100` to take only the last 2 digits. This will give us a totally random number between 0 and 99.

## This method is vulnerable to attack by a dishonest node

In Ethereum, when you call a function on a contract, you broadcast it to a node or nodes on the network as a transaction. The nodes on the network then collect a bunch of transactions, try to be the first to solve a computationally-intensive mathematical problem as a "Proof of Work", and then publish that group of transactions along with their Proof of Work (PoW) as a block to the rest of the network.

Once a node has solved the PoW, the other nodes stop trying to solve the PoW, verify that the other node's list of transactions are valid, and then accept the block and move on to trying to solve the next block.

This makes our random number function **exploitable**.

Let's say we had a coin flip contract — heads you double your money, tails you lose everything. Let's say it used the above random function to determine heads or tails. (`random >= 50` is heads, `random < 50` is tails).

If I were running a node, I could publish a transaction only to my own node and not share it. I could then run the coin flip function to see if I won — and if I lost, choose not to include that transaction in the next block I'm solving. I could keep doing this indefinitely until I finally won the coin flip and solved the next block, and profit.

## So how do we generate random numbers safely in Ethereum?

Because the entire contents of the blockchain are visible to all participants, this is a hard problem, and its solution is beyond the scope of this tutorial. You can read [this StackOverflow thread](https://ethereum.stackexchange.com/questions/191/how-can-i-securely-generate-a-random-number-in-my-smart-contract) for some ideas. One idea would be to use an oracle to access a random number function from outside of the Ethereum blockchain.

Of course, since tens of thousands of Ethereum nodes on the network are competing to solve the next block, my odds of solving the next block are extremely low. It would take me a lot of time or computing resources to exploit this profitably — but if the reward were high enough (like if I could bet $100,000,000 on the coin flip function), it would be worth it for me to attack.

# Contract security enhancements: Overflows and Underflows
We're going to look at one major security feature you should be aware of when writing smart contracts: Preventing `overflows` and `underflows`.

## What's an `overflow`?

Let's say we have a `uint8`, which can only have 8 bits. That means the largest number we can store is binary `11111111` (or in decimal, 2^8 - 1 = 255).

Take a look at the following code. What is number equal to at the end?

```shell
uint8 number = 255;
number++;
```

In this case, we've caused it to `overflow` — so number is counterintuitively now equal to 0 even though we increased it. (If you add 1 to binary 11111111, it resets back to 00000000, like a clock going from 23:59 to 00:00).

An `underflow` is similar, where if you subtract `1` from a `uint8` that equals `0`, it will now equal `255` (because uints are unsigned, and cannot be negative).

While we're not using `uint8` here, and it seems unlikely that a `uint256` will overflow when incrementing by 1 each time (2^256 is a really big number), it's still good to put protections in our contract so that our DApp never has unexpected behavior in the future.

# Using SafeMath
To prevent this, OpenZeppelin has created a library called **SafeMath** that prevents these issues by default.

But before we get into that... What's a `library`?

A `library` is a special type of contract in Solidity. One of the things it is useful for is to attach functions to native data types.

For example, with the SafeMath library, we'll use the syntax `using SafeMath for uint256`. The SafeMath library has 4 functions — `add, sub, mul, and div`. And now we can access these functions from `uint256` as follows:

```shell
using SafeMath for uint256;

uint256 a = 5;
uint256 b = a.add(3); // 5 + 3 = 8
uint256 c = a.mul(2); // 5 * 2 = 10
```


Let's take a look at the code behind **SafeMath**:

```shell
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
```

First we have the library keyword — `libraries` are similar to contracts but with a few differences. For our purposes, libraries allow us to use the using keyword, which automatically tacks on all of the library's methods to another data type:

```shell
using SafeMath for uint;
// now we can use these methods on any uint
uint test = 2;
test = test.mul(3); // test now equals 6
test = test.add(5); // test now equals 11
```

Note that the `mul` and `add` functions each require 2 arguments, but when we declare `using SafeMath for uint`, the uint we call the function on (test) is automatically passed in as the first argument.

Let's look at the code behind `add` to see what SafeMath does:

```shell
function add(uint256 a, uint256 b) internal pure returns (uint256) {
  uint256 c = a + b;
  assert(c >= a);
  return c;
}
```

Basically `add` just adds 2 uints like +, but it also contains an `assert` statement to make sure the sum is greater than a. This protects us from `overflows`.

`assert` is similar to `require`, where it will throw an error if false. The difference between `assert` and `require` is that `require` will refund the user the rest of their gas when a function fails, whereas `assert` will not. So most of the time you want to use require in your code; assert is typically used when something has gone horribly wrong with the code (like a uint overflow).

So, simply put, SafeMath's `add, sub, mul`, and `div` are functions that do the basic 4 math operations, but throw an error if an overflow or underflow occurs.

# Comments

## Syntax for comments
Commenting in Solidity is just like JavaScript. You've already seen some examples of single line comments throughout the CryptoZombies lessons:

```shell
// This is a single-line comment. It's kind of like a note to self (or to others)
```

Just add double `//` anywhere and you're commenting. It's so easy that you should do it all the time.

But I hear you — sometimes a single line is not enough. You are born a writer, after all!

Thus we also have multi-line comments:

```shell
contract CryptoZombies {
  /* This is a multi-lined comment. I'd like to thank all of you
    who have taken your time to try this programming course.
    I know it's free to all of you, and it will stay free
    forever, but we still put our heart and soul into making
    this as good as it can be.

    Know that this is still the beginning of Blockchain development.
    We've come very far but there are so many ways to make this
    community better. If we made a mistake somewhere, you can
    help us out and open a pull request here:
    https://github.com/loomnetwork/cryptozombie-lessons

    Or if you have some ideas, comments, or just want to say
    hi - drop by our Telegram community at https://t.me/loomnetworkdev
  */
}
```

In particular, it's good practice to comment your code to explain the expected behavior of every function in your contract. This way another developer (or you, after a 6 month hiatus from a project!) can quickly skim and understand at a high level what your code does without having to read the code itself.

The standard in the Solidity community is to use a format called `natspec`, which looks like this:

```shell
/// @title A contract for basic math operations
/// @author ialoig
/// @notice For now, this contract just adds a multiply function
contract Math {
  /// @notice Multiplies 2 numbers together
  /// @param x the first uint.
  /// @param y the second uint.
  /// @return z the product of (x * y)
  /// @dev This function does not currently check for overflows
  function multiply(uint x, uint y) returns (uint z) {
    // This is just a normal comment, and won't get picked up by natspec
    z = x * y;
  }
}
```

`@title` and `@author` are straightforward.

`@notice` explains to a user what the contract / function does.

`@dev` is for explaining extra details to developers.

`@param` and `@return` are for describing what each parameter and return value of a function are for.

Note that you don't always have to use all of these tags for every function — all tags are optional. But at the very least, leave a `@dev` note explaining what each function does.