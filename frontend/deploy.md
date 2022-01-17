# Truffle
`Truffle` is the most popular blockchain development framework for good reason - it's packed with lots of useful features:

- easy smart contract compilation
- automated ABI generation
- integrated smart contract testing - there's even support for Mocha and Chai!
- support for multiple networks - code can be deployed to `Rinkeby`, `Ethereum` or even to `Loom`. We'll walk you through this later😉
Provided that `npm` and `node` have been installed on your computer, we'll want you to install Truffle and make it available globally.

```shell
npm install truffle -g
```

## Getting Started with Truffle
Now that we've installed `Truffle`, it's time to initialize our new project by running: 

```shell
truffle init
```

All it is doing is to create a set of folders and config files with the following structure:

```shell
├── contracts
    ├── Migrations.sol
├── migrations
    ├── 1_initial_migration.js
└── test
truffle-config.js
truffle.js
```

## Truffle's Default Directory Structure
So, running the truffle init command inside of the projects directory, should create several directories and some JavaScript and Solidity files. Let's have a closer look:

- `contracts`: this is the place where Truffle expects to find all our smart contracts. To keep the code organized, we can even create nested folders such as contracts/tokens. Pretty neat😉.

> Note: `truffle init` should automatically create a contract called `Migrations.sol` and the corresponding migration file. We'll explain them a bit later.

- `migrations`: a migration is a JavaScript file that tells Truffle how to deploy a smart contract.

- `test`: here we are expected to put the unit tests which will be JavaScript or Solidity files. Remember, once a contract is deployed it can't be changed, making it essential that we test our smart contracts before we deploy them.

`truffle.js` and `truffle-config.js`: config files used to store the network settings for deployment. Truffle needs two config files because on Windows having both truffle.js and truffle.exe in the same folder might generate conflicts. Long story short - if you are running Windows, it is advised to delete truffle.js and use truffle-config.js as the default config file. Check out Truffle's official [documentation](https://trufflesuite.com/docs/truffle/reference/configuration) to further your understanding.

But why should I use this directory structure?

Well, there's are a few good reasons. First, Truffle will not work as expected if you change the names of these folders.

Second, by adhering to this convention your projects will be easily understood by other developers. To put it short, using a standard folder structures and code conventions make it easier if you expand or change your team in the future.

## truffle-hdwallet-provider
In this lesson, we will be using **Infura** to deploy our code to Ethereum. This way, we can run the application without needing to set up our own Ethereum node or wallet. However, to keep things secure, Infura does not manage the private keys, which means it can't sign transactions on our behalf. Since deploying a smart contract requires Truffle to sign transactions, we are going to need a tool called `truffle-hdwallet-provider`. Its only purpose is to handle the transaction signing.

> Note: Maybe you are asking why we chose not to install truffle-hdwallet-provider in the previous chapter using something like:

```shell
npm install truffle truffle-hdwallet-provider
```

Well... the truffle init command expects to find an empty directory. If there's any file there, it will error out. Thus, we need to do everything in the correct order and install truffle-hdwallet-provider after we run truffle init.

# Compiling the Source Code

The **Ethereum Virtual Machine** can't directly understand Solidity source code as we write it. Thus, we need to run a compiler that will "translate" our smart contract into machine-readable bytecode. The virtual machine then executes the bytecode, and completes the actions required by our smart contract.

Curious about how does the bytecode look like? Let's take a look:
```shell
"0x60806040526010600155600154600a0a6002556201518060035566038d7ea4c6800060085560006009556046600a55336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1..."
```

Next, we copied all our smart contracts into the ./contracts folder. Now the project structure should look like this:

```shell
├── contracts
    ├── Migrations.sol
    ├── contract.sol
├── migrations
└── test
```
Everything is set up properly. Let's compile our project.

```shell
truffle compile
```
This command should create the build artifacts and place them in the `./build/contracts` directory.

# Migrations

To deploy to Ethereum we will have to create something called a `migration`.

Migrations are JavaScript files that help **Truffle** deploy the code to `Ethereum`. 
Note that truffle init created a special contract called Migrations.sol that keeps track of the changes you're making to your code. The way it works is that the history of changes is saved onchain. Thus, there's no way you will ever deploy the same code twice.

## Creating a New Migration
We'll start from the file truffle init already created for us- ./contracts/1_initial_migration.js. Let's take a look at what's inside:

