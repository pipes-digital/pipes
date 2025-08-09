# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Run the application
```bash
# Start the development server
bundle exec puma -e development
```

### Install dependencies
```bash
# Install Ruby gems
bundle install
```

### Run tests
```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby tests/feedblock.rb
bundle exec ruby tests/sortblock.rb
```

## Architecture Overview

Pipes CE is a Ruby/Sinatra application that provides a graphical interface for data manipulation through connected blocks, using RSS as the internal format.

### Core Components

**Block System Architecture**
- `block.rb` - Base Block class that all blocks inherit from. Implements recursive processing where blocks call their inputs before processing.
- `blocks/` directory contains specialized block implementations (FeedBlock, FilterBlock, CombineBlock, etc.)
- Each block has `inputs` (data sources), `options` (configuration), and a `process` method for data transformation
- Blocks process data recursively: parent blocks call child blocks' `run()` method to get processed data

**Main Application Components**
- `server.rb` - Sinatra web application with routes and authentication (uses Portier for passwordless login)
- `pipe.rb` - Manages pipe execution, creates block chains from JSON definitions, handles caching
- `database.rb` - Database operations for users, pipes, cache, and webhooks
- `user.rb` - User management and authentication
- `downloader.rb` - Handles HTTP downloads with caching

**Data Flow**
1. Pipes are stored as JSON structures defining blocks and their connections
2. When executed, a Pipe object creates a tree of Block objects based on the JSON
3. The output block's `run()` method triggers recursive processing of all input blocks
4. Each block processes its inputs and returns RSS/XML data
5. Results are cached for 10 minutes (600 seconds) to improve performance

**Key Implementation Details**
- Uses SQLite for data storage (pipes, users, sessions, cache)
- RSS is the internal data format - all blocks input/output RSS feeds
- Blocks can have both data inputs and text inputs (user parameters)
- Authentication via Portier (passwordless email-based login)
- Session persistence using Moneta with SQLite backend
- Background thread pool for cleanup tasks (cache, webhooks)