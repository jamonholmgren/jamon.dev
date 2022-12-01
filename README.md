# Jamon.dev -- QB64 website

This website is built in [QB64](https://qb64.com/), which is a slightly more modern version of the venerable old QBasic I used to do. Yes, it's weird! But ... it works.

## The Code

You can find all of the code in `./app.bas`. I started building a way to serve up static pages in `./pages/*.html`, but haven't finished it yet.

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

I spent several days trying to figure out how to host this, and finally got it working!

1. Create a Digital Ocean Ubuntu droplet (use my [affiliate link](https://m.do.co/c/a78810eb0cff) to help me recoup several minutes of my time spent on this 😂)
2. Add your SSH public key so you can SSH into the droplet
3. Add a domain to that Droplet ... I used a subdomain. Note that since this doesn't support HTTPS, you'll need to use a .com or other TLD that works with bare HTTP -- it confused me for a while why my .dev domain always redirects to HTTPS, but that's part of the TLD rules for .dev
4. SSH into the droplet with something like `ssh root@yourdomain.com` and run these commands:
5. `curl -L -o ./qb64_lnx.tgz.gz https://github.com/QB64Official/qb64/releases/download/v2.1/qb64_dev_2022-09-08-07-14-00_47f5044_lnx.tar.gz`
6. `tar -xf ./qb64_lnx.tgz.gz`
7. `mv ./qb64_2022-09-08-23-38-12_47f5044_lnx ./qb64`
8. `nano ./qb64/setup_lnx.sh`
9. In this setup file, comment out the first line that says "exit 1" ... it should be in the "you're trying to run as root" if block. Just put a # in front of it to comment it out
10. Press Ctrl+X and enter to save & exit nano
11. Now run the setup script to compile for this architecture (won't work without this!): `cd ./qb64 && ./setup_lnx.sh && cd -`
12. Run `./qb64/qb64 --help` to ensure it works
13. Now you have a version of qb64 to compile the source. Exit out of the ssh shell with `exit`
14. When you're ready to deploy, edit the `./bin/env.sh` script to have your info, and then run `./bin/deploy`
15. If you need to restart, use `./bin/restart` or `./bin/reboot`
16. To watch server logs, go into your SSH and then run `tail -f /var/log/syslog`
