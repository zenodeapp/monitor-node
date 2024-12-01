#!/bin/bash

# Usage:
#          e.g. bash monitor_node.sh "namada_node" "http://localhost:26657" "your-healthchecks-id" 600
#          This will check whether the node at port 26657 is synced or not. It will only give error 3
#          if the last block is older than 600 seconds (10 minutes). See below for more error types.

#          Make sure to create a cronjob like:
#          */10 * * * * /bin/bash /path/to/monitor_node.sh "namada_node" "http://localhost:26657" "your-healthchecks-id" 600
#          (*/10 and 600 don't have to match)


# Input (parameters):
#          $1 - Title for the node (e.g., namada_node)
#          $2 - Local RPC endpoint (default: http://localhost:26657)
#          $3 - Healthchecks unique ID (optional)
#          $4 - Optional stale block threshold in seconds (default: 300 [5 minutes])
#               CAUTION: Make sure not to set the threshold too low; your local server's time might be
#                        inconsistent with the node. Omitting the value (600) will default it to 300.
TITLE=${1:-"node"} 
RPC_URL=${2:-"http://localhost:26657"} 
HC_ID=${3:-""} 
STALE_THRESHOLD=${4:-300}

# Output (error types):
#          0 = No error
#          1 = Node down
#          2 = Catching up
#          3 = Stale blocks
ERROR=0

# Directories and files
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOGS_DIR="${SCRIPT_DIR}/.logs"
LOG_FILE="${LOGS_DIR}/${TITLE}_health.log"
BLOCK_TRACK_FILE="${LOGS_DIR}/${TITLE}_block_height"

# Make sure the .logs folder exists and create the log file
mkdir -p "$LOGS_DIR"
if [ ! -f "$LOG_FILE" ]; then
  echo "=== Monitoring ${TITLE} ===" > "$LOG_FILE"
fi

# Fetch node and server data
NODE_STATUS=$(curl -s --connect-timeout 5 "$RPC_URL/status")
SERVER_TIME_UNIX=$(date +%s)

if [ -z "$NODE_STATUS" ]; then
  ERROR=1
  MESSAGE="Error 1: Node is down. Unable to reach RPC ($RPC_URL)."
else
  BLOCK_HEIGHT=$(echo "$NODE_STATUS" | jq -r '.result.sync_info.latest_block_height')
  CATCHING_UP=$(echo "$NODE_STATUS" | jq -r '.result.sync_info.catching_up')
  BLOCK_TIME=$(echo "$NODE_STATUS" | jq -r '.result.sync_info.latest_block_time')
  BLOCK_TIME_UNIX=$(date -d "$BLOCK_TIME" +%s 2>/dev/null || echo "0")
  ELAPSED_TIME=$((SERVER_TIME_UNIX - BLOCK_TIME_UNIX))

  # Read the last known block height
  if [ -f "$BLOCK_TRACK_FILE" ]; then
    LAST_KNOWN_BLOCK_HEIGHT=$(cat "$BLOCK_TRACK_FILE")
  else
    LAST_KNOWN_BLOCK_HEIGHT=0
  fi

  # Update the block height tracker
  echo "$BLOCK_HEIGHT" > "$BLOCK_TRACK_FILE"

  if [ "$CATCHING_UP" == "true" ]; then
    ERROR=2
    MESSAGE="Error 2: Node is catching up. Block height: $BLOCK_HEIGHT."
  elif (( BLOCK_HEIGHT == LAST_KNOWN_BLOCK_HEIGHT && ELAPSED_TIME > STALE_THRESHOLD )); then
    ERROR=3
    MESSAGE="Error 3: No block progress in the last $ELAPSED_TIME seconds. Last block height: $BLOCK_HEIGHT at $BLOCK_TIME."
  else
    MESSAGE="Node is healthy. Latest block: $BLOCK_HEIGHT, Timestamp: $BLOCK_TIME."
  fi
fi

# Log the message to the log file
echo "[$(date -d "@$SERVER_TIME_UNIX" "+%Y-%m-%d %H:%M:%S")] $MESSAGE" >> "$LOG_FILE"

# Ping Healthchecks if HC_ID is provided
if [ -n "$HC_ID" ]; then
  tail -n 5 "$LOG_FILE" | curl -fsS -m 10 --retry 5 --data-binary @- "https://hc-ping.com/$HC_ID/$ERROR"
fi

echo "$MESSAGE"