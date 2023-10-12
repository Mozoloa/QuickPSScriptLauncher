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

$bgCol = [System.Drawing.ColorTranslator]::FromHtml("#050505")
$accentCol = [System.Drawing.ColorTranslator]::FromHtml("#ffbb50")
$hoverCol = [System.Drawing.ColorTranslator]::FromHtml("#201000")
$primCol = [System.Drawing.ColorTranslator]::FromHtml("#1c0f01")
$secondCol = [System.Drawing.ColorTranslator]::FromHtml("#999999")
$btnCol = [System.Drawing.ColorTranslator]::FromHtml("#202020")
$style = [System.Windows.Forms.FlatStyle]::Flat
$iconSize = 15

function Get-Icon {
    param (
        [string]$iconPath,
        [int]$width = $iconSize,
        [int]$height = $iconSize
    )

    $icon = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot $iconPath))
    return $icon.GetThumbnailImage($width, $height, $null, [IntPtr]::Zero)
}

$PSIcon = Get-Icon ".\icons\ps.png"
$openFolderImage = Get-Icon ".\icons\browse.png"
$LaunchIcon = Get-Icon ".\icons\launch.png"



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
        $groupBox.ForeColor = $secondCol
        
        $Form.Controls.Add($groupBox)
        

        foreach ($script in $scripts) {
            $tablePanel = New-Object System.Windows.Forms.TableLayoutPanel
            $tablePanel.Dock = "Top"
            $tablePanel.RowCount = 1
            $tablePanel.Height = 30
            $tablePanel.ForeColor = $accentCol
            $tablePanel.ColumnCount = 3  # Changed from 2 to 3
            $tablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Default to full width
                      
            # Create the script execution button
            $button = New-Object System.Windows.Forms.Button
            $button.Dock = [System.Windows.Forms.DockStyle]::Fill
            $button.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 9)
            $button.Image = $LaunchIcon
            $button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleRight
            $button.Text = "$($script.BaseName)"
            $button.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $button.Tag = $script.FullName
            $button.FlatStyle = $style
            $button.FlatAppearance.BorderSize = 0
            $button.FlatAppearance.MouseOverBackColor = $hoverCol
            $button.BackColor = $btnCol
            $button.Add_Click({
                    $path = $this.Tag
                    $arguments = "-ExecutionPolicy Bypass -NoExit -File `"$path`""
                    Start-Process PowerShell -ArgumentList $arguments
                })
            $tablePanel.Controls.Add($button, 0, 0) # Add button to first column
        
            # Check for $location variable in the script
            $scriptContent = Get-Content -Path $script.FullName -Raw
            if ($scriptContent -match '^\s*\$location\s*=\s*"([^"]+)"') {
                $locationPath = $matches[1]
                $locationButton = New-Object System.Windows.Forms.Button
                $locationButton.Dock = [System.Windows.Forms.DockStyle]::Fill
                $locationButton.Image = $openFolderImage
                $locationButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
                $locationButton.Text = ""
                $locationButton.Image = $openFolderImage
                $locationButton.Tag = $locationPath
                $locationButton.FlatStyle = $style
                $locationButton.BackColor = $bgCol
                $locationButton.ForeColor = $secondCol
                $locationButton.FlatAppearance.BorderSize = 0
                $locationButton.FlatAppearance.MouseOverBackColor = $bgCol
                $locationButton.Add_Click({
                        Start-Process explorer.exe -ArgumentList $this.Tag
                    })
                $tablePanel.Controls.Add($locationButton, 1, 0) # Add button to second column

                $powershellButton = New-Object System.Windows.Forms.Button
                $powershellButton.Dock = [System.Windows.Forms.DockStyle]::Fill
                $powershellButton.Image = $PSIcon
                $powershellButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
                $powershellButton.Text = ""
                $powershellButton.Tag = $locationPath
                $powershellButton.FlatStyle = $style
                $powershellButton.BackColor = $bgCol
                $powershellButton.ForeColor = $secondCol
                $powershellButton.FlatAppearance.BorderSize = 0
                $powershellButton.FlatAppearance.MouseOverBackColor = $bgCol
                $powershellButton.Add_Click({
                        Start-Process PowerShell -ArgumentList "-NoExit", "-Command", "cd '$($this.Tag)'"
                    })
                $tablePanel.Controls.Add($powershellButton, 2, 0) # Add button to third column
            
                $tablePanel.ColumnStyles[0].Width = 70  # Adjust the first column to 70%
                $tablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 12))) # Set second column to 15%
                $tablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 12))) # Set third column to 15%

            }
        
            $groupBox.Controls.Add($tablePanel)
        }

    }

    # Refresh button
    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Size = New-Object System.Drawing.Size(115, 23) # Half the original width
    $refreshButton.Text = "Refresh"
    $refreshButton.Dock = "Bottom"
    $refreshButton.FlatStyle = $style
    $refreshButton.Add_Click({
            Refresh-UI -Form $Form -ScriptPath $ScriptPath
        })
    $Form.Controls.Add($refreshButton)

    # Open Folder button
    $openFolderButton = New-Object System.Windows.Forms.Button
    $openFolderButton.Size = New-Object System.Drawing.Size(115, 23) # Half the original width
    $openFolderButton.Text = "Open Folder"
    $openFolderButton.Dock = "Bottom"
    $openFolderButton.FlatStyle = $style
    $openFolderButton.Add_Click({
            Start-Process explorer.exe -ArgumentList $ScriptPath
        })
    $Form.Controls.Add($openFolderButton)


    # Update button
    $updateButton = New-Object System.Windows.Forms.Button
    $updateButton.Size = New-Object System.Drawing.Size(80, 23)
    $updateButton.Text = "Update"
    $updateButton.Dock = "Bottom"
    $updateButton.FlatStyle = $style
    $updateButton.Add_Click({
            $scriptDir = $PSScriptRoot
            Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -file  $scriptDir\update.ps1"
            $form.Close() # Close the current UI
        })
    $Form.Controls.Add($updateButton)
}

$scriptPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "scripts")

$form = New-Object System.Windows.Forms.Form 
$form.Text = "Script Launcher"
$form.AutoScroll = $true
$form.MinimumSize = New-Object System.Drawing.Size(300, 100)
$form.Padding = 10
$form.AutoSize = $true
$form.BackColor = $bgCol
$form.ForeColor = $accentCol
$form.AutoSizeMode = "GrowAndShrink"
$form.StartPosition = "CenterScreen"

Refresh-UI -Form $form -ScriptPath $scriptPath

[void]$form.ShowDialog()

