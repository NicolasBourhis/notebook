---
tags:
  - linux
  - rsync
  - design_patterns
---

# How to tranfere file continuously between linux systems in a robust way  

## What ?

Transfering file between two computer is one of the most basic task in sysadmin|devops|(platform|data) engineer life,<br>
and to do so, those above have blessed us with the holly rsync.

But there is two more things that I need: 
  * I want to transfer files continuously
  * and it shall never fill my disk.

I'm lazy, I don't want to maintain code or run any kind custom service.
So here is my two cents on this.

The tool stack: 

  *  rsync
  *  cron
  *  flock
  *  killall

## TL;DR

We do this by defining two cron job on the client:

```bash
# first job: if used space on disk is less than 70% and if no previous instance of this job is running, run rsync
* * * * * bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//') -lt 70 ] && flock -n /tmp/lock.file rsync dir_A/ dir_B/"

# second job: if used space on disk is more than 80%, send sigterm to all rsync process
* * * * * bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//') -gt 80 ] && killall rsync"
```

With those two jobs, we continuously sync file while being sure that we will not run out of disk space

# Details

Both cron are encapsuled in *bash -c*, so the command is executed by bash and not the default shell wich is often sh
More over, both cron are in the form of

```
bash -c "command_a && command_b"
```
where *command_b* will only get executed if *command_a* is True.

#### The first cron job

This cron job run rsync if the disk used percetage is less than 70%, and if no previous instance of this job is running (flock -n).

The condition is :
```
[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -lt 70 ] 
```
This use the output of *df*, *awk* and *sed* to get the disk's used space percentage, and return true if it is less than 70 %.

The second part is :
```
flock -n /tmp/lock.file rsync dir_A/ dir_B/"
```
You can learn more about flock [here](https://linuxhandbook.com/flock-command/)

Here we use it to not run rsync if one is already running.

We do this because the cron job will run every minute, but a rsync can run for more than a minute, and we dont want to run a rsync if there is already one running.

By using *flock -n /tmp/file.lock*, if the file /tmp/file.lock is not locked, the job lock the file and run rsync, if it is locked (by a previous instance of job), the job terminate without running rsync.

#### The second cron job

The second command is here to kill all rsync if the disk usage exeed a certain amount.
```
bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//') -gt 80 ] && killall rsync
```
The condition is:
```
[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -gt 80 ]
```
Wich mean we run the killall rsync if disk usage is greater than 80%
```
killall rsync
```
*killall* will send a sigterm to all rsync process on the host and rsync will exit gracefully.

This is kind of brutal and not very eleganto.

I'm looking to improve this part to only kill the rsync launched by the job.

Until then take care of your self,

<br>
<br>
<br>
<br>
Bye !



