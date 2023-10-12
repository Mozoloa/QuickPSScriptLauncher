# QuickPSScriptLauncher
*A quick way to launch powershell scripts, handy for your numerous cloned githubs if you use conda etc*

## Installation & Usage
1. Git clone this repo
2. Right click `main.ps1` > `run with powershell` *(An optional taskbar pin-able shortcut will appear next to it)*
3. Create personalised *category* subfolders inside **scripts** to put your scripts in
4. Example of correct folder structure :
```md
📄 main.ps1
📂 scripts
├── 📂 Deepfake
│   └── 📄 FaceFusion.ps1
├── 📂 Image
│   ├── 📄 FastCaption.ps1
│   └── 📄 Kohya.ps1
...
```
1. Hit `Refresh` to refresh the UI
2. Launch your scripts by clicking on their name


### Other buttons

- `📂` : Browse to the execution `$location` of the script (see *Script Example* bellow)
- `📺` : Launch a powershell windows in this execution `$location`
- `Scripts` : Open the script library
- `Update` : Execute `git pull` in this repository for updates (⚠️ ***experimental, only works if you git cloned this repo***) 


## Script example
*Using a github repo with conda env*
```
$location =  "path/to/repo" # It's important to set this variable, else the  📂 and 📺 buttons won't appear 
Set-location $location
conda activate envname
git pull # if you want to auto update
python app.py
```
## Current UI
![Alt text](ReadmeImages/UI.png)