```shell
var Migrations = artifacts.require("./Migrations.sol");
module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
```

Pretty straightforward, isn't it?

First, the script tells Truffle that we'd want to interact with the `Migrations` contract.

Next, it exports a function that accepts an object called `deployer` as a parameter. This object acts as an interface between you (the developer) and Truffle's deployment engine.

# Configuration Files

We'll have to edit the configuration file to tell Truffle the networks we want to deploy to.

## Ethereum Test Networks
Several public **Ethereum** test networks let you test your contracts for free before you deploy them to the main net (remember once you deploy a contract to the main net it can't be altered). These test networks use a different consensus algorithm to the main net (usually PoA), and Ether is free to encourage thorough testing.

In this lesson, we will be using Rinkeby, a public test network created by The Ethereum Foundation.

## The truffle.js configuration file
Now, let's take a look at the default **Truffle** configuration file:

```shell
$ cat truffle.js
/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 *
 * mainnet: {
 *     provider: function() {
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>')
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */
 ```

It is just an empty shell. Thus, we'll be required to update this file to allow us to deploy contracts to Rinkeby and the Ethereum mainnet.

## Truffle's HD Wallet Provider
Remember the second chapter?

We asked you to install an additional package called `truffle-hdwallet-provider` that helps Truffle sign transactions.

Now, we want to edit our configuration file to use HDWalletProvider. To get this to work we'll add a line at the top of the file:

```shell
var HDWalletProvider = require("truffle-hdwallet-provider");
```
Next, we'll create a new variable to store our mnemonic:
```shell
var mnemonic = "onions carrots beans ...";
```
Note that we don't recommend storing secrets like a mnemonic or a private key in a configuration file.

...but why?

Config files are often pushed to GitHub, where anyone can see them, leaving you wide open to attack 😱! To avoid revealing your mnemonic (or your private key!), you should read it from a file and add that file to `.gitignore`. We'll show you how to do this later.

To keep things simple in this case, we've copied the mnemonic and stored in a variable.

## Set up Truffle for Rinkeby and Ethereum main net
Next, to make sure Truffle "knows" the networks we want to deploy to, we will have to create `two separate objects`- one for `Rinkeby` and the other one for the Ethereum `main net`:
```shell
networks: {
  // Configuration for mainnet
  mainnet: {
    provider: function () {
      // Setting the provider with the Infura Mainnet address and Token
      return new HDWalletProvider(mnemonic, "https://mainnet.infura.io/v3/YOUR_TOKEN")
    },
    network_id: "1"
  },
  // Configuration for rinkeby network
  rinkeby: {
    // Special function to setup the provider
    provider: function () {
      // Setting the provider with the Infura Rinkeby address and Token
      return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/YOUR_TOKEN")
    },
    // Network id is 4 for Rinkeby
    network_id: 4
  }
```
> Note: the provider value is wrapped in a function, which ensures that it won't get initialized until it's needed.

## Wrapping it up
Now, let's put these piece together and have a look at how our config file should look:
```shell
// Initialize HDWalletProvider
const HDWalletProvider = require("truffle-hdwallet-provider");

// Set your own mnemonic here
const mnemonic = "YOUR_MNEMONIC";

// Module exports to make this configuration available to Truffle itself
module.exports = {
  // Object with configuration for each network
  networks: {
    // Configuration for mainnet
    mainnet: {
      provider: function () {
        // Setting the provider with the Infura Mainnet address and Token
        return new HDWalletProvider(mnemonic, "https://mainnet.infura.io/v3/YOUR_TOKEN")
      },
      network_id: "1"
    },
    // Configuration for rinkeby network
    rinkeby: {
      // Special function to setup the provider
      provider: function () {
        // Setting the provider with the Infura Rinkeby address and Token
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/YOUR_TOKEN")
      },
      // Network id is 4 for Rinkeby
      network_id: 4
    }
  }
};
```

## Get some Ether
Before doing the deployment, make sure there is enough Ether in your account. The easiest way to get Ether for testing purposes is through a service known as a faucet. We recommend the [Authenticated Faucet](https://faucet.rinkeby.io/) running on Rinkeby. Follow the instructions, and within a few minutes, your address will be credited with some Ether.

It's time to deploy to `Rinkeby`: 

```shell
run truffle migrate --network rinkeby
```

> Note: migrations are being executed in order😉.


It's time to deploy to `Mainnet`: 

```shell
run truffle migrate --network mainnet
```

```