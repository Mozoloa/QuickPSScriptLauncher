# Check if shortcut exists, if not create it
$shortcutPath = [System.IO.Path]::Combine((Split-Path -Parent $MyInvocation.MyCommand.Definition), 'QuickPSScriptLauncher.lnk')
if (-Not (Test-Path -Path $shortcutPath)) {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = 'powershell.exe'
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -windowstyle minimized -File `"$($MyInvocation.MyCommand.Definition)`""
    $Shortcut.IconLocation = 'powershell.exe,0' # Set icon to PowerShell icon
    $Shortcut.Save()
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Run the UI
function Refresh-UI {
    param (
        $Form,
        $ScriptPath
    )

    $Form.Controls.Clear()
    $folders = Get-ChildItem -Path $ScriptPath -Directory

    foreach ($folder in $folders) {
        $scripts = Get-ChildItem -Path $folder.FullName -Filter *.ps1
        if ($scripts.Count -eq 0) {
            continue
        }

        $groupBox = New-Object System.Windows.Forms.GroupBox
        $groupBox.Text = $folder.Name
        $groupBox.Dock = "Top"
        $groupBox.AutoSize = "true"
        $groupBox.Padding = 10
        $Form.Controls.Add($groupBox)

        foreach ($script in $scripts) {
            $button = New-Object System.Windows.Forms.Button
            $button.Dock = "Top"
            $button.Size = New-Object System.Drawing.Size(240, 23)
            $button.Text = $script.BaseName
            $button.Tag = $script.FullName
            $button.Add_Click({
                    # Retrieve the script path from the Tag property of the sender
                    $button = $this -as [System.Windows.Forms.Button]
                    $path = $button.Tag
                    $arguments = "-ExecutionPolicy Bypass -NoExit -File `"$path`""
                    Write-Host $arguments
                    Start-Process PowerShell -ArgumentList $arguments
                })
            $groupBox.Controls.Add($button)
        }
    }

    # Refresh button
    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Size = New-Object System.Drawing.Size(115, 23) # Half the original width
    $refreshButton.Text = "Refresh"
    $refreshButton.Dock = "Bottom"
    $refreshButton.Add_Click({
            Refresh-UI -Form $Form -ScriptPath $ScriptPath
        })
    $Form.Controls.Add($refreshButton)

    # Open Folder button
    $openFolderButton = New-Object System.Windows.Forms.Button
    $openFolderButton.Size = New-Object System.Drawing.Size(115, 23) # Half the original width
    $openFolderButton.Text = "Open Folder"
    $openFolderButton.Dock = "Bottom"
    $openFolderButton.Add_Click({
            Start-Process explorer.exe -ArgumentList $ScriptPath
        })
    $Form.Controls.Add($openFolderButton)


    # Update button
    $updateButton = New-Object System.Windows.Forms.Button
    $updateButton.Size = New-Object System.Drawing.Size(80, 23)
    $updateButton.Text = "Update"
    $updateButton.Dock = "Bottom"
    $updateButton.Add_Click({
            $scriptDir = $PSScriptRoot
            Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass", "-Command & {
            Set-Location '$scriptDir';
            if (Test-Path '.git') {
                Write-Host 'Relaunching in update mode, do not close this window'
                git pull;
                Start-Sleep -Seconds 2; # Sleep for 2 seconds to give the user time to see the result
                Write-Host 'Opening...'
                & main.ps1; # Relaunch the script
            } else {
                Write-Host 'Not a git repository.'
            }
        }"
            $form.Close() # Close the current UI
        })
    $Form.Controls.Add($updateButton)
}

$scriptPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "scripts")

$form = New-Object System.Windows.Forms.Form 
$form.Text = 'Script Launcher'
$form.AutoScroll = $true
$form.MinimumSize = New-Object System.Drawing.Size(300, 100)
$form.Padding = 10
$form.AutoSize = $true
$form.AutoSizeMode = "GrowAndShrink"
$form.StartPosition = "CenterScreen"

Refresh-UI -Form $form -ScriptPath $scriptPath

[void]$form.ShowDialog()
