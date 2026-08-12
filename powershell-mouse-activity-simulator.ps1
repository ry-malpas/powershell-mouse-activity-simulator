# Load necessary .NET assemblies
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Define Windows API calls using PowerShell Reflection
 $Signature = @'
    [DllImport("user32.dll")] 
    public static extern short GetAsyncKeyState(int vKey);
    
    [DllImport("user32.dll")] 
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);

    [DllImport("user32.dll")] 
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("kernel32.dll")] 
    public static extern uint SetThreadExecutionState(uint esFlags);
'@

# Create the type dynamically
 $WinAPI = Add-Type -MemberDefinition $Signature -Name "WinAPI" -Namespace "PowerShellHook" -PassThru

# Constants
 $ES_CONTINUOUS       = [uint32]2147483648
 $ES_SYSTEM_REQUIRED  = [uint32]0x00000001
 $ES_DISPLAY_REQUIRED = [uint32]0x00000002
 $MOUSEEVENTF_LEFTDOWN = [uint32]0x02
 $MOUSEEVENTF_LEFTUP   = [uint32]0x04
# Constant for minimizing the window
 $SW_MINIMIZE = 6

# Settings
 $MoveOffset = 600
 $AnimTime   = 500

# --- AUTO MINIMIZE LOGIC ---
# Get the handle of the current PowerShell window
 $consolePtr = (Get-Process -Id $PID).MainWindowHandle
# Minimize the window
 $WinAPI::ShowWindow($consolePtr, $SW_MINIMIZE) | Out-Null

# Set Power Flags
 $flags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED
 $WinAPI::SetThreadExecutionState($flags) | Out-Null

# Helper function to check for keyboard input
function Test-KeyboardPressed {
    for ($keyCode = 8; $keyCode -le 255; $keyCode++) {
        if ($keyCode -in @(1,2,4,5,6,7)) { continue }
        $state = $WinAPI::GetAsyncKeyState($keyCode)
        if ($state -band 0x8000) { return $true }
    }
    return $false
}

# Helper to wait until key is released (prevents immediate stop on startup)
function Wait-ForKeyRelease {
    while (Test-KeyboardPressed) { 
        Start-Sleep -Milliseconds 50 
    }
}

# Function to move mouse naturally
function Move-Smoothly {
    param($TargetPos, $DurationMs)

    $CurrentPos = [System.Windows.Forms.Cursor]::Position
    $StartX = $CurrentPos.X
    $StartY = $CurrentPos.Y
    $TargetX = $TargetPos.X
    $TargetY = $TargetPos.Y

    $Dx = $TargetX - $StartX
    $Dy = $TargetY - $StartY

    if ($Dx -eq 0 -and $Dy -eq 0) { return $false }

    $Steps = 50
    $SleepPerStep = $DurationMs / $Steps

    for ($i = 1; $i -le $Steps; $i++) {
        # Check keyboard inside the loop so it stops mid-movement
        if (Test-KeyboardPressed) { return $true }

        $Ratio = $i / $Steps
        $NewX = [int]($StartX + ($Dx * $Ratio))
        $NewY = [int]($StartY + ($Dy * $Ratio))

        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($NewX, $NewY)
        Start-Sleep -Milliseconds $SleepPerStep
    }
    
    [System.Windows.Forms.Cursor]::Position = $TargetPos
    return $false
}

# --- MAIN EXECUTION ---

# Wait for the launch key (Enter) to be released before starting logic
Wait-ForKeyRelease

try {
    $MiddlePos = [System.Windows.Forms.Cursor]::Position
    $IsPaused = $false

    while ($true) {
        # --- CHECK FOR PAUSE TOGGLE ---
        if (Test-KeyboardPressed) {
            $IsPaused = -not $IsPaused
            # Wait for user to let go of the key
            Wait-ForKeyRelease
        }

        # --- EXECUTE OR WAIT ---
        if ($IsPaused) {
            # Sleep to save CPU while paused
            Start-Sleep -Milliseconds 200
        }
        else {
            # --- Move Left ---
            $Target = $MiddlePos
            $Target.X -= $MoveOffset
            $interrupted = Move-Smoothly -TargetPos $Target -DurationMs $AnimTime
            if ($interrupted) { $IsPaused = $true; Wait-ForKeyRelease; continue }
            
            $WinAPI::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
            Start-Sleep -Milliseconds 50
            $WinAPI::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)

            # --- Return to Middle ---
            $interrupted = Move-Smoothly -TargetPos $MiddlePos -DurationMs $AnimTime
            if ($interrupted) { $IsPaused = $true; Wait-ForKeyRelease; continue }

            # --- Move Right ---
            $Target = $MiddlePos
            $Target.X += $MoveOffset
            $interrupted = Move-Smoothly -TargetPos $Target -DurationMs $AnimTime
            if ($interrupted) { $IsPaused = $true; Wait-ForKeyRelease; continue }

            $WinAPI::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
            Start-Sleep -Milliseconds 50
            $WinAPI::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)

            # --- Return to Middle ---
            $interrupted = Move-Smoothly -TargetPos $MiddlePos -DurationMs $AnimTime
            if ($interrupted) { $IsPaused = $true; Wait-ForKeyRelease; continue }
        }
    }
}
finally {
    # Cleanup: Restore normal power settings
    $WinAPI::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
}