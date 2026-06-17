#!/system/bin/sh
# Runs automatically on every boot (Magisk service.d). This phone has no
# physical battery, so Android's BatteryService decides to shut down unless
# convinced a healthy battery is present - this loop keeps lying to it.
while true; do
  dumpsys battery set ac 1
  dumpsys battery set status 2
  dumpsys battery set level 100
  dumpsys battery set present 1
  dumpsys battery set temp 250
  sleep 15
done &
