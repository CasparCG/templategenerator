# CasparCG TemplateGenerator

> To be updated

![stable](https://img.shields.io/badge/stable-n%2Fa-lightgray.svg?style=flat-square)
[![help](https://img.shields.io/badge/help-community%20forum-green.svg?style=flat-square)](https://casparcg.com/forum)
[![irc](https://img.shields.io/badge/irc-%23casparcg-green.svg?style=flat-square)](https://kiwiirc.com/client/sinisalo.freenode.net/?nick=Guest|?#CasparCG)
[![license](https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat-square)](LICENSE)


## Progress - Repository Updates
- [x] Create a new repository at GitHub (CasparCG/templategenerator)
- [x] Create a README
- [X] Find latest version of the TemplateGenerator
- [X] Cleanup current project
- [X] Make sure it builds/works
- [X] Create a .gitignore
- [X] Update README



## Getting Started
This is a extension for Adobe Flash/Animate which will show up in Window->Extension->Template Generator. The View for the panel (/assets/fla/TemplateGeneratorView.fla) is modified using Adobe Animate. It compiles to a swc (/lib/TemplateGeneratorView.swc) which is used in the code.

The panel swf (/bin/Template Generator.swf) is compiled in Flash Develop. The entry point is src/caspar/tools/TemplateGenerator.as. 

The panel calls a jsfl script (/src/caspar/jsfl/brew2_3.jsfl) that injects code into the swf and saves it with the .ft extension and can then be used by caspar cg as a flash template. For testing the jsfl you will need to execute it inside the Animate program. The easiest way to work with the jsfl is to install the extension and edit the brew2_3.jsfl directly in the WindowSWF folder.

https://www.youtube.com/watch?v=mn4IfcDkIhU
https://github.com/CasparCG/help/wiki/Media%3A-Flash-Templates
https://help.adobe.com/archive/en_US/flash/cs5/flash_cs5_extending.pdf

### Prerequisites
Flash Develop
Animate

### Installing
There is a manual installer included, since the adobe extension-handling has changed a lot over time. To build and deploy (so far, windows only):
1. go to /build and run "generateManualInstallFolder.bat"
2. This will create a folder with all the assets (CasparCG Template Generator-v.2.2.0)
3. Copy this folder to C:\Users\{user}\AppData\Local\Adobe\Animate {version}\{lang}, e.g. C:\Users\johndoe\AppData\Local\Adobe\Animate CC 2018\en_US
4. Run the manualInstall.bat inside the folder
5. Restart Animate
6. Now you should find the panel in Window->Extension->Template Generator


## Releases
Every release considered as stable will be tagged according to our versioning principles.  
A complete history of all releases and the changes can be found in the [CHANGELOG](CHANGELOG).


## Versioning
From now on we will start versioning this project according to Semantic Versioning [(SemVer)][1] principles.


## License
CasparCG TemplateGenerator is distributed under the GNU General Public License GPLv3 or higher, see [LICENSE](LICENSE) for details.


[1]: https://semver.org/

