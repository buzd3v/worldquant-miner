@echo off
setlocal

echo =======================================================================
echo  Starting Naive-Ollama Services Locally (without Docker)
echo =======================================================================
echo.

echo [INFO] This script will start the Ollama server, the Alpha Orchestrator, and the Web Dashboard.
echo.
echo [IMPORTANT] Prerequisites:
echo 1. Make sure you have installed Ollama on your system.
echo 2. Make sure you have installed all Python dependencies by running:
echo    pip install -r requirements.txt
echo 3. Make sure you have created the 'credential.txt' file.
echo.

REM Check for credential.txt
if not exist "credential.txt" (
    echo [ERROR] 'credential.txt' not found! Please create it before running.
    pause
    exit /b 1
)

echo [STEP 1/3] Starting Ollama server in a new window...
REM The 'start' command launches a new process in a new window.
start "Ollama Server" ollama serve

echo [INFO] Waiting for 5 seconds for Ollama to initialize...
timeout /t 5 /nobreak > nul

echo [STEP 2/3] Starting Alpha Orchestrator in a new window...
start "Alpha Orchestrator" python alpha_orchestrator.py

echo [STEP 3/3] Starting Web Dashboard in a new window...
start "Web Dashboard" python web_dashboard.py

echo.
echo =======================================================================
echo  All services have been started successfully in separate windows.
echo =======================================================================
echo.
echo  - Web Dashboard is available at: http://localhost:5000
echo  - Ollama API is available at:    http://localhost:11434
echo.
echo  To STOP all services, simply close the three new command prompt windows
echo  that were opened ("Ollama Server", "Alpha Orchestrator", "Web Dashboard").
echo.

pause
endlocal
