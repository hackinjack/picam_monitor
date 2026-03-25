#!/bin/bash

# Configuration
PICAM_IP="picam1.thirteenb.mywire.org"  # Replace with your PiCam's IP
WEBHOOK_URL="https://www.virtualsmarthome.xyz/url_routine_trigger/activate.php?trigger=31d18422-6cfa-488d-b16f-d3235a1bdf46&token=c0f7aeea-c156-4550-a7f4-24d4fe9274c7&response=html"
LOCK_FILE="/tmp/picam_reboot.lock"
COOLDOWN_MINUTES=15

# 1. Check if we are in a cooldown period to prevent infinite reboot loops
if [ -f "$LOCK_FILE" ]; then
    # Find if the lock file is older than our cooldown period
    if test "$(find "$LOCK_FILE" -mmin +$COOLDOWN_MINUTES)"; then
        rm "$LOCK_FILE" # Cooldown expired, remove lock
    else
        exit 0 # Still in cooldown, do nothing
    fi
fi

# 2. Ping the PiCam (send 3 packets, wait up to 2 seconds for each)
if ! ping -c 3 -W 2 "$PICAM_IP" > /dev/null; then
    # 3. If ping fails, trigger the Alexa routine via webhook
    curl -s "$WEBHOOK_URL"
    
    # 4. Create the lock file to start the cooldown timer
    touch "$LOCK_FILE"
    
    # 5. Log the event
    echo "$(date): PiCam at $PICAM_IP is completely unresponsive. Alexa restart triggered." >> /var/log/picam_monitor.log
fi

