This document will contain notes for the development of Pipes. It is meant as a reminder for me and as a starting point for other developers.

## Getting involved

Ideally, open an issue to discuss your plans or send me a mail. I might be able to help plan your changes. Then you can send in a PR with your changes. I need to understand them, but if I do and they don't collide with what is there I will merge.

## Architecture

Pipes has a very small architecture, with few files and classes. It is thus easy to read the whole code, but it is conceptually dense. Read through this section do understand the core concepts.

### Key Implementation Details

- Uses Ruby/Sinatra on the backend, Raphaël on the frontend for the editor, otherwise Pure.CSS as CSS library
- Authentication via Portier (passwordless email-based login)
- Pipes are stored as JSON structures defining blocks and their connections
- When executed, a Pipe object creates a tree of Block objects based on the JSON
- The output block's `run()` method triggers recursive processing of all input blocks
- Results are cached for 10 minutes (600 seconds) to improve performance
- Uses SQLite for data storage (pipes, users, sessions, cache)
- Blocks can have both data inputs and text inputs (user parameters)
- RSS is the internal data format for feed type blocks - those blocks input/output RSS feeds
- Data blocks rely on a data layer called water instead - it contains a hash that gets converted to JSON or XML

### Backend

Pipes is on the backend a Ruby application. It uses Sinatra as a web framework, with Portier for logins. SQLite is used as a database, with all code that gets and sets data in the **database.rb**. For the functionality, each block as seen in the frontend has a corresponding ruby class under **blocks/**. Blocks have a function `process` where the custom functionality of each block is defined, again in Ruby code. A pipe is a graph of blocks, created in **pipe.rb**'s `createInputs` based on the JSON the frontend produced. There is one root (the output block) of the graph. The pipe class calls `run` on the output block, which then calls `run` on its inputs, which call `run` on their inputs and so on. In `run` the `process` function is called and its output returned.

What that output is depends on the type of blocks. There are two.

Blocks inheriting directly from `Block` will return an RSS object (from the [ruby rss gem](https://github.com/ruby/rss)). They are called feed type blocks in the user documentation. The idea is that other blocks work with that object without always having to parse an RSS string, as it was done initially. Blocks will usually iterate over the input feed, create a new RSS object with `RSS::Maker.make("rss2.0")`, use the `transferChannel` function (defined in **block.rb**) to copy the channel and then do their work on the items, copying items with `transferData` (also defined in **block.rb**) when possible. The feed block is the main entry point for those pipes and creates the initial RSS object, with the help of the feedparser gem if Ruby's RSS parser does not work with the fetched data. All other blocks of that type can now assume that they get a valid RSS object, and they function accordingly on channel items etc.

Blocks inheriting fom `WateredBlock` do not return an RSS object, but a `Water` object (**water.rb**) - it is what flows in a pipe. This is a data abstraction layer. They are called data blocks in the user documentation. `Water` can `absorb` XML or JSON (this could be extended for all hierarchical data representation formats) and saves this internally as a hash. That hash can in the end be `solidify`ed into XML or JSON. The idea is that blocks can work directly on the internal hash, without having to use tools specialized for either XML or JSON. But it turned out that JSONPath gems like Janeway were helpful to work with the hash. These type of blocks can assume nothing about the structure of the data they work on, users have to select the relevant fields. Water has an `outline` function that emits all possible JSONPaths, with which the autocomplete function is implemented.

The **server.rb** defines all the web endpoints. It is supposed to not do too much work itself, but call other classes like `Pipe`, `Database` or `User`. The other relevant class is in **downloader.rb**. `Downloader` is a wrapper around the gem HTTParty. It is simple, but it does implement throttling, respects http 429 headers (so we don't get banned as easily) and is a core functionality of almost all pipes.


#### Core helpers/gems

Partly a recap, but this backend architecture makes Pipes rely on a number of Ruby gems. Especially:

 * Sinatra for the web functionality (with Rack)
 * RSS as the data representation and tool used for regular `Block`s
 * OXML, currently a fork of it, as the tool that parses XML into the hash in `WateredBlock`s (based on the very fast Ox gem)
 * JSON to parse JSON input files in `WateredBlock`s, and for the pipe representation
 * Janeway, the JSONPath gem used to implement the functionality of the existing `WateredBlock`s
 * HTTParty for the downloads
 * throttle-queue to limit the amount of parallel downloads
 * sinatra-portier for user logins

### Frontend

On the frontend, you can separate Pipes into two parts. Most of the pages - there aren't that many - are static HTML generated by the ERB templates under **views/**. Also the editor page is created that way, but it is also the bigger second part: The editor functionality is implemented in Javascript via the Raphaël library, with Raphaël creating SVG objects on a canvas. It is completly managed in the (overly) big Javascript file **public/pipes-ui.js**. HTML input elements are absolutely positioned on that canvas to provide the user inputs, and manually culled or re-created when the user scrolls.

How the blocks are placed on that canvas, filled and connected gets serialized in a JSON object. That JSON object gets sent to the backend, where it is stored in the database on save or used to create the ruby blocks when a pipe runs. That's the mechanism with which the user creates a pipe.

The pipes-ui.js has functions for each block, like `FilterBlock`. Those functions .call the `Block` function for shared functionality, like the input and output objects. Each of the `new`ed functions for blocks on the canvas are stored in a global `blocks` array, connections between blocks are stored in a global `connections` array. These lists are later used to serialize the editor state.

The other pages, the HTML parts of the site, use the Pure.CSS framework. That was already a weird choice when the project started, but it was a bit of an easter egg, to reference the Yahoo! background of Pipes by using a Yahoo! CSS library. Pure provides some classes and default stylings that are used throughout the site, overriden in **public/style.css** where necessary.

Apart from that, the site has a interaction pattern of using vex.js' dialog boxes to ask for confirmation and to pop up text inputs.

#### Core libraries

The frontend thus depends on:

 * Raphaël, as it paints and manages the blocks with their elements and connections
 * Pure.CSS, the CSS framework used
 * Interact.js for the drag'n drop functionality in the editor
 * Font Awesome for most of the icons
 * vex for dialog boxes
 * vkBeautify to pretty print JSON in the block inspector
 * XMLDisplay to pretty print XML in the block inspector

## Possible future steps

Pipes being a single monolith might be strange. There is very separate functionality: On one side the web application that handles incoming requests and renders the HTML the user sees, on the other the Ruby code that runs the pipes. This could be separated.
It wasn't done yet because attempts in that direction failed so far. Once very late, when after launch the performance impact was too high for the existing usage, so the change had to be reverted. But a better implementation might even help with managing server ressources. Or, it is possible that since all pipe requests involve the webserver aspect - and the webserver requests that don't run pipes are too rare -, doing it all with the webworkers has an inherent performance benefit. To be investigated.

It might be a good idea to implement the pipe editor with different technology. Raphaël is quite old and hasn't seen a release in years. That is not really a problem since SVGs are very stable, and so is Javascript, but browser compatibility issues might still become an issue. Not only with Raphaël itself, also the approach to mix SVGs with absolutely positioned HTML input elements is not bulletproof. We have already seen issues [with Safari](https://github.com/pipes-digital/pipes/issues/86), and in the past there were similar issues with Firefox and Chrome.
One option for that rebuild is Flutter - building only one part a webapp is supported (so, one page, like the editor), the way it paints UI elements on a canvas would fit and in general it would allow for a more modern UI (e.g. with more animations), plus I do like the Dart programming language, it meshes well with Ruby. On the other hand, Flutter and its ecosystem not being as stable as Vanilla JS and Raphaël could make this change become a future maintenance problem.

The other parts of the frontend could also use a modernization. If it results in a more modern looking design or if it makes some design elements easier to implement, it might be time to replace the Pure.CSS modules. Either with a more modern CSS Framework or library or just with modern HTML and CSS.

The data blocks are new and not complete. More feed type blocks should get a data block equivalent. Not all of them - some are too focused on feed structure, but others would work well with the new approach, like the webhook block. There also seem to be opportunities for some old and new blocks to work better together, especially the extract and the feed builder block should have options there. And there might be new kind of blocks that are possible now, that were not before.

One possibility of a new block is an LLM block, though that not even depends on the new data abstraction approach. Pipes should never jump on the AI hype, it collides way too much with the history of this software and the stability that is needed here. But, LLMs are very good in changing data structures, transforming between them for example or adding missing parts. And blocks might actually be a nice UI abstraction to work with an LLM, the inputs being the data to be worked on, together with a written prompt from the userinput. There is potential here to make actually good use of the "AI" technology.

Test coverage is not sufficient to be confident in changes. Not too much an issue when it was just about keeping the software/the server stable, but not helpful when doing bigger changes, like [when I reworked](https://github.com/pipes-digital/pipes/issues/141) what feed type blocks output. All blocks should get some tests to at least secure basic functionality. Pipes internals could also use some (though frankly, the surface is so small that this is quite optional).