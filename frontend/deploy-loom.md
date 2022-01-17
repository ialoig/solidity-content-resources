# Use Truffle with Loom!

## Loom Basechain
Now, if you want to build DApps on Ethereum, there's one thing you should be aware of - on the main net, users are required to pay gas fees for every transaction. But this isn't ideal for a user-facing DApp or a game. It can easily ruin the user experience.

Conversely, on `Loom`, your users can have much speedier and gas-free transactions, making it a much better fit for games and other non-financial applications.

That's not all - deploying to Loom is no different from deploying to Rinkeby, or to the Ethereum main net. If you know how to do one, you also know how to do the other.

In the next chapters, we'll be walking you through deploying to Loom.

## loom-truffle-provider
We at Loom are using Truffle to build, test, and deploy our smart contracts. To make our life easier, we developed something called a provider that lets Truffle deploy to Loom just like it deploys to Rinkeby or Ethereum main net.

```shell
npm install loom-truffle-provider
```

# Deploy to Loom Testnet
In this chapter, we’re going to deploy our smart contract to the Loom Testnet, but before doing the deployment, some prep work is needed.

First, we should create our own `Loom private key`. The easiest way to do it is by downloading and installing Loom according to this tutorial.

Next, creating a private key is as as simple as this:

```shell
$./loom genkey -a public_key -k private_key
local address: 0x42F401139048AB106c9e25DCae0Cf4b1Df985c39
local address base64: QvQBE5BIqxBsniXcrgz0sd+YXDk=
$cat private_key
/i0Qi8e/E+kVEIJLRPV5HJgn0sQBVi88EQw/Mq4ePFD1JGV1Nm14dA446BsPe3ajte3t/tpj7HaHDL84+Ce4Dg==
```

> Note: Never reveal your private keys! We are only doing this for simplicity's sake.

## Updating truffle.js
The first thing we are required to do is to initialize `loom-truffle-provider`. The syntax is similar to the one we've already used for HDWalletProvider:

```shell
const LoomTruffleProvider = require('loom-truffle-provider');
```
Next, we'll have to let Truffle know how to deploy on Loom testnet. To do so, let's add a new object to `truffle.js`

```shell
loom_testnet: {
  provider: function() {
    const privateKey = 'YOUR_PRIVATE_KEY'
    const chainId = 'extdev-plasma-us1';
    const writeUrl = 'http://extdev-plasma-us1.dappchains.com:80/rpc';
    const readUrl = 'http://extdev-plasma-us1.dappchains.com:80/query';
    return new LoomTruffleProvider(chainId, writeUrl, readUrl, privateKey);
    },
  network_id: '9545242630824'
}
```


It's time to deploy to `loom_testnet`: 
```shell
truffle migrate --network loom_testnet
```


# Deploy to Basechain
This chapter will walk you through the process of deploying to `Basechain` (that is our Mainnet).

Here's a brief rundown of what you'll do in this chapter:

- Create a new private key.
- Creating a new private key is pretty straightforward. But since we're talking about deploying to the main net, it's time to get more serious about security. Thus, we'll show you how to securely pass the private key to Truffle.
- Tell Truffle how to deploy to Basechain by adding a new object to the truffle.js configuration file.
- Whitelist your deployment keys so you can deploy to Basechain.
- Lastly, we wrap everything up by actually deploying the smart contract.

## Create a new private key
You already know how to create a private key. However, we must change the name of the file in which we're going to save it:

```shell
./loom genkey -a mainnet_public_key -k mainnet_private_key
local address: 0x07419790A773Cc6a2840f1c092240922B61eC778
local address base64: B0GXkKdzzGooQPHAkiQJIrYex3g=
```

## Securely pass the private key to Truffle
The next thing we want to do is to prevent the private key file from being pushed to GitHub. To do so, let's create a new file called `.gitignore`:

```shell
touch .gitignore
```
Now let's "tell" GitHub that we want it to ignore the file in which we saved the private key by entering the following command:

```shell
echo mainnet_private_key >> .gitignore
```

Now that we made sure our secrets aren't going to be pushed to GitHub, we must edit the `truffle.js` configuration file and make it so that Truffle reads the private key from this file.

Let's start by importing a couple of things:

```shell
const { readFileSync } = require('fs')
const path = require('path')
const { join } = require('path')
```

Next, we would want to define a function that reads the private key from a file and initializes a new `LoomTruffleProvider`:

```shell
function getLoomProviderWithPrivateKey (privateKeyPath, chainId, writeUrl, readUrl) {
  const privateKey = readFileSync(privateKeyPath, 'utf-8');
  return new LoomTruffleProvider(chainId, writeUrl, readUrl, privateKey);
}
```

Pretty straightforward, isn't it?

## Tell Truffle how to deploy to Basechain
Now, we must let Truffle know how to deploy to Basechain. To do so, let's add a new object to `truffle.js`
```shell
basechain: {
  provider: function() {
    const chainId = 'default';
    const writeUrl = 'http://basechain.dappchains.com/rpc';
    const readUrl = 'http://basechain.dappchains.com/query';
    return new LoomTruffleProvider(chainId, writeUrl, readUrl, privateKey);
    const privateKeyPath = path.join(__dirname, 'mainnet_private_key');
    const loomTruffleProvider = getLoomProviderWithPrivateKey(privateKeyPath, chainId, writeUrl, readUrl);
    return loomTruffleProvider;
    },
  network_id: '*'
}
```

At this point, your `truffle.js` file should look something like the following:

```shell
// Initialize HDWalletProvider
const HDWalletProvider = require("truffle-hdwallet-provider");

const { readFileSync } = require('fs')
const path = require('path')
const { join } = require('path')


// Set your own mnemonic here
const mnemonic = "YOUR_MNEMONIC";

function getLoomProviderWithPrivateKey (privateKeyPath, chainId, writeUrl, readUrl) {
  const privateKey = readFileSync(privateKeyPath, 'utf-8');
  return new LoomTruffleProvider(chainId, writeUrl, readUrl, privateKey);
}

// Module exports to make this configuration available to Truffle itself
module.exports = {
  // Object with configuration for each network
  networks: {
    // Configuration for mainnet
    mainnet: {
      provider: function () {
        // Setting the provider with the Infura Rinkeby address and Token
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
    },

    basechain: {
      provider: function() {
        const chainId = 'default';
        const writeUrl = 'http://basechain.dappchains.com/rpc';
        const readUrl = 'http://basechain.dappchains.com/query';
        return new LoomTruffleProvider(chainId, writeUrl, readUrl, privateKey);
        const privateKeyPath = path.join(__dirname, 'mainnet_private_key');
        const loomTruffleProvider = getLoomProviderWithPrivateKey(privateKeyPath, chainId, writeUrl, readUrl);
        return loomTruffleProvider;
        },
      network_id: '*'
    }
  }
};
```

## Whitelist your deployment keys
Before deploying to Basechain, you need to whitelist your keys by following the instructions from our [Deploy to Mainnet guide](https://loomx.io/developers/en/deploy-loom-mainnet.html#deposit-loom-to-basechain).
