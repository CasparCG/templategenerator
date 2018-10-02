@echo off
set outName="CasparCG Template Generator-v.2.2.0"

rmdir /s /q %outName% 
mkdir %outName%
:: Start copy
echo. 
echo +Copy files
echo. 

xcopy "..\src\caspar\template\TemplateMain.as" %outName%"\Classes\casparCG\caspar\template\"
xcopy /f /y "..\src\caspar\jsfl\*" %outName%"\WindowSWF\"
xcopy /f /y ".\templates\*" %outName%"\Templates\CasparCG\*"
xcopy ".\helpers\ManualInstallationReadme.txt" %outName%"\"
xcopy "..\lib\CasparCGFramework-v.2.0.1.swc" %outName%"\Libraries\casparCG\"
xcopy "..\bin\Template Generator.swf" %outName%"\WindowSWF\"
xcopy /f /y ".\settings\*" %outName%"\WindowSWF\"
xcopy /f /y ".\helpers\manualInstall.bat" %outName%"\"
xcopy /f /y ".\helpers\WINDOWS_ManualInstallationReadme.txt" %outName%"\"