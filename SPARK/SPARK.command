#!/bin/sh
# S.P.A.R.K. launcher: macOS (double-click), Linux (./SPARK.command), Android (Termux)
cd "$(dirname "$0")" || exit 1
[ -f index.html ] || { echo "index.html not found next to this file."; exit 1; }

PY=""
for p in python3 python; do command -v $p >/dev/null 2>&1 && PY=$p && break; done

# find a free port starting at 8080
PORT=8080
if [ -n "$PY" ]; then
  PORT=$($PY - <<'PYEOF'
import socket
for p in range(8080, 8100):
    s = socket.socket()
    try:
        s.bind(("127.0.0.1", p)); s.close(); print(p); break
    except OSError:
        s.close()
PYEOF
)
fi
URL="http://localhost:$PORT"

( sleep 1.5
  if command -v termux-open-url >/dev/null 2>&1; then termux-open-url "$URL"
  elif command -v open >/dev/null 2>&1; then open "$URL"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL"
  fi ) >/dev/null 2>&1 &

echo "S.P.A.R.K. running at $URL  (press Ctrl+C to stop)"
if   [ -n "$PY" ];                      then exec $PY -m http.server "$PORT" --bind 127.0.0.1
elif command -v php  >/dev/null 2>&1;   then exec php -S 127.0.0.1:"$PORT"
elif command -v ruby >/dev/null 2>&1;   then exec ruby -run -e httpd . -p "$PORT"
elif command -v npx  >/dev/null 2>&1;   then exec npx --yes http-server -p "$PORT"
else
  echo "No web server runtime found. Install Python 3 (python.org, or 'pkg install python' in Termux)."
  exit 1
fi
