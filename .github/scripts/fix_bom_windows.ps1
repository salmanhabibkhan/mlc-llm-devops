# Remove potential UTF-8 BOM from CMakeLists.txt to avoid CMake parse errors

Get-ChildItem -Recurse -Filter "CMakeLists.txt" | ForEach-Object {
    $raw   = Get-Content -Path $_.FullName -Raw
    $clean = $raw -replace "^\uFEFF", ""

    Set-Content -Path $_.FullName -Value $clean -Encoding UTF8
}
