# QuickPSScriptLauncher
*A quick way to launch powershell scripts, handy for your numerous cloned githubs if you use conda etc*

## Installation & Usage
1. Git clone this repo
2. Right click main.ps1 > run with powershell
3. A shortcut will be created at the root, use it to add the program to your taskbar if you want
4. Place your scripts in a subfolder **(not at the root)** of the "scripts" folder, they will then appear in the UI after you hit **Refresh**
5. Example of correct folder structure :
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
6. Launch your scripts by clicking the `▶️` button, they should be launched in a new powershell window
7. browse to the execution `$location` of the script by clicking the `📂` button (see *Script Example* bellow)
8. launch a powershell windows in this execution `$location` by clicking the `📺` button (see *Script Example* bellow)
9. Click `Scripts` to open the script library
10. Click `Update` to `git pull` this repository for updates (⚠️ ***experimental, only works if you git cloned this repo***) 


## Script example
*Using a github repo with conda env*
```
$location =  "path/to/repo" # It's important to set this variable, else the  📂 and PS buttons won't appear 
Set-location $location
conda activate envname
git pull # if you want to auto update
python app.py
```
## Current UI
![Alt text](ReadmeImages/UI.png)
