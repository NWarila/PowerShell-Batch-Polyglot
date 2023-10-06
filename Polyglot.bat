<# ::
@ECHO OFF & Rem/||(

    .SYNOPSIS
    Is used to install an HTTPS WSMan Listener on a computer with a valid certificate.

    .DESCRIPTION
        This script is designed to be called from a Startup/Logon PowerShell GPO.
        The Distinguished Name of the certificate issuer must be passed to the script.

    .PARAMETER Issuer
    The full Distinguished Name of the Issing CA that will have issued the certificate to be used
    for this HTTPS WSMan Listener.

    .PARAMETER DNSNameType
    The allowed DNS Name types that will be used to find a matching certificate. Defaults to Both.

    .PARAMETER MatchAlternate
    The certificate used must also have an alternate subject name containing the DNS name found in
    the subject as well. Defaults to false.

    .PARAMETER Port
    This is the port the HTTPS WSMan Listener will be installed onto. Defaults to 5986.

    .PARAMETER LogFilename
    This optional parameter contains a full path and file name to the log file to create.
    If this parameter is not set then a log file will not be created.

    .EXAMPLE
    Install-WSManHttpsListener -Issuer 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM'
    Install a WSMan HTTPS listener from an appropriate machine certificate issued by
    'CN=LABBUILDER.COM Issuing CA, DC=LABBUILDER, DC=COM'.

    .EXAMPLE
    Install-WSManHttpsListener -Issuer 'CN=CONTOSO.COM Issuing CA, DC=CONTOSO, DC=COM' -Port 7000
    Install a WSMan HTTPS listener from an appropriate machine certificate issued by
    'CN=LABBUILDER.COM Issuing CA, DC=LABBUILDER, DC=COM' on port 7000.


)

:# Disabling argument expansion avoids issues with ! in arguments.
SetLocal EnableExtensions DisableDelayedExpansion

:# Temporarily Ignore Zone Checking
SET "SEE_MASK_NOZONECHECKS=1"

:# Define Intial Variable(s)
FOR %%V in (noCLS noWait isUNC didTimeout) DO (SET "%%V=FALSE")
SET "startDir=%cd%" & SET "scriptDir=%~dp0"

:# Extract Non-PowerShell Variables.
@ECHO. %ARGS% | Findstr /I /C:"\?NoCLS">nul && (SET "NoCLS=TRUE" & SET "ARGS=%ARGS:?NoCLS =%")
@ECHO. %ARGS% | Findstr /I /C:"\?NoWait">nul && (SET "NoWait=TRUE" & SET "ARGS=%ARGS:?NoWait =%")
@ECHO. %ARGS% | Findstr /I /C:"\?NoAdmin">nul && (SET "NoAdmin=TRUE" & SET "ARGS=%ARGS:?NoAdmin =%")

:# Prepare the batch arguments, so that PowerShell parses them correctly
SET ARGS=%*
IF defined ARGS set ARGS=%ARGS:"=\"%
IF defined ARGS set ARGS=%ARGS:'=''%

:# Enforce Elevation If Required.
IF "%NoAdmin%" == "FALSE" (
    net session >nul 2>&1 || (
        ECHO. Script requires elevation
        pause >nul
        EXIT /B 1
    )
)

:# Escape the file path for all possible invalid characters.
SET "FilePath=%FilePath:'=''%"
SET "FilePath=%FilePath:^=^^%"
SET "FilePath=%FilePath:[=`[%"
SET "FilePath=%FilePath:]=`]%"
SET "FilePath=%FilePath:&=^&%"

:# Ensure path is utilizing a lettered drive path.
SET "FilePath=%~f0"
IF "%FilePath:~0,2%" == "\\" PUSHD "%~dp0"
IF "%FilePath:~0,2%" == "\\" SET "FilePath=%CD%\%~nx0"
IF NOT "%FilePath:~0,2%" == "\\" CD "%~dp0"

:# Always move to local directory.
IF "%StartDir:%~0,2%" == "\\" (
    SET "isUNC=True"
    PUSHD "%~dp0"
) ELSE (
    If NOT "%scriptDir%" == "%startDir" (
        CD /D "%~dp0"
    )
)

:# ============================================================================================================ #:
:# The ^ before the first " ensures that the Batch parser does not enter quoted mode there, but that it enters  #:
:# and exits quoted mode for every subsequent pair of ". This in turn protects the possible special chars & | < #:
:# > within quoted arguments. Then the \ before each pair of " ensures that PowerShell's C command line parser  #:
:# considers these pairs as part of the first and only argument following -c. Cherry on the cake, it's possible #:
:# to pass a " to PS by entering two "" in the bat args.                                                        #:
:# ============================================================================================================ #:
ECHO In BATCH; Entering PowerShell.
"%WinDir%\System32\WindowsPowerShell\v1.0\powershell.exe" -c ^
    ^"Invoke-Expression ('^& {' + (get-content -raw '%FilePath%') + '} %ARGS%')"
ECHO Exited PowerShell; Back in BATCH.

:# Wait 60 seconds before closing.
IF "%noWait%" == "FALSE" (
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

@endlocal
GOTO:END

:# ###############################################################################################################
:# #>

:END
