# QuickPSScriptLauncher
*A quick way to launch scripts, handy for your numerous cloned githubs if you use conda etc*

## Installation & Usage
1. Git clone this repo
2. Right click main.ps1 > run with powershell
3. A shortcut was created at the root, use it to add the program to your taskbar if you want
4. Place your scripts in a subfolder **(not at the root)** of the "scripts" folder, they will then appear in the UI after you hit **Refresh**
5. Launch your scripts by clicking the `▶️` button, they should be launched in a new powershell window
6. browse to the execution `$location` of the script by clicking the `📂` button (see *Script Example* bellow)
7. launch a powershell windows in this execution `$location` by clicking the `PS` button (see *Script Example* bellow)


## Script example
```ps
# Here's an example script to uncomment and modify if you want
$location =  "path/to/repo" 
Set-location $location
conda activate envname
git pull
python app.py
```
