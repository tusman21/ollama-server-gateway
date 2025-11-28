<#
.SYNOPSIS
    Ollama Server Gateway (PowerShell Edition)
.DESCRIPTION
    Starts Ollama (if not running), creates an SSH tunnel via localhost.run,
    and publishes the URL to ntfy.sh.
.PARAMETER Topic
    The unique topic name for ntfy.sh
#>

param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Missing Topic. Usage: .\ollama-gateway.ps1 <unique-topic-name>")]
    [string]$Topic
)

# --- Configuration & State ---
$global:OllamaProcess = $null
$global:JobSubscriber = $null

# --- Logging Helper Functions ---
function Write-LogInfo { param([string]$msg) Write-Host "INFO: $msg" -ForegroundColor Blue }
function Write-LogSuccess { param([string]$msg) Write-Host "SUCCESS: $msg" -ForegroundColor Green }
function Write-LogWarn { param([string]$msg) Write-Host "WARN: $msg" -ForegroundColor Yellow }
function Write-LogError { param([string]$msg) Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# --- Cleanup Function ---
function Cleanup {
    Write-Host ""
    Write-LogInfo "Cleaning up..."
    
    # Kill Ollama if we started it
    if ($global:OllamaProcess -and -not $global:OllamaProcess.HasExited) {
        Stop-Process -Id $global:OllamaProcess.Id -Force -ErrorAction SilentlyContinue
    }

    # Unregister the async log event
    if ($global:JobSubscriber) {
        Unregister-Event -SubscriptionId $global:JobSubscriber.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $global:JobSubscriber.SourceIdentifier -ErrorAction SilentlyContinue
    }

    Write-LogInfo "Tunnel closed. Goodbye!"
}

# --- Main Logic Wrapped in Try/Finally for Safety ---
try {
    # --- Banner ---
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host "               Ollama Server Gateway                  " -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host ""

    # --- Dependency Checks ---
    if (-not (Get-Command "ssh" -ErrorAction SilentlyContinue)) { Write-LogError "ssh is not installed or not in PATH." }
    # Note: PowerShell has built-in Invoke-RestMethod, so strict curl.exe check isn't strictly necessary, 
    # but we check it if we want to rely on the alias. We will use native PowerShell for HTTP requests.

    # --- 2. Ollama Service Check ---
    Write-LogInfo "Checking Ollama status..."

    $OllamaRunning = $false
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:11434/" -UseBasicParsing -ErrorAction Stop
        if ($Response.StatusCode -eq 200) { $OllamaRunning = $true }
    } catch {
        $OllamaRunning = $false
    }

    if ($OllamaRunning) {
        Write-LogSuccess "Ollama is running."
    } else {
        Write-LogWarn "Ollama not detected. Starting..."
        $env:OLLAMA_HOST = '0.0.0.0'

        Write-LogInfo "Starting Ollama..."
        Write-Host "--- Ollama Logs ---" -ForegroundColor DarkGray

        # Start Ollama as an async process to capture logs live
        $StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $StartInfo.FileName = "ollama"
        $StartInfo.Arguments = "serve"
        $StartInfo.RedirectStandardOutput = $true
        $StartInfo.RedirectStandardError = $true
        $StartInfo.UseShellExecute = $false
        $StartInfo.CreateNoWindow = $true

        $global:OllamaProcess = New-Object System.Diagnostics.Process
        $global:OllamaProcess.StartInfo = $StartInfo

        # Event handler to print Ollama logs to host in Gray
        $Action = { 
            if ($Event.SourceEventArgs.Data) { 
                Write-Host "[Ollama] $($Event.SourceEventArgs.Data)" -ForegroundColor DarkGray 
            } 
        }

        # Register events for stdout and stderr
        $global:JobSubscriber = Register-ObjectEvent -InputObject $global:OllamaProcess -EventName "OutputDataReceived" -Action $Action
        Register-ObjectEvent -InputObject $global:OllamaProcess -EventName "ErrorDataReceived" -Action $Action | Out-Null

        $global:OllamaProcess.Start() | Out-Null
        $global:OllamaProcess.BeginOutputReadLine()
        $global:OllamaProcess.BeginErrorReadLine()

        Start-Sleep -Seconds 5

        # Verify it started
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost:11434/" -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-LogError "Failed to start Ollama."
        }
        Write-LogSuccess "Ollama is running."
    }

    Write-Host ""

    # --- 3. Start Tunnel ---
    Write-LogInfo "Opening secure tunnel..."
    Write-LogWarn "Waiting for public URL..."

    # We use ssh directly. 
    # Note: We must ensure ssh doesn't allocate a TTY that confuses PowerShell piping, 
    # but localhost.run usually requires TTY allocation (-t) or no command (-N). 
    # The original script used -T (disable pseudo-tty).
    
    $SSHCommand = "ssh"
    $SSHArgs = @("-T", "-R", "80:localhost:11434", "nokey@localhost.run")

    # Run SSH and process output stream line-by-line
    & $SSHCommand $SSHArgs | ForEach-Object {
        $Line = $_
        
        # Uncomment to debug SSH raw output
        # Write-Host "SSH: $Line"

        if ($Line -match "https://[a-zA-Z0-9.-]*\.life") {
            $TunnelUrl = $matches[0]
            
            if (-not [string]::IsNullOrWhiteSpace($TunnelUrl)) {
                Write-LogInfo "Attempting to register tunnel URL: $TunnelUrl"

                try {
                    # Send to ntfy.sh
                    Invoke-RestMethod -Uri "https://ntfy.sh/$Topic" -Method Post -Body $TunnelUrl -ErrorAction Stop | Out-Null
                    
                    Write-LogSuccess "Gateway live!"
                    Write-Host ""
                    Write-LogWarn "Press Ctrl+C to stop."
                    Write-Host ""
                } catch {
                    Write-LogError "Failed to register tunnel URL with ntfy.sh"
                }
            }
        }
    }

} finally {
    # This block runs on Exit or Ctrl+C
    Cleanup
}