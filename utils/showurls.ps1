#Requires -Version 5.1

# Emits any <http://localhost:4004...> URLs found in an exercise's content.
# Will try to determine the exercise number (e.g. 01) from the current
# directory; failing that, it will fall back to requiring it to be passed as a
# parameter.
#
# This is the Windows PowerShell equivalent of the Bash `showurls` script.

param(
    [string]$Exercise
)

$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot

# Try to determine the exercise number from the trailing digits of the current
# working directory (e.g. when run from within exercises/01).
$ex = $null
if ((Get-Location).Path -match '(\d{2})$') {
    $ex = $Matches[1]
}

# Fall back to the number passed as an argument, zero-padded to two digits.
if (-not $ex) {
    if (-not $Exercise) {
        throw 'Specify exercise number'
    }
    $ex = '{0:D2}' -f [int]$Exercise
}

$readme = Join-Path $here "..\exercises\$ex\README.md"

Select-String -Path $readme -Pattern '<http://localhost:4004.+>' -AllMatches |
    ForEach-Object { $_.Matches } |
    ForEach-Object { $_.Value }
