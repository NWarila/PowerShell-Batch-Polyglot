<# :: Start of the PS comment around the Batch Section ###########################################################
@ECHO OFF

@REM Disabling argument expansion avoids issues with ! in arguments.
SetLocal EnableExtensions DisableDelayedExpansion

@REM Temporarily Ignore Zone Checking
SET "SEE_MASK_NOZONECHECKS=1"

@REM Define Intial Variable(s)
FOR %%V in (noCLS noWait isUNC didTimeout NoAdmin getHelp) DO (SET "%%V=FALSE")
SET "ARGS=%*" & SET "startDir=%cd%" & SET "scriptDir=%~dp0" & SET "FilePath=%~f0"

@REM Extract Non-PowerShell Variables.
ECHO. %ARGS% | Findstr /I /C:" \?NoCLS">nul && (SET "NoCLS=TRUE" & SET "ARGS=%ARGS:?NoCLS=%")
ECHO. %ARGS% | Findstr /I /C:" \?NoWait">nul && (SET "NoWait=TRUE" & SET "ARGS=%ARGS:?NoWait=%")
ECHO. %ARGS% | Findstr /I /C:" \?NoAdmin">nul && (SET "NoAdmin=TRUE" & SET "ARGS=%ARGS:?NoAdmin=%")
ECHO. %ARGS% | Findstr /I /C:" \?GetHelp">nul && (SET "getHelp=TRUE" & SET "ARGS=%ARGS:?GetHelp=%")

@REM Clear the screen up.
If /I "%NoCLS%" == "False" ( CLS )

@REM Prepare the batch arguments, so that PowerShell parses them correctly
If /I "%getHelp%" == "True" (
    SET "ARGS=-ShowHelp"
) Else (
    IF defined ARGS set ARGS=%ARGS:"=\"%
    IF defined ARGS set ARGS=%ARGS:'=''%
)

@REM Enforce Elevation If Required.
IF "%NoAdmin%" == "FALSE" (
    net session >nul 2>&1 || (
        ECHO. Script requires elevation
        pause >nul
        EXIT /B 1
    )
)

@REM Ensure path is utilizing a lettered drive path.
IF "%FilePath:~0,2%" == "\\" DO (
    PUSHD "%~dp0"
    SET "isUNC=True"
) Else (
    If NOT "%scriptDir%" == "%startDir" (
        CD /D "%~dp0"
    )
)
SET "FilePath=%CD%\%~nx0"

@REM Escape the file path for all possible invalid characters.
SET "FilePath=%FilePath:'=''%" & SET "FilePath=%FilePath:^=^^%" & SET "FilePath=%FilePath:[=`[%"
SET "FilePath=%FilePath:]=`]%" & SET "FilePath=%FilePath:&=^&%"

@REM ========================================================================================================== #:
@REM The ^ before the first " ensures that the Batch parser does not enter quoted mode there, but that it       #:
@REM enters and exits quoted mode for every subsequent pair of ". This in turn protects the possible special    #:
@REM chars & | < within quoted arguments. Then the \ before each pair of " ensures that PowerShell's C command  #:
@REM line parser considers these pairs as part of the first and only argument following -c. Cherry on the cake, #:
@REM it's possible to pass a " to PS by entering two "" in the bat args.                                        #:
@REM ========================================================================================================== #:
::@ECHO In BATCH; Entering PowerShell.
"%WinDir%\System32\WindowsPowerShell\v1.0\powershell.exe" -c ^
    ^"Invoke-Expression ('^& {' + (get-content -raw '%FilePath%') + '} %ARGS%')"
::@ECHO Exited PowerShell; Back in BATCH.

@REM Wait 60 seconds before closing.
IF NOT "%noWait%" == "TRUE" (
    TIMEOUT /T 60
)

if "%isUNC%" == "TRUE" (
    IF "%noWait"=="True" (
        TIMEOUT /T 5 >nul
    )
    POPD
) ELSE (
    If NOT "%scriptDir%" == "%startDir" (
        CD /D "%startDir%"
    )
)

@REM Exit Script
@endlocal & CALL ::EOF & EXIT /B

:# ############### End of the PS comment around the Batch section; Begin the PowerShell section. ############ : #>
Param (
    [Switch]$ShowHelp
)

If ($ShowHelp -eq $True) {
    Write-Host -Object:@'
    NAME
        Get-HotFix

    SYNOPSIS
        Gets the hotfixes that have been applied to the local and remote computers.


    SYNTAX
        Get-HotFix [-ComputerName <String[]>] [-Credential <PSCredential>] [-Description
        <String[]>] [<CommonParameters>]

        Get-HotFix [[-Id] <String[]>] [-ComputerName <String[]>] [-Credential
        <PSCredential>] [<CommonParameters>]


    DESCRIPTION
        The Get-Hotfix cmdlet gets hotfixes (also called updates) that have been installed
        on either the local computer (or on specified remote computers) by Windows Update,
        Microsoft Update, or Windows Server Update Services; the cmdlet also gets hotfixes
        or updates that have been installed manually by users.


    RELATED LINKS
        Online Version: http://go.microsoft.com/fwlink/?LinkId=821586
        Win32_QuickFixEngineering http://go.microsoft.com/fwlink/?LinkID=145071
        Get-ComputerRestorePoint
        Add-Content

    REMARKS
        To see the examples, type: "get-help Get-HotFix -examples".
        For more information, type: "get-help Get-HotFix -detailed".
        For technical information, type: "get-help Get-HotFix -full".
        For online help, type: "get-help Get-HotFix -online"
'@
Exit 0
}
