# Jamon.dev -- QB64 website

This website is built in [QB64](https://qb64.com/), which is a slightly more modern version of the venerable old QBasic I used to do. Yes, it's weird! But ... it works.

## The Code

You can find all of the code in `./jamondotdev.bas`. I started building a way to serve up static pages in `./pages/*.html`, but haven't finished it yet.

It includes a small router that handles subpages like `http://localhost:8080/subpage`. Check out the `handle_request` function.

## Building

Install a version of QB64 and open the `jamondotdev.bas` file. You can then create an executable from there, or run it directly.

Once it's running (you'll see a terminal pop up with a blank black screen), go to http://localhost:8080. The website will pop up and you'll see something like:

```
Request handled in .0060625 seconds.
Completed request for: /
 from TCP/IP:46557:127.0.0.1
 using Mozilla/5.0 (Macintosh...)
```

...show up in the terminal.

I started working on supporting CSS and JS files, and may complete that at some point.

## Hosting

I spent a couple days trying to figure out how to host this, but it seems that it's not practical. The closest I got was a DigitalOcean Ubuntu Droplet, but since QB64 doesn't natively support operating systems without GUIs (this is rather ironic to me), it just errors with this and quits:

```
freeglut (./qb64):
Error: Process completed with exit code 1.
```

Unfortunate, as it would be really cool to host this somewhere!

I _could_ host it from my home Mac and serve it up using a dynamic IP, but ... eh.
