# Pipes CE

[![CI](https://github.com/pipes-digital/pipes/actions/workflows/ci.yml/badge.svg)](https://github.com/pipes-digital/pipes/actions/workflows/ci.yml)

The open source CE edition of pipes.digital

![pipes ce example](https://www.onli-blogging.de/uploads/pipesce.png)

## The CE edition

[pipes.digital](https://www.pipes.digital) is a spiritual successor to Yahoo Pipes, a graphical interface to get data from the web and to manipulate it by connecting block. It's heavily focused on the concept of feeds, that data flows item by item from block to block, with RSS as the default and internally used format. The CE edition is the FOSS core of pipes.digital, minus things like a pricing page and user plans.

To get an impression of how pipes works without installing anything, try [pipes.digital](https://www.pipes.digital/) first.

## How to install and run

Clone this repository. You need to install Ruby and the bundler gem:

    gem install bundler

Then cd into the cloned repository and download the required gems with bundler:

    bundle install

Some gems won't install without some additional requirements, like **sqlite3**.

When everything is installed you can start the server:

    bundle exec puma -e development

### Logging in

Pipes CE uses [portier](https://portier.github.io/) to provide an easy passwordless login. After the installation you can immediately login with every email address you control.

## Development

[This blog article](https://www.pipes.digital/blog/8/The%20Architecture%20and%20Software%20behind%20Pipes) explains the architecture and most of the software used. It is a good starting point if you want to make changes.

The code is dual licensed: AGPL, but with the exception of not having to share code run on pipes.digital, the founding project (this so far only touches stuff like the pricing page, as explained above).

Feature and Pull Requests are welcome. If in doubt open an issue before investing the work to discuss deeper changes, though those are also welcome.

You can also join [the gitter channel](https://gitter.im/pipes-digital/community).
