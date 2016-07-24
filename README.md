
# An Anarcho-Syndicalist Commune

Sumpreme executive power derives from a mandate from the masses! (not some farcical aquatic ceremony)

This project will implement an "anarcho-syndicalist commune" in Ethereum, as defined by Monty Python:
https://youtu.be/JvKIWjnEPNY?t=1m15s

Some key points:
 * Take it in turns to be an executive-officer-for-the-week
 * All the decisions of that officer have to be ratified at a special bi-weekly meeting (interpreted as two times per week)
 * A simple majority is sufficient for purely internal affairs, or a two-thirds majority in the case of more major matters

It is meant as a light-hearted project, not a "serious" contract to put lots of funds at risk. It's still in-progress, not ready even for alpha testing.

The current plan is that a chat room will be under the control of the "commune". There will be some cost to activate an account, some cost to speak (both globally, and per person). Also, the accounts will have nicknames. All of these things will go through the voting process.

For now, only the chat is undergoing implementation, with a "king" address that can make all these decisions unilaterally. In the future, the commune contract will replace the king in chat. The contract will have unilateral control, but will only execute on decisions through the rules outlined above.

## Local Deployment

The chat is much too slow to execute in Mix, the IDE. For any significant testing, deploy locally with:

1. Run `geth --testnet` (or whatever private ethereum network you want, on port 8545) - unlock the account and start the miner
1. In Mix: `Deploy -> Deploy to Network` - follow all the instructions
2. `cp $WEBTHREE-UMBRELLA/web3.js/dist/web3.min.js $THIS_REPO/package/www/.`
3. in $THIS_REPO/package/www/index.html move the deployment.js script import below the web3.js import and initialization (this import is a workaround until the mist browser is generally available)
4. in $THIS_REPO/package/www run `python -m SimpleHTTPServer` (assuming python 2.*)
5. Open http://localhost:8000
5. In the javascript console, run `Chat.crown([the Autonomous Collective address]); Collective.setChat([the Chat contract address]);`
6. Send a message using the UI
7. Set the nickname to the address used to send the message, also using the UI
