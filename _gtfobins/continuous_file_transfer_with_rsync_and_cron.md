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
  * and it shall never fill up my disk.

I'm lazy, I don't want to maintain code or run any kind custom service.
So here is my two cents on this.

## The Tool Stack

The solution uses the following tools:  
- **rsync**: For file synchronization.  
- **cron**: To automate periodic execution.  
- **flock**: To prevent overlapping processes.  
- **killall**: To terminate processes if needed.  

## TL;DR  

1. Create a dedicated user for managing the synchronization process:  
   ```bash
   sudo useradd rsync_user_1
   ```  

2. Define two cron jobs under this user:  

   - **First cron job**:  
     Runs `rsync` only if disk usage is below 70% and no other instance of the job is running:  
     ```bash
     * * * * * rsync_user_1 bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/%//') -lt 70 ] && flock -n /tmp/lock.file rsync dir_A/ dir_B/"
     ```  

   - **Second cron job**:  
     Terminates all `rsync` processes if disk usage exceeds 80%:  
     ```bash
     * * * * * rsync_user_1 bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/%//') -gt 80 ] && killall -u rsync_user_1 rsync"
     ```  

This setup ensures continuous file synchronization while preventing disk overfill.  

---

## Detailed Explanation

### Command Structure  

Both cron jobs are encapsulated within `bash -c`. This ensures the commands are executed by Bash (not the default shell, which is often `sh`). Each command is in the form:  
```bash
bash -c "command_a && command_b"
```  
Here, `command_b` is executed **only if** `command_a` evaluates to `true`.  

---

### First Cron Job  

**Purpose**: To run `rsync` only if:  
- Disk usage is below 70%.  
- No previous instance of the job is running.  

The command:  
```bash
* * * * * rsync_user_1 bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/%//') -lt 70 ] && flock -n /tmp/lock.file rsync dir_A/ dir_B/"
```  

1. **Condition to check disk usage**:  
   ```bash
   [ $(df /data | awk 'NR==2 {print $5}' | sed 's/%//') -lt 70 ]
   ```  
   - `df /data`: Checks disk usage of the `/data` directory.  
   - `awk 'NR==2 {print $5}'`: Extracts the percentage of disk usage from the second row.  
   - `sed 's/%//'`: Removes the `%` symbol from the output.  
   - `-lt 70`: Ensures the disk usage is less than 70%.  

2. **Prevent overlapping processes**:  
   ```bash
   flock -n /tmp/lock.file rsync dir_A/ dir_B/
   ```  
   - `flock -n /tmp/lock.file`: Ensures only one instance of `rsync` runs at a time. If another instance is running, the command exits without starting a new one.  
   - `rsync dir_A/ dir_B/`: Synchronizes files from `dir_A` to `dir_B`.  

---

### Second Cron Job  

**Purpose**: To terminate all `rsync` processes if disk usage exceeds 80%.  

The command:  
```bash
* * * * * rsync_user_1 bash -c "[ $(df /data | awk 'NR==2 {print $5}' | sed 's/%//') -gt 80 ] && killall -u rsync_user_1 rsync"
```  

1. **Condition to check disk usage**:  
   ```bash
   [ $(df /data | awk 'NR==2 {print $5}' | sed 's/%//') -gt 80 ]
   ```  
   - Similar to the first job but checks if disk usage exceeds 80%.  

2. **Terminate `rsync` processes**:  
   ```bash
   killall -u rsync_user_1 rsync
   ```  
   - Sends a SIGTERM signal to all `rsync` processes owned by the user `rsync_user_1`.  
   - Ensures `rsync` exits gracefully without causing further disk space issues.  

---

### Why These Safeguards?  

1. **Disk Usage Thresholds**:  
   - The first job ensures that `rsync` runs only when there’s sufficient free space (<70%).  
   - The second job acts as a safety net, terminating `rsync` if disk usage exceeds 80%.  

2. **Avoid Overlapping Processes**:  
   - `flock` prevents multiple `rsync` processes from running simultaneously, avoiding redundant operations.  

3. **Handle Edge Cases**:  
   - Large data inflows or temporary connectivity loss could cause excessive disk usage during a single `rsync` session. The second job mitigates this risk by terminating such sessions.  

---

### Why Use a Dedicated User?

We need the ability to safely use the `killall rsync` command to terminate synchronization processes when necessary. However, indiscriminately killing all `rsync` processes on the host system would be highly undesirable, as other users or services might also rely on `rsync`.  

To prevent this, we "namespace" the termination by using the **process owner**. By creating a dedicated user (e.g., `rsync_user_1`), we ensure that only `rsync` processes owned by this specific user are targeted for termination.  

#### Why Not Use a PID-Based Mechanism?

While tracking processes using a PID-based mechanism is possible, it adds unnecessary complexity to the solution. A PID-based approach would require:  
- Maintaining PID files.  
- Handling edge cases where processes terminate unexpectedly or PID files become stale.  

Using a user-specific namespace for `killall` simplifies the solution while ensuring robust and precise control over process termination. This approach strikes a balance between functionality and simplicity.

---

## Conclusion  

By combining `rsync`, `cron`, `flock`, and `killall`, this setup provides a simple yet robust solution for continuously transferring files between Linux systems without the risk of filling up the disk.  

No custom code, no complex services—just a reliable, lightweight solution.

<br>
<br>
<br>
<br>
Happy syncing!  
