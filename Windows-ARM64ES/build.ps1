$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$llvm = 'C:\Program Files\LLVM\bin'
if (Test-Path -LiteralPath $llvm) {
    $env:Path = $llvm + ';' + $env:Path
}

if (-not (Test-Path -LiteralPath 'build')) {
    New-Item -ItemType Directory -Path 'build' | Out-Null
}

& llvm-dlltool -m arm64 -d compiler\kernel32.def -l build\libkernel32.a
if ($LASTEXITCODE -ne 0) {
    Write-Output ('llvm-dlltool failed (exit ' + $LASTEXITCODE + ')')
    exit 1
}

$objs = @()
foreach ($src in Get-ChildItem -LiteralPath 'compiler' -Filter '*.S' -File | Sort-Object Name) {
    $obj = Join-Path 'build' ($src.BaseName + '.o')
    & clang --target=aarch64-w64-mingw32 -DTARGET_WINDOWS -c ('compiler\' + $src.Name) -o $obj
    if ($LASTEXITCODE -ne 0) {
        Write-Output ('clang failed on ' + $src.Name + ' (exit ' + $LASTEXITCODE + ')')
        exit 1
    }
    $objs += $obj
}

& lld-link -nologo -entry:start -subsystem:console -nodefaultlib -out:ender.exe @objs build\libkernel32.a
if ($LASTEXITCODE -ne 0) {
    Write-Output ('lld-link failed (exit ' + $LASTEXITCODE + ')')
    exit 1
}

Write-Output 'built ender.exe'
exit 0
