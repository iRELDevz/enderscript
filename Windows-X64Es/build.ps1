$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Test-Path -LiteralPath 'build')) {
    New-Item -ItemType Directory -Path 'build' | Out-Null
}

$sources = @(Get-ChildItem -LiteralPath 'compiler' -Filter '*.asm' -File | Sort-Object Name)
if ($sources.Count -eq 0) {
    Write-Output 'no compiler\*.asm files found'
    exit 1
}

$objs = @()
foreach ($src in $sources) {
    $obj = Join-Path 'build' ($src.BaseName + '.obj')
    & nasm -f win64 -I compiler/inc/ -o $obj ('compiler\' + $src.Name)
    if ($LASTEXITCODE -ne 0) {
        Write-Output ('nasm failed on ' + $src.Name + ' (exit ' + $LASTEXITCODE + ')')
        exit 1
    }
    $objs += $obj
}

& gcc -nostdlib -nostartfiles -s '-Wl,-e,start' '-Wl,--subsystem,console' -o ender.exe @objs -lkernel32
if ($LASTEXITCODE -ne 0) {
    Write-Output ('gcc link failed (exit ' + $LASTEXITCODE + ')')
    exit 1
}

Write-Output 'built ender.exe'
exit 0
