#!/bin/bash

echo "======================================================================="
echo " Starting Naive-Ollama Services Locally (without Docker)"
echo "======================================================================="
echo ""

echo "[IMPORTANT] Prerequisites:"
echo "1. Make sure you have installed Ollama on your system."
echo "2. Make sure you have installed all Python dependencies by running:"
echo "   pip3 install -r requirements.txt"
echo "3. Make sure you have created the 'credential.txt' file."
echo ""

# Check for credential.txt
if [ ! -f "credential.txt" ]; then
    echo "[ERROR] 'credential.txt' not found! Please create it before running."
    exit 1
fi

# File to store PIDs for easy cleanup
PID_FILE="ollama_services.pids"

# Clean up old PID file if it exists
if [ -f "$PID_FILE" ]; then
    rm "$PID_FILE"
fi

# --- Start Services ---
echo "[STEP 1/3] Starting Ollama server in the background..."
# Use nohup to keep the process running even if the terminal is closed
# Redirect stdout and stderr to a log file
nohup ollama serve > ollama.log 2>&1 &
OLLAMA_PID=$!
echo $OLLAMA_PID > $PID_FILE
echo "Ollama Server started with PID: $OLLAMA_PID. Log: ollama.log"

echo "[INFO] Waiting for 5 seconds for Ollama to initialize..."
sleep 5

echo "[STEP 2/3] Starting Alpha Orchestrator in the background..."
nohup python3 alpha_orchestrator.py > orchestrator.log 2>&1 &
ORCHESTRATOR_PID=$!
echo $ORCHESTRATOR_PID >> $PID_FILE
echo "Alpha Orchestrator started with PID: $ORCHESTRATOR_PID. Log: orchestrator.log"

echo "[STEP 3/3] Starting Web Dashboard in the background..."
nohup python3 web_dashboard.py > dashboard.log 2>&1 &
DASHBOARD_PID=$!
echo $DASHBOARD_PID >> $PID_FILE
echo "Web Dashboard started with PID: $DASHBOARD_PID. Log: dashboard.log"

echo ""
echo "======================================================================="
echo " All services have been started in the background."
echo "======================================================================="
echo ""
echo "  - Web Dashboard is available at: http://localhost:5000"
echo "  - Ollama API is available at:    http://localhost:11434"
echo ""
echo "  - Process IDs (PIDs) are saved in '$PID_FILE'"
echo ""
echo "  To STOP all services, run the following command:"
echo "  kill \$(cat $PID_FILE) && rm $PID_FILE"
echo ""
