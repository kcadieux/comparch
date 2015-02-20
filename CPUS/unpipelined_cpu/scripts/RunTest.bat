@echo off
setlocal

IF "%1%"=="" (
	ECHO FAILURE: No test file was specified
	GOTO EXIT
)

pushd "%~dp0..\quartus"

::Convert the backslashes to forward slashes because Tcl likes forward slashes for paths
SET TOP_LEVEL_DIR=%~dp0..
SET TOP_LEVEL_DIR=%TOP_LEVEL_DIR:\=/%

::Pass initial commands to vsim. These will set up the environment of the runtest.tcl script
SET TEST_NAME=%1%
SET TEST_FILE_PATH=%TOP_LEVEL_DIR%/tests/%TEST_NAME%.asm

IF NOT EXIST "%TEST_FILE_PATH%" (
    ECHO FAILURE: The test file provided does not exist in the tests folder.
	GOTO EXIT
)

SET COMMANDS="set topLevelDir \"%TOP_LEVEL_DIR%\"; set testName %TEST_NAME%; source \"%TOP_LEVEL_DIR%/scripts/runtest.tcl\"; quit"

vsim.exe -c -nostdout -do %COMMANDS%
popd

:EXIT

endlocal