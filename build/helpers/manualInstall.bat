@echo off

:: Start copy
echo. 
echo +Copy files
echo. 
copy "WindowSWF" "..\Configuration\WindowSWF"
XCOPY "Classes" "..\Configuration\Classes" /E /Y /I 
XCOPY "Libraries" "..\Configuration\Libraries" /E /Y /I 
XCOPY "Templates" "..\Configuration\Templates" /E /Y /I 

