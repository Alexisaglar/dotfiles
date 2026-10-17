#!/bin/bash
# Reconnect the Sony ZV-E10 to OBS without stopping the stream or OBS.
#
#   reconnect-camera.sh           re-point OBS at the camera (no sudo needed)
#   reconnect-camera.sh --reset   power-cycle the camera's USB port first (sudo)
#   reconnect-camera.sh --check   only report camera + OBS state, change nothing
#
# Needs OBS: Tools -> WebSocket Server Settings -> Enable WebSocket server.
# The password is read from OBS's own config.

CAM_NAME="ZV-E10"
CAM_VENDOR="054c"          # Sony
CAM_STREAM_PRODUCT="0de3"  # ZV-E10 in USB streaming (webcam) mode
OBS_WS_CONFIG="$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugin_config/obs-websocket/config.json"
WAIT_SECS=20
SETTLE_SECS=4         # pause between the camera appearing and OBS opening it

mode="${1:-}"

# /dev/videoN of the camera's capture node (newest one if several), or nothing.
find_cam_dev() {
    local d best=""
    for d in /sys/class/video4linux/video*; do
        [ -e "$d/name" ] || continue
        grep -q "$CAM_NAME" "$d/name" || continue
        [ "$(cat "$d/index")" = "0" ] || continue   # skip the metadata node
        best="/dev/$(basename "$d")"
    done
    [ -n "$best" ] && echo "$best"
}

