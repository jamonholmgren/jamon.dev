# Jamon.dev -- QB64 website

This website is built in [QB64](https://qb64.com/), which is a slightly more modern version of the venerable old QBasic I used to do. Yes, it's weird! But ... it works!

<img src="https://user-images.githubusercontent.com/1479215/209062980-5706a963-b880-4702-a1db-3195dff4c297.png" width="500" style="margin: 0 auto;" />
</center>

## The Code

You can find all of the QB64 code in `./app.bas` along with pages in `./web/pages/*.html`, CSS and JS in `./web/static/*`, and common partial sections in `./web/*`.

It includes a small hard-coded router that handles subpages like `http://localhost:8080/subpage`. Check out the `handle_request` function. I may make this dynamic in the future.

## Building Locally

Install a version of QB64 [from the website](https://qb64.com/) (_not_ the ./bin/install_qb64 script -- that's only for the remote server) and open the `app.bas` file. You can then create an executable from there, or run it directly.

Once it's running (you'll see a terminal pop up with a blank black screen), go to `http://localhost`. The website will pop up and you'll see something like:

```
Request handled in .0060625 seconds.
Completed request for: /
 from TCP/IP:46557:127.0.0.1
 using Mozilla/5.0 (Macintosh...)
```

...show up in the terminal.

You can also run `./bin/build` to build the executable and then run it.

```bash
./bin/build
./bin/run
```

## Hosting

I spent several days trying to figure out how to host this, and finally got it working!

1. Create a Digital Ocean Ubuntu droplet (use my [affiliate link](https://m.do.co/c/a78810eb0cff) to help me recoup the hours of my time spent on getting all this to work!)
2. Add your SSH public key to the Droplet through so you can SSH into the droplet
3. Add a domain to that Droplet. Note that since this server doesn't support HTTPS out of the box, you'll need to use something like CloudFlare as a proxy in front of the server to enable HTTPS.
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
14. When you're ready to deploy, edit the `./bin/env.sh` script to have your server's info, and then run `./bin/deploy`. You can add a `--compile` flag to make it compile the QB app, if anything changed in app.bas.
15. If you need to restart the QB server on DigitalOcean, use `./bin/restart` or `./bin/reboot` for a full reboot of the droplet
16. To watch server logs, go into an SSH session on your droplet and then run `tail -f /var/log/syslog`

## Gotchas

- If you're using a .dev domain like I am, you MUST use SSH. So how I handled this was I hosted the domain on DigitalOcean, and then used CloudFlare as a proxy in front of it. This way, I can use CloudFlare's free SSL certificate to enable HTTPS.
- There seems to be memory limits. I wasn't able to stream large HTML / CSS / JS files. I haven't figured out what those memory limits are, yet, but I'll update here when I do.
