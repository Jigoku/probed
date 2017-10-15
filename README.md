# probed
A module tracker for Linux

![screenshot_2017-10-15_23-00-20](https://user-images.githubusercontent.com/1535179/31589635-a88472b4-b1fc-11e7-9fb0-8d691e481bde.png)

### What is this?
probed is a tiny script for tracking used kernel modules over time.   
This can be very useful if you choose to compile your kernel with `make localmodconfig`

### How to use? 
Boot a 'huge' or default kernel and attach every hardware device that will be used with the machine (usb, dvb, external discs, cdrom -- etc) 
so that the required kernel modules are loaded. Once you've gathered enough modules (don't forget filesystems), by manually loading, or 
running probed as a cron job, you can then run the script with the "--load" flag prior to compiling your kernel with `make localmodmconfig`
This will allow you to compile a minimal kernel with only the modules that were collected. This is usually done to speed up compiling times 
for a personalized kernel.

If you don't want to spend the day inserting and removing random devices, run probed as a cron (use the -s flag for silent output) 
and wait  a few days after some normal usage, where you would typically attach disks, drives, joysticks, dongles etc. 

