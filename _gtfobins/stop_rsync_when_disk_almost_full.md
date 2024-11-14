---
tags:
  - linux
  - rsync
  - design_pattern
---

Here I present how we can transfer file continuously from dir_A to dir_B using rsync and cron,
with a kill switch when the disk is amost full.

This solution use basic system utilities and aim to be robust with the minimal amount of scripting

The stack: 

  *  rsync
  *  crontab
  *  flock
  *  killall

### TL;DR
Edit the crontab using 
```
crontab -e
```
and put in the following line ( but adjust the dir /data and rsync command to match your need obviously )
```bash
* * * * * bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -lt 70 ] && flock -n /tmp/lock.file rsync dir_A/ dir_B/"
* * * * * bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -gt 80 ] && killall rsync"
```


### In details

Both cron are encapsuled in *bash -c*, so the command is executed by bash and not the default shell wich is often sh
More over, both cron are in the form of

```
bash -c "command_a && command_b"
```
where *command_b* will only get executed if *command_a* is True.

So here command_a is used as a condition : is disk usage less or greater than x %.

#### The first cron job

This cron job run rsync if the disk used percetage is less than 70%, and if no previous instance of this job is running (flock -n).

The condition in the first command is :
```
[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -lt 70 ] 
```
This use the output of *df*, *awk* and *sed* to get the used percentage of the disk, and return true id this is less than 70.

The second part is :
```
flock -n /tmp/lock.file rsync dir_A/ dir_B/"
```
You can learn more about flock [here](https://linuxhandbook.com/flock-command/)

But in brief, here we use it to not run a process if one is already running.

This cron job run every minute, but a rsync can run for more than a minute, and we dont want to run a rsync if there is already one running.

By using *flock -n /tmp/file.lock*, the rsync will not be run if a previous cron job run is still locking the file.


#### The second cron job

The second command is here to kill all rsync if the disk usage exeed a certain amount.
```
bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -gt 80 ] && killall rsync
```
The condition is:
```
[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -gt 80 ]
```
Wich mean we run the killall rsync if disk usage is greater than 80%


