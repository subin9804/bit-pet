# 폰 ↔ 로컬 백엔드 연결 (adb reverse 터널)
#
# USB 재연결·폰 재부팅·adb 서버 재시작 때마다 터널이 풀린다. 그때 이 스크립트를 다시 돌린다.
#
#   powershell -File C:\Users\subin\Desktop\bit-pet\dev-connect.ps1
#
# 배포(https://tailog.me) 후에는 앱이 인터넷으로 직접 붙으므로 이 스크립트 자체가 필요 없어진다.

$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    Write-Host "adb를 찾을 수 없음: $adb" -ForegroundColor Red
    exit 1
}

# 포트별 용도. 8080만 걸고 4566을 빠뜨리면 개체 목록은 뜨는데
# 상세 화면의 사진에서만 SocketException 이 난다 (사진 URL이 LocalStack을 가리킴).
#
# ⚠️ 해시테이블을 쓰지 않는다. [ordered] 는 정수 인덱싱을 "키"가 아니라 "순번"으로 해석해서
#    $ports[8080] 이 8080번째 항목을 찾다가 빈 값이 된다.
$ports = @(
    [pscustomobject]@{ Port = 8080; Label = "백엔드 API";          Path = "/api/v1/memo-tags"; Hint = "백엔드 서버(bootRun)가 떠 있는지 확인" }
    [pscustomobject]@{ Port = 4566; Label = "LocalStack (사진/S3)"; Path = "/";                 Hint = "docker compose up -d 확인" }
)

Write-Host "`n[1/3] 기기 확인" -ForegroundColor Cyan
$devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }

if (-not $devices) {
    Write-Host "  연결된 기기 없음 — USB 케이블/충전전용 케이블 확인" -ForegroundColor Red
    exit 1
}
if ($devices -match 'unauthorized') {
    Write-Host "  승인 대기 중 — 폰 화면의 'USB 디버깅을 허용하시겠습니까?'에서 [항상 허용]" -ForegroundColor Yellow
    exit 1
}
$devices | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

Write-Host "`n[2/3] 터널 연결" -ForegroundColor Cyan
foreach ($e in $ports) {
    & $adb reverse "tcp:$($e.Port)" "tcp:$($e.Port)" | Out-Null
    Write-Host "  tcp:$($e.Port) → $($e.Label)" -ForegroundColor Green
}

Write-Host "`n[3/3] 폰에서 실제 응답 확인" -ForegroundColor Cyan
$allOk = $true
foreach ($e in $ports) {
    # 서버가 안 떠 있으면 터널만 걸려 있고 응답은 000 이 나온다. 터널 존재와 서버 기동은 별개다.
    $code = (& $adb shell "curl -s -o /dev/null -w '%{http_code}' http://localhost:$($e.Port)$($e.Path)").Trim()

    if ($code -eq "200") {
        Write-Host "  tcp:$($e.Port)  HTTP $code  OK" -ForegroundColor Green
    } else {
        $allOk = $false
        Write-Host "  tcp:$($e.Port)  HTTP $code  실패 — $($e.Hint)" -ForegroundColor Red
    }
}

if ($allOk) {
    Write-Host "`n준비 완료. 앱을 실행하세요.`n" -ForegroundColor Green
} else {
    Write-Host "`n터널은 걸렸지만 응답하지 않는 포트가 있습니다.`n" -ForegroundColor Yellow
    exit 1
}
