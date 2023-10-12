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

# Define styles for different types of buttons
function PrimaryButton {
    param (
        [string]$Text,
        [string]$Tag,
        [scriptblock]$OnClick
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Dock = [System.Windows.Forms.DockStyle]::Fill
    $button.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 9)
    $button.Image = $LaunchIcon
    $button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $button.Text = $Text
    $button.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $button.Tag = $Tag
    $button.FlatStyle = $style
    $button.FlatAppearance.BorderSize = 0
    $button.FlatAppearance.MouseOverBackColor = $hoverCol
    $button.BackColor = $btnCol
    $button.Add_Click($OnClick)

    return $button
}

function SecondaryButton {
    param (
        [System.Drawing.Image]$Image,
        [string]$Tag,
        [scriptblock]$OnClick
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Dock = [System.Windows.Forms.DockStyle]::Fill
    $button.Image = $Image
    $button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $button.Text = ""
    $button.Tag = $Tag
    $button.FlatStyle = $style
    $button.BackColor = $bgCol
    $button.ForeColor = $secondCol
    $button.FlatAppearance.BorderSize = 0
    $button.FlatAppearance.MouseOverBackColor = $bgCol
    $button.Add_Click($OnClick)

    return $button
}

function ActionButton {
    param (
        [string]$Text,
        [scriptblock]$OnClick,
        [string]$anchor
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Dock = "Bottom"
    $button.FlatStyle = $style
    $button.AutoSize = $true
    $button.Width = 82
    $button.Add_Click($OnClick)

    return $button
}

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
        $groupBox.Text = $folder.Name.ToUpper()
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
            $executeButtonAction = {
                $path = $this.Tag
                $arguments = "-ExecutionPolicy Bypass -NoExit -File `"$path`""
                Start-Process PowerShell -ArgumentList $arguments
            }
            $button = PrimaryButton -Text "$($script.BaseName)" -Tag $script.FullName -OnClick $executeButtonAction
            $tablePanel.Controls.Add($button, 0, 0) # Add button to first column
        
            # Check for $location variable in the script
            $scriptContent = Get-Content -Path $script.FullName -Raw
            if ($scriptContent -match '^\s*\$location\s*=\s*"([^"]+)"') {

                $locationButtonAction = {
                    Start-Process explorer.exe -ArgumentList $this.Tag
                }

                $locationPath = $matches[1]
                $locationButton = SecondaryButton -Image $openFolderImage -Tag $locationPath -OnClick $locationButtonAction
                $tablePanel.Controls.Add($locationButton, 1, 0) # Add button to second column

                $powershellButtonAction = {
                    Start-Process PowerShell -ArgumentList "-NoExit", "-Command", "cd '$($this.Tag)'"
                }
                $powershellButton = SecondaryButton -Image $PSIcon -Tag $locationPath -OnClick $powershellButtonAction                
                $tablePanel.Controls.Add($powershellButton, 2, 0) # Add button to third column
            
                $tablePanel.ColumnStyles[0].Width = 70  # Adjust the first column to 70%
                $tablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 12))) # Set second column to 15%
                $tablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 12))) # Set third column to 15%

            }
        
            $groupBox.Controls.Add($tablePanel)
        }

    }

    # Create a FlowLayoutPanel
    $bottomPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $bottomPanel.Dock = "Bottom"
    $bottomPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $bottomPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 0) # Padding between items
    $bottomPanel.AutoSize = $true
    $bottomPanel.AutoSizeMode = "GrowAndShrink"
    $form.Controls.Add($bottomPanel)

    # Refresh button
    $refreshButtonAction = { Refresh-UI -Form $Form -ScriptPath $ScriptPath }
    $refreshButton = ActionButton -Text "Refresh" -OnClick $refreshButtonAction

    # Open Folder button
    $openButtonAction = { Start-Process explorer.exe -ArgumentList $ScriptPath }
    $openFolderButton = ActionButton -Text "Scripts" -OnClick $openButtonAction


    # Update button
    $updateButtonAction = {
        $scriptDir = $PSScriptRoot
        Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass", "-file `"$scriptDir\update.ps1`""
        $form.Close() 
    }
    $updateButton = ActionButton -Text "Update" -OnClick $updateButtonAction -anchor "Right"

    # Add buttons to the bottom panel
    $bottomPanel.Controls.Add($refreshButton)
    $bottomPanel.Controls.Add($openFolderButton)
    $bottomPanel.Controls.Add($updateButton)
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
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

Refresh-UI -Form $form -ScriptPath $scriptPath

[void]$form.ShowDialog()

