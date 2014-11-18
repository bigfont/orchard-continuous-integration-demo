@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 0.1.11
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

:: FOR_ORCHARD, we changed to this from temp
SET SITE_DIR=%~dp0%..

echo SITE_DIR: "%SITE_DIR%"

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)
echo DEPLOYMENT_SOURCE: "%DEPLOYMENT_SOURCE%"

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%SITE_DIR%\wwwroot
)
echo DEPLOYMENT_TARGET: "%DEPLOYMENT_TARGET%"

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%SITE_DIR%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%SITE_DIR%\manifest
  )
)
echo NEXT_MANIFEST_PATH: "%NEXT_MANIFEST_PATH%"
echo PREVIOUS_MANIFEST_PATH: "%PREVIOUS_MANIFEST_PATH%"

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)
IF NOT DEFINED DEPLOYMENT_TEMP (
  SET DEPLOYMENT_TEMP="%DEPLOYMENT_SOURCE%\build\precompiled"
  SET CLEAN_LOCAL_DEPLOYMENT_TEMP=true
)

IF DEFINED CLEAN_LOCAL_DEPLOYMENT_TEMP (
  
  echo Cleaning local deployment temp.

  IF EXIST "%DEPLOYMENT_TEMP%" rd /s /q "%DEPLOYMENT_TEMP%"
  mkdir "%DEPLOYMENT_TEMP%"
)

IF NOT DEFINED MSBUILD_PATH (
  SET MSBUILD_PATH=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\msbuild.exe
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling .NET Web Application deployment.

:: 1. Restore NuGet packages
IF /I "src\Orchard.sln" NEQ "" (

  echo Restoring NuGet packages

  call :ExecuteCmd nuget restore "%DEPLOYMENT_SOURCE%\src\Orchard.sln"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 2. Build to the temporary path
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (

  echo Running build precompiled

  call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\orchard.proj" /nologo /verbosity:m /t:Precompiled /p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release /p:SolutionDir="%DEPLOYMENT_SOURCE%\src\\" %SCM_BUILD_ARGS%

) ELSE (

  echo Warning: we don't usually performing build precompiled for in place deployment

  call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\orchard.proj" /nologo /verbosity:m /t:Precompiled /p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release /p:SolutionDir="%DEPLOYMENT_SOURCE%\src\\" %SCM_BUILD_ARGS%
)

IF !ERRORLEVEL! NEQ 0 goto error

:: 3. KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (

  echo Copying build results to wwwroot

  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_TEMP%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"

  IF !ERRORLEVEL! NEQ 0 goto error
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Post deployment stub
IF DEFINED POST_DEPLOYMENT_ACTION call "%POST_DEPLOYMENT_ACTION%"
IF !ERRORLEVEL! NEQ 0 goto error

goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
