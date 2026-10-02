param(
    [Parameter(Mandatory)][string]$Engine,
    [Parameter(Mandatory)][string]$Project,
    [Parameter(Mandatory)][string]$Results
)
$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path -LiteralPath $Project).Path
$Engine = (Resolve-Path -LiteralPath $Engine).Path
New-Item -ItemType Directory -Path $Results -Force | Out-Null
$Results = (Resolve-Path -LiteralPath $Results).Path
$runId = [guid]::NewGuid().ToString('N')
$hostId = 'host_' + $runId
$guestId = 'guest_' + $runId
$channel = 'QA_CratAble_' + $runId
$sequences = @{}
$processes = @()
$checks = [ordered]@{}

function Send-QA([string]$Client, [hashtable]$Command) {
    if (-not $sequences.ContainsKey($Client)) { $sequences[$Client] = 0 }
    $sequences[$Client]++
    $Command.seq = $sequences[$Client]
    $path = Join-Path $Results ($Client + '_command.json')
    [IO.File]::WriteAllText($path + '.tmp', ($Command | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath ($path + '.tmp') -Destination $path -Force
    $response = Join-Path $Results ($Client + '_' + $Command.seq + '.json')
    $deadline = [DateTime]::UtcNow.AddSeconds(25)
    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-Path -LiteralPath $response) { return Get-Content -LiteralPath $response -Raw | ConvertFrom-Json }
        Start-Sleep -Milliseconds 100
    }
    throw "Timeout: $Client $($Command.op)"
}
function Component($Snapshot, [string]$Id) { @($Snapshot.components | Where-Object id -eq $Id)[0] }
function Check([string]$Name, [bool]$Passed) {
    $checks[$Name] = $Passed
    if (-not $Passed) { throw "Failed: $Name" }
}
try {
    foreach ($client in @($hostId, $guestId)) {
        $args = @('--headless', '--path', ('"' + $Project + '"'), '--max-fps', '60',
            '--quit-after', '10800', '--log-file', ('"' + (Join-Path $Results ($client + '-engine.log')) + '"'),
            'res://tests/online_peer.tscn', '--', ('qa-id=' + $client), ('"qa-results=' + $Results + '"'))
        $processes += Start-Process -FilePath $Engine -ArgumentList $args -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $Results ($client + '-stdout.log')) `
            -RedirectStandardError (Join-Path $Results ($client + '-stderr.log'))
    }
    $h = Send-QA $hostId @{op='online_start';role='Host';channel=$channel;settle=3}
    $g = Send-QA $guestId @{op='online_start';role='Guest';channel=$channel;settle=3}
    Check 'both_subscribed' ($h.connected -and $g.connected)
    $null = Send-QA $hostId @{op='deck'}
    $null = Send-QA $hostId @{op='draw';id='QADeck'}
    $counter = (Send-QA $hostId @{op='add_counter'}).extra.created_id
    $dice = (Send-QA $hostId @{op='add_dice'}).extra.created_id
    $null = Send-QA $hostId @{op='add_zone'}
    $null = Send-QA $hostId @{op='card'}
    $null = Send-QA $hostId @{op='flip';id='QACard'}
    $null = Send-QA $guestId @{op='counter';id=$counter;value=27}
    $null = Send-QA $guestId @{op='roll';id=$dice}
    $null = Send-QA $guestId @{op='request_sync';settle=2}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'no_duplicate_objects' (@($h.components.id | Select-Object -Unique).Count -eq $h.components.Count -and @($g.components.id | Select-Object -Unique).Count -eq $g.components.Count)
    Check 'one_draw_only' ((Component $h QADeck).draw_pile.Count -eq 5 -and (Component $g QADeck).draw_pile.Count -eq 5 -and $h.hand_count -eq 1)
    Check 'synced_draw_order' (((Component $h QADeck).draw_pile -join '|') -eq ((Component $g QADeck).draw_pile -join '|'))
    Check 'guest_dice_broadcast' ((Component $h $dice).dice -eq (Component $g $dice).dice -and (Component $h $dice).dice -ne 'D6: -')
    Check 'counter_survives_sync' ((Component $h $counter).value -eq 27 -and (Component $g $counter).value -eq 27)
    Check 'face_survives_sync' ((Component $g QACard).is_face_down -eq $true)
    Check 'raw_card_data' ((Component $g QACard).card_atk -eq 123 -and (Component $g QACard).card_name -eq 'QA custom card')
    Check 'no_extra_zone_on_sync' (@($h.components | Where-Object category -eq zone).Count -eq 1 -and @($g.components | Where-Object category -eq zone).Count -eq 1)
    $g = Send-QA $guestId @{op='draw';id='QADeck'}
    $h = Send-QA $hostId @{op='disconnect';settle=5}
    Check 'host_reconnects' $h.connected
    $null = Send-QA $guestId @{op='request_sync';settle=2}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'guest_can_draw_after_sync' ($g.hand_count -eq 1 -and (Component $h QADeck).draw_pile.Count -eq 4 -and (Component $g QADeck).draw_pile.Count -eq 4)

    $g = Send-QA $guestId @{op='drop_hand';x=1050;y=650}
    $played = $g.extra.card_id
    Check 'one_drag_callback' ($g.extra.drag_end_connections -eq 1)
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'guest_hand_card_visible' ($null -ne (Component $h $played))
    Check 'guest_drop_position_and_rotation' ((Component $h $played).x -eq (Component $g $played).x -and (Component $h $played).y -eq (Component $g $played).y -and (Component $h $played).rotation -eq (Component $g $played).rotation)
    $g = Send-QA $guestId @{op='rotate_handle';id=$played}
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'rotation_handle_sync' ((Component $h $played).rotation -eq (Component $g $played).rotation -and (Component $g $played).rotation -eq 270)
    $g = Send-QA $guestId @{op='click_dice';id=$dice}
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'locked_dice_click_sync' ((Component $h $dice).dice -eq (Component $g $dice).dice -and (Component $g $dice).dice -ne 'D6: -')
    $null = Send-QA $guestId @{op='to_hand';id=$played}
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'private_hand_removed_remotely' ($null -eq (Component $h $played))
    $g = Send-QA $guestId @{op='drop_hand';x=900;y=500}
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'replayed_card_returns' ($null -ne (Component $h $played) -and (Component $h $played).x -eq (Component $g $played).x)
    $null = Send-QA $hostId @{op='return_private_card';id='QADeck'}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'private_card_return_updates_pile' ((Component $h QADeck).draw_pile.Count -eq 5 -and (Component $g QADeck).draw_pile.Count -eq 5)
    $null = Send-QA $guestId @{op='exit_button'}
    $g = Send-QA $guestId @{op='local_start'}
    Check 'local_session_reset' ($g.room_id -eq '' -and $g.role -eq 'Host' -and $g.field_rotation -eq 0 -and -not $g.connected)
    foreach ($client in @($hostId, $guestId)) {
        $errorLog = Get-Content -LiteralPath (Join-Path $Results ($client + '-stderr.log')) -Raw
        Check ($client.Split('_')[0] + '_no_engine_errors') (-not ($errorLog -match '(?m)^(SCRIPT ERROR|ERROR):'))
    }
    Write-Output "ONLINE_RESULT $($checks.Count)/$($checks.Count)"
} finally {
    [IO.File]::WriteAllText((Join-Path $Results 'online_checks.json'), ($checks | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
    foreach ($client in @($hostId, $guestId)) {
        $seq = 1 + $sequences[$client]
        [IO.File]::WriteAllText((Join-Path $Results ($client + '_command.json')), ('{"op":"quit","seq":' + $seq + '}'))
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(5000)) { $process.Kill() }
    }
}