# sysfs directory of the camera on the USB bus (any mode), or nothing.
find_cam_usb() {
    local d
    for d in /sys/bus/usb/devices/*; do
        [ -e "$d/idVendor" ] || continue
        [ "$(cat "$d/idVendor")" = "$CAM_VENDOR" ] && { echo "$d"; return; }
    done
}

wait_for_cam() {
    local i dev
    for ((i = 0; i < WAIT_SECS * 2; i++)); do
        dev=$(find_cam_dev) && { echo "$dev"; return 0; }
        sleep 0.5
    done
    return 1
}

reset_usb_port() {
    local usb port
    usb=$(find_cam_usb)
    if [ -z "$usb" ]; then
        echo "Camera is not on the USB bus at all - replug the cable or power-cycle the camera." >&2
        return 1
    fi
    port=$(readlink -f "$usb/port")
    echo "Power-cycling USB port $(basename "$port") (sudo)..."
    sudo sh -c "echo 1 > '$port/disable'; sleep 2; echo 0 > '$port/disable'"
}

# Talk to OBS over obs-websocket. $1 = "check", "release" or "set"; $2 = device path.
obs_request() {
    python3 - "$OBS_WS_CONFIG" "$1" "${2:-}" <<'PY'
import base64, hashlib, json, os, socket, struct, sys

cfg_path, action, device = sys.argv[1:4]
cfg = json.load(open(cfg_path))

try:
    sock = socket.create_connection(("127.0.0.1", cfg.get("server_port", 4455)), timeout=5)
except OSError:
    sys.exit("Cannot reach OBS. Is OBS running with Tools -> WebSocket Server Settings -> Enable?")

key = base64.b64encode(os.urandom(16)).decode()
sock.sendall((
    "GET / HTTP/1.1\r\nHost: 127.0.0.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
    f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
buf = b""
while b"\r\n\r\n" not in buf:
    chunk = sock.recv(4096)
    if not chunk:
        sys.exit("OBS closed the connection during the handshake.")
    buf += chunk
head, buf = buf.split(b"\r\n\r\n", 1)
if b" 101 " not in head.split(b"\r\n")[0]:
    sys.exit("OBS refused the WebSocket connection.")

def read(n):
    global buf
    while len(buf) < n:
        chunk = sock.recv(65536)
        if not chunk:
            sys.exit("OBS closed the connection (wrong password?).")
        buf += chunk
    out, buf = buf[:n], buf[n:]
    return out

def send(obj, opcode=1):
    data = obj if isinstance(obj, bytes) else json.dumps(obj).encode()
    mask = os.urandom(4)
    n = len(data)
    if n < 126:
        header = struct.pack("!BB", 0x80 | opcode, 0x80 | n)
    elif n < 65536:
        header = struct.pack("!BBH", 0x80 | opcode, 0x80 | 126, n)
    else:
        header = struct.pack("!BBQ", 0x80 | opcode, 0x80 | 127, n)
    sock.sendall(header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

def recv():
    message = b""
    while True:
        b0, b1 = read(2)
        n = b1 & 0x7F
        if n == 126:
            n = struct.unpack("!H", read(2))[0]
        elif n == 127:
            n = struct.unpack("!Q", read(8))[0]
        data = read(n)
        opcode = b0 & 0x0F
        if opcode == 9:          # ping
            send(data, opcode=10)
            continue
        if opcode == 8:          # close
            sys.exit("OBS closed the connection (wrong password?).")
        message += data
        if b0 & 0x80:
            return json.loads(message)

hello = recv()["d"]
identify = {"rpcVersion": 1, "eventSubscriptions": 0}
if "authentication" in hello:
    auth = hello["authentication"]
    secret = base64.b64encode(hashlib.sha256(
        (cfg.get("server_password", "") + auth["salt"]).encode()).digest()).decode()
    identify["authentication"] = base64.b64encode(hashlib.sha256(
        (secret + auth["challenge"]).encode()).digest()).decode()
send({"op": 1, "d": identify})
if recv()["op"] != 2:
    sys.exit("OBS did not accept the login.")

def request(kind, data=None):
    send({"op": 6, "d": {"requestType": kind, "requestId": kind, "requestData": data or {}}})
    while True:
        msg = recv()
        if msg["op"] == 7:
            status = msg["d"]["requestStatus"]
            if not status["result"]:
                sys.exit(f"OBS rejected {kind}: {status.get('comment', status['code'])}")
            return msg["d"].get("responseData", {})

inputs = request("GetInputList", {"inputKind": "v4l2_input"})["inputs"]
if not inputs:
    sys.exit("OBS has no 'Video Capture Device (V4L2)' source.")
for inp in inputs:
    name = inp["inputName"]
    current = request("GetInputSettings", {"inputName": name})["inputSettings"].get("device_id")
    if action == "check":
        print(f"OBS source '{name}' is using {current}")
    elif action == "release":
        # Point OBS at nothing so it lets go of the camera and does not grab
        # it again by itself the instant the camera reappears.
        request("SetInputSettings", {"inputName": name, "inputSettings": {"device_id": ""}})
        print(f"OBS source '{name}' released the camera")
    else:
        request("SetInputSettings", {"inputName": name, "inputSettings": {"device_id": device}})
        print(f"OBS source '{name}' now using {device}")
PY
}

case "$mode" in
--check)
    dev=$(find_cam_dev) && echo "Camera is streaming on $dev" || {
        usb=$(find_cam_usb)
        if [ -n "$usb" ]; then
            echo "Camera is on USB but not in streaming mode (product $(cat "$usb/idProduct"), expected $CAM_STREAM_PRODUCT)."
        else
            echo "Camera is not connected."
        fi
    }
    obs_request check
    exit
    ;;
--reset | "") ;;
*)
    sed -n '2,9p' "$0" | cut -c3-
    exit 1
    ;;
esac

# OBS must let go of the camera before it comes back: if OBS reopens it the
# instant it reappears, the capture dies after a couple of frames.
obs_request release || exit 1
sleep 1

if [ "$mode" = "--reset" ]; then
    reset_usb_port || exit 1
fi

echo "Waiting for the camera..."
if ! dev="${CAM_DEV:-$(wait_for_cam)}"; then
    usb=$(find_cam_usb)
    if [ -z "$usb" ]; then
        echo "Camera did not come back. Replug the cable or power-cycle the camera, then run this again." >&2
    elif [ "$(cat "$usb/idProduct")" != "$CAM_STREAM_PRODUCT" ]; then
        echo "Camera is connected but not in USB streaming mode - select USB Streaming on the camera, then run this again." >&2
    else
        echo "Camera is on USB but gave no video device. Try: $0 --reset" >&2
    fi
    exit 1
fi
echo "Camera is on $dev, letting it settle for ${SETTLE_SECS}s..."
sleep "$SETTLE_SECS"
dev="${CAM_DEV:-$(find_cam_dev)}" || { echo "Camera dropped again while settling - run this again." >&2; exit 1; }

# Make sure the camera really delivers frames before handing it to OBS. After
# a drop the kernel can keep a dead video device around until the USB port is
# power-cycled.
if command -v v4l2-ctl >/dev/null && [ -z "${CAM_DEV:-}" ]; then
    if timeout 8 v4l2-ctl -d "$dev" --stream-mmap --stream-count=5 2>&1 | grep -q "returned -1"; then
        if [ "$mode" = "--reset" ]; then
            echo "Camera still gives no video after the port reset. Replug the cable or power-cycle the camera, then run this again." >&2
        else
            echo "Camera is listed but its video stream is dead. Run: $0 --reset" >&2
        fi
        exit 1
    fi
    echo "Camera is delivering frames."
fi
obs_request set "$dev"
