#!/usr/bin/env python3
"""
Adaptive scrolling layout column width.
Sets scrolling:column_width based on the widest connected monitor:
  >= 3000px wide  →  0.333 (3-column, ultrawide)
  < 3000px wide   →  0.5   (2-column, laptop/normal)
Listens for monitor connect/disconnect and config reload events to re-apply.
"""

import json
import os
import socket
import subprocess


ULTRAWIDE_THRESHOLD = 3000
ULTRAWIDE_WIDTH = "0.333"
DEFAULT_WIDTH = "0.5"


def update():
    try:
        monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"]))
        max_width = max((m["width"] for m in monitors), default=0)
        width = ULTRAWIDE_WIDTH if max_width >= ULTRAWIDE_THRESHOLD else DEFAULT_WIDTH
        subprocess.run(["hyprctl", "keyword", "scrolling:column_width", width])
    except Exception as e:
        print(f"adaptive-scrolling: error updating column width: {e}")


def main():
    update()

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    sock_path = f"{runtime_dir}/hypr/{sig}/.socket2.sock"

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(sock_path)
        buf = b""
        while True:
            data = s.recv(4096)
            if not data:
                break
            buf += data
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                if any(ev in line for ev in [b"monitoradded", b"monitorremoved", b"configreloaded"]):
                    update()


if __name__ == "__main__":
    main()
