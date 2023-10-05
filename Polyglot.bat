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

:# Temporarily Ignore Zone Checking
SET "SEE_MASK_NOZONECHECKS=1"

:# Define Intial Variable(s)
FOR %%V in (noCLS noWait isUNC didTimeout) DO (SET "%%V=FALSE")
SET "startDir=%cd%" & SET "scriptDir=%~dp0"

:# Extract Non-PowerShell Variables.
@ECHO. %ARGS% | Findstr /I /C:"\?NoCLS">nul && (SET "NoCLS=TRUE" & SET "ARGS=%ARGS:?NoCLS =%")
@ECHO. %ARGS% | Findstr /I /C:"\?NoWait">nul && (SET "NoWait=TRUE" & SET "ARGS=%ARGS:?NoWait =%")
@ECHO. %ARGS% | Findstr /I /C:"\?NoAdmin">nul && (SET "NoAdmin=TRUE" & SET "ARGS=%ARGS:?NoAdmin =%")

:# Enforce Elevation If Required.
IF "%NoAdmin%" == "FALSE" (
    net session >nul 2>&1 || (
        ECHO. Script requires elevation
        pause >nul
        EXIT /B 1
    )
)

:# Always move to local directory.
IF "%StartDir:%~0,2%" == "\\" (
    SET "isUNC=True"
    PUSHD "%~dp0"
) ELSE (
    If NOT "%scriptDir%" == "%startDir" (
        CD /D "%~dp0"
    )
)

:# PowerShell Shit goes here

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
