# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is jamon.dev, a personal website built with QB64 (a modern QBasic derivative). The backend web server is written entirely in QB64 (`app.bas`), serving HTML/CSS/JS content. This is an intentionally unconventional choice for nostalgia.

## Common Commands

```bash
./bin/dev              # Kill running instances, compile, and run locally (requires qb64 in PATH)
./bin/build            # Compile app.bas to executable using local qb64 folder
./app                  # Run the compiled server (listens on localhost:6464)

./bin/deploy           # Deploy to DigitalOcean via rsync
./bin/deploy --compile # Deploy and recompile on server
./bin/restart          # Restart remote server
```

## Architecture

**Server (`app.bas`)**: Single-file QB64 web server handling up to 8 concurrent TCP connections. Key constants:
- `DEFAULT_HOST` / `DEFAULT_PORT`: Set to `localhost:6464` for local, change for production
- `ENABLE_LOG`: Set to `1` for debug logging, `0` for production
- `MAX_CLIENTS = 8`, `EXPIRY_TIME = 240` seconds

**Web Content (`web/`)**:
- `pages/*.html` - Individual page content (16 pages)
- `static/` - CSS, JS, images
- `head.html`, `header.html`, `footer.html` - Shared partials

**Routing**: Hard-coded in the `handle_request` function in `app.bas`. URIs map directly to page files.

## Development Notes

- Pages use `<!--TITLE ... -->` comment for page title extraction
- Server runs on port 6464, access via `http://localhost:6464`
- Production uses CloudFlare proxy for HTTPS (`.dev` domains require SSL)
- Debug logs go to terminal locally, `/var/log/syslog` on production
- QB64 has memory limits for streaming large files
