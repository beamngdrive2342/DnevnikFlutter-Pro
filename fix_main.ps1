$header = Get-Content 'c:\src\DnevnikFlutter\lib\main_header.dart.tmp'
$main = Get-Content 'c:\src\DnevnikFlutter\lib\main.dart'
$tail = $main[373..($main.Count-1)]
$result = $header + $tail
$result | Set-Content 'c:\src\DnevnikFlutter\lib\main.dart' -Encoding UTF8
Write-Host "Done. Total lines: $($result.Count)"
