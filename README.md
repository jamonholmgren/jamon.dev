# Jamon.dev -- QB64 website

This website is built in [QB64](https://qb64.com/). Yes, it's weird! But ... it works.

## Hosting

I'm hosting the website on DigitalOcean's smallest "droplet", running Ubuntu Linux.

To make a compatible build, it's a little annoying. You have to be running Ubuntu.

Best way is with Parallels. I tried with VirtualBox and ... well, that didn't go so well. Good luck, if you're not willing to pay for Parallels!

You can, of course, have a different computer running Linux, or if you're running Linux already, you're good to go.

So I installed a version of Ubuntu on my Mac Studio using Parallels. I ran the virtual machine and opened up Firefox. I downloaded QB64 from https://qb64.com, and extracted it.

I went into a terminal, cd'd into the extracted folder, and ran this:

```
sudo apt-get update -y
./setup_lnx.sh
```

This should install all the dependencies.

Now, to test the compiler, do this:

```
echo "PRINT 1" > ./test.bas
./qb64 ./test.bas -c -o ./test
./test
```

You should see a terminal window appear that shows just the number 1 in it.

To make qb64 available everywhere, I made a softlink to it in ./usr/local/bin/qb64

```

```

I then clicked the Parallels menu Devices -> Sharing -> Add a folder, and shared this project with the Ubuntu VM. Then I could compile the ./jamondotdev.bas file anytime.

```
./qb64 ../JamonBAS/jamondotdev.bas -c -o ./jamondotdev_lnx
```

It appears that Ubuntu doesn't like trying to read files, for some reason. This causes it to not compile.

On DigitalOcean, I provisioned a new "Droplet" using Ubuntu, and then assigned a subdomain (qb64.jamon.dev) to that Droplet. I had to add an A record to qb64.jamon.dev pointing the proper IP, which you can see in the Droplet dashboard.

After provisioning the droplet, I ssh'd into it.

(TODO!)
