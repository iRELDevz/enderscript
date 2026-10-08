param(
    [string]$Compiler = '',
    [string]$Filter = ''
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$script:passed = 0
$script:failed = 0

if ($Compiler -eq '') {
    $Compiler = Join-Path (Split-Path $PSScriptRoot -Parent) 'ender.exe'
}
$compiler = (Resolve-Path -LiteralPath $Compiler).Path

function Normalize-Text([string]$Text) {
    return $Text.Replace("`r`n", "`n")
}

function Show-Text([string]$Text) {
    if ($Text -eq '') { return '<empty>' }
    return $Text
}

function Invoke-Native([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory) {
    $quoted = @()
    foreach ($a in $Arguments) {
        if ($a -eq '' -or $a -match '\s') { $quoted += ('"' + $a + '"') } else { $quoted += $a }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = ($quoted -join ' ')
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    $proc.WaitForExit()
    $result = [pscustomobject]@{
        ExitCode = $proc.ExitCode
        Stdout   = $stdoutTask.Result
        Stderr   = $stderrTask.Result
    }
    $proc.Dispose()
    return $result
}

function Write-Result([string]$Label, [bool]$Ok, [string[]]$Details) {
    if ($Ok) {
        $script:passed++
        Write-Output ('PASS ' + $Label)
    } else {
        $script:failed++
        Write-Output ('FAIL ' + $Label)
        foreach ($d in $Details) {
            foreach ($line in ($d -split "`n")) {
                Write-Output ('    ' + $line)
            }
        }
    }
}

function Get-Cases([string]$RelDir, [string]$Pattern) {
    $dir = Join-Path $PSScriptRoot $RelDir
    if (-not (Test-Path -LiteralPath $dir)) { return @() }
    return @(Get-ChildItem -LiteralPath $dir -Filter $Pattern -File | Sort-Object Name)
}

function Test-Selected([string]$Name) {
    if ($Filter -eq '') { return $true }
    return $Name.Contains($Filter)
}

function Read-Expect([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return [IO.File]::ReadAllText($Path)
}

foreach ($f in Get-Cases 'check\ok' '*.es') {
    $name = $f.BaseName
    if (-not (Test-Selected $name)) { continue }
    $r = Invoke-Native $compiler @('check', $f.Name) $f.DirectoryName
    $err = (Normalize-Text $r.Stderr).Trim()
    $ok = ($r.ExitCode -eq 0 -and $err -eq '')
    Write-Result ('check\ok\' + $name) $ok @(
        ('expected: exit 0, empty stderr'),
        ('actual: exit ' + $r.ExitCode + ', stderr: ' + (Show-Text $err))
    )
}

foreach ($f in Get-Cases 'check\err' '*.es') {
    $name = $f.BaseName
    if (-not (Test-Selected $name)) { continue }
    $label = 'check\err\' + $name
    $expectText = Read-Expect (Join-Path $f.DirectoryName ($name + '.expect'))
    $r = Invoke-Native $compiler @('check', $f.Name) $f.DirectoryName
    if ($null -eq $expectText) {
        Write-Result $label $false @('missing ' + $name + '.expect')
        continue
    }
    $expected = $expectText.Trim()
    $actualFirst = ((Normalize-Text $r.Stderr) -split "`n")[0].Trim()
    $ok = ($r.ExitCode -eq 1 -and $actualFirst -eq $expected)
    Write-Result $label $ok @(
        ('expected: exit 1, first stderr line: ' + $expected),
        ('actual: exit ' + $r.ExitCode + ', first stderr line: ' + (Show-Text $actualFirst))
    )
}

foreach ($f in Get-Cases 'check\warn' '*.es') {
    $name = $f.BaseName
    if (-not (Test-Selected $name)) { continue }
    $label = 'check\warn\' + $name
    $expectText = Read-Expect (Join-Path $f.DirectoryName ($name + '.expect'))
    $r = Invoke-Native $compiler @('check', $f.Name) $f.DirectoryName
    if ($null -eq $expectText) {
        Write-Result $label $false @('missing ' + $name + '.expect')
        continue
    }
    $expected = (Normalize-Text $expectText).Trim()
    $actual = (Normalize-Text $r.Stderr).Trim()
    $ok = ($r.ExitCode -eq 0 -and $actual -eq $expected)
    Write-Result $label $ok @(
        ('expected: exit 0, stderr:' + "`n" + (Show-Text $expected)),
        ('actual: exit ' + $r.ExitCode + ', stderr:' + "`n" + (Show-Text $actual))
    )
}

$runCases = Get-Cases 'run' '*.es'
if ($runCases.Count -gt 0) {
    $buildTests = Join-Path $PSScriptRoot 'out'
    if (-not (Test-Path -LiteralPath $buildTests)) {
        New-Item -ItemType Directory -Path $buildTests | Out-Null
    }
}
foreach ($f in $runCases) {
    $name = $f.BaseName
    if (-not (Test-Selected $name)) { continue }
    $label = 'run\' + $name
    $exe = Join-Path $PSScriptRoot ('out\' + $name + '.exe')
    $b = Invoke-Native $compiler @('build', $f.Name, '-o', $exe) $f.DirectoryName
    if ($b.ExitCode -ne 0) {
        Write-Result $label $false @(
            ('expected: build exit 0'),
            ('actual: build exit ' + $b.ExitCode + ', stderr: ' + (Show-Text (Normalize-Text $b.Stderr).Trim()))
        )
        continue
    }
    $expectedOut = Read-Expect (Join-Path $f.DirectoryName ($name + '.out'))
    if ($null -eq $expectedOut) {
        Write-Result $label $false @('missing ' + $name + '.out')
        continue
    }
    $r = Invoke-Native $exe @() $f.DirectoryName
    $expected = Normalize-Text $expectedOut
    $actual = Normalize-Text $r.Stdout
    $ok = ($r.ExitCode -eq 0 -and $actual -eq $expected)
    Write-Result $label $ok @(
        ('expected: exit 0, stdout:' + "`n" + (Show-Text $expected)),
        ('actual: exit ' + $r.ExitCode + ', stdout:' + "`n" + (Show-Text $actual))
    )
}

Write-Output ($script:passed.ToString() + ' passed, ' + $script:failed.ToString() + ' failed')
if ($script:failed -gt 0) { exit 1 }
exit 0
