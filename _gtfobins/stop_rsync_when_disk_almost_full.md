---
tags:
  - linux
  - rsync

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
* * * * * bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -lt 70 ] && flock -n lock.file rsync dir_A/ dir_B/"
* * * * * bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/\%//' -gt 80 ] && killall rsync"
```

### In details

