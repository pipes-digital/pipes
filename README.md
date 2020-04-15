# Pipes CE
The open source CE edition of pipes.digital

## The CE edition

[pipes.digital](https://www.pipes.digital) is a spiritual successor to Yahoo Pipes, a graphical interface to get data from the web and to manipulate it by connecting block. It's heavily focused on the concept of feeds, that data flows item by item from block to block, with RSS as the default and internally used format. The CE edition is the FOSS core of pipes.digital, minus things like a pricing page and user plans.

## How to install and run

Fork this repository. You need to install Ruby and the bundler gem:

    gem install bundler

Then cd into the forked repository and download the required gems with bundler:

    bundle install

Some gems won't install without some additional requirements, like **sqlite3**.

When everything is installed you can start the server:

    bundle exec puma -e development

### Activating the twitter block

The Twitter block accesses the official Twitter API, the documentation to get started is on [developer.twitter.com](https://developer.twitter.com/en/docs/basics/getting-started) and the [repo of the twitter gem](https://github.com/sferik/twitter). Four variables need to be filled with environment variables you can provide when starting the server:

   TWITTER_CONSUMER_KEY
   TWITTER_CONSUMER_SECRET
   TWITTER_ACCESS_TOKEN
   TWITTER_ACCESS_TOKEN_SECRET

### Logging in

Pipes CE uses [portier](https://portier.github.io/) to provide an easy passwordless login. After the installation you can immediately login with every email address you control.

## Contributions

The code is dual licensed: AGPL, but with the exception of not having to share code run on pipes.digital, the founding project (this so far only touches stuff like the pricing page, as explained above).

Feature and Pull Requests are welcome. If in doubt open an issue before investing the work to discuss deeper changes, though those are also welcome.