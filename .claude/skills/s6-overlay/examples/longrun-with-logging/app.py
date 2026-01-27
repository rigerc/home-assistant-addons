#!/usr/bin/env python3
"""
Example application that demonstrates logging with s6-overlay.
All output to stdout/stderr is captured by the logger service.
"""

import time
import sys

def main():
    print("Application starting...", flush=True)
    print("This output goes to /var/log/app/current", flush=True)

    counter = 0
    while True:
        counter += 1
        print(f"[INFO] Heartbeat {counter}", flush=True)

        # Errors go to stderr, which is also logged
        if counter % 5 == 0:
            print(f"[WARN] Warning message {counter}", file=sys.stderr, flush=True)

        time.sleep(10)

if __name__ == "__main__":
    main()
