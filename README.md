# powershell-mouse-activity-simulator

A PowerShell script that simulates periodic mouse activity by smoothly moving the cursor and performing clicks at configurable positions.

The script also prevents Windows from entering a sleep or display-off state while it is running and automatically minimises its PowerShell window.

Requirements
Windows
PowerShell
A graphical desktop session

The script uses Windows APIs through .NET and therefore is intended for Windows systems.

Usage

Run the script from PowerShell:

.\mouse-activity.ps1

The script will minimise the PowerShell window and begin moving the mouse between two positions around the cursor's original location.

Features
Smooth mouse movement
Configurable movement distance
Configurable movement duration
Periodic mouse clicks
Keyboard-controlled pause
Stops movement when keyboard input is detected
Prevents the system from sleeping
Prevents the display from being turned off
Automatically minimises the PowerShell window
Restores normal Windows power behaviour when the script exits
Configuration

The main movement settings are defined near the top of the script:

$MoveOffset = 600
$AnimTime   = 500
MoveOffset

Controls how far the cursor moves from its starting position.

For example:

$MoveOffset = 300

will move the cursor 300 pixels to either side of its starting position.

AnimTime

Controls how long each mouse movement takes, in milliseconds.

For example:

$AnimTime = 1000

will make each movement take approximately one second.

How It Works

When started, the script:

Records the current cursor position.
Minimises the PowerShell window.
Prevents Windows from automatically sleeping or turning off the display.
Waits for any key pressed during launch to be released.
Moves the cursor smoothly to the left of its original position.
Performs a mouse click.
Returns to the original position.
Moves smoothly to the right.
Performs another mouse click.
Returns to the original position.
Repeats the process.

Keyboard input can interrupt movement and pause the script.

Pausing

The script monitors keyboard input while running.

When keyboard input is detected, the current movement is interrupted and the script enters its paused state.

The script waits until the key is released before continuing.

Power Management

While running, the script uses the Windows SetThreadExecutionState API to request that Windows:

Keep the system awake
Keep the display active

When the script exits, the execution state is reset so normal Windows power-management behaviour can resume.

Stopping the Script

The script can be terminated from the PowerShell session.

For example:

Ctrl+C

The script includes a finally block that attempts to restore normal power-management behaviour when it exits.

Notes

The script controls the actual system mouse cursor. Using the mouse while the script is running may therefore interfere with its movement.

The script is intended for situations where simulated mouse activity is appropriate. Be aware that applications may detect or respond differently to simulated input compared with physical mouse input.

The movement distance and animation speed can be adjusted to suit your requirements.
