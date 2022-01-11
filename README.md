
# 📝 Solidity Learning Notes

# 📚 Documentation

📕 Read the docs: https://docs.soliditylang.org

📚 [Solidity by example](https://solidity-by-example.org)

- [Primitive Data Types](https://solidity-by-example.org/primitives/)
- [Mappings](https://solidity-by-example.org/mapping/)
- [Structs](https://solidity-by-example.org/structs/)
- [Modifiers](https://solidity-by-example.org/function-modifier/)
- [Events](https://solidity-by-example.org/events/)
- [Inheritance](https://solidity-by-example.org/inheritance/)
- [Payable](https://solidity-by-example.org/payable/)
- [Fallback](https://solidity-by-example.org/fallback/)

# 🔭 Learning Solidity

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

# ⛽ Gas stuff

- [8 general guideline methods on contract optimization](https://medium.com/coinmonks/8-ways-of-reducing-the-gas-consumption-of-your-smart-contracts-9a506b339c0a)

- [Profiling Gas Leaks in Solidity Smart Contracts](https://arxiv.org/pdf/2008.05449.pdf)
