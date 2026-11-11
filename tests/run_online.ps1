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
    # Each command is published once. Windows readers can keep the previous file open.
    $path = Join-Path $Results ($Client + '_command_' + $Command.seq + '.json')
    [IO.File]::WriteAllText($path + '.tmp', ($Command | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
    [IO.File]::Move($path + '.tmp', $path)
    $response = Join-Path $Results ($Client + '_' + $Command.seq + '.json')
    $deadline = [DateTime]::UtcNow.AddSeconds(25)
    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-Path -LiteralPath $response) {
            try { return [IO.File]::ReadAllText($response) | ConvertFrom-Json }
            catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw } }
        }
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
    $null = Send-QA $guestId @{op='flip_deck';id='QADeck'}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'guest_flip_syncs_back' ((Component $h QADeck).pile_face_down -and (Component $g QADeck).pile_face_down -and (Component $h QADeck).deck_back_visible -and (Component $g QADeck).deck_back_visible)
    $null = Send-QA $guestId @{op='request_sync';settle=2}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'flip_survives_resync' ((Component $g QADeck).pile_face_down -and (Component $g QADeck).deck_back_visible)
    $null = Send-QA $hostId @{op='flip_deck';id='QADeck'}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'host_flip_restores_faces' (-not (Component $h QADeck).pile_face_down -and -not (Component $g QADeck).pile_face_down -and -not (Component $g QADeck).deck_back_visible)
    $null = Send-QA $hostId @{op='locked_selector'}
    $null = Send-QA $guestId @{op='request_sync';settle=2}
    $g = Send-QA $guestId @{op='select_locked_deck'}
    $deckId = $g.extra.deck_id
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'rotated_zone_caption_upright_on_both' ((Component $h 'QALockedSelector').label_upright -and (Component $g 'QALockedSelector').label_upright)
    Check 'guest_selected_locked_deck_on_both' ($g.extra.selector_opened -and (Component $g $deckId).locked -and (Component $h $deckId).locked -and (Component $g $deckId).deck_back_visible -and (Component $h $deckId).deck_back_visible)
    $null = Send-QA $guestId @{op='flip_deck';id=$deckId}
    $null = Send-QA $guestId @{op='request_sync';settle=2}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'locked_face_up_after_resync' ((Component $g $deckId).locked -and (Component $h $deckId).top_texture -and (Component $g $deckId).top_texture -and (Component $g $deckId).top -eq (Component $h $deckId).top)
    $handsBefore = @($h.hand_count, $g.hand_count)
    $pileBefore = @((Component $h $deckId).draw_pile)
    $drawTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0 + 3
    $null = Send-QA $hostId @{op='draw';id=$deckId;at=$drawTime;settle=0.1}
    $g = Send-QA $guestId @{op='draw';id=$deckId;at=$drawTime;settle=4}
    $h = Send-QA $hostId @{op='snapshot'}
    Check 'both_click_locked_deck' ($h.hand_count -eq $handsBefore[0] + 1 -and $g.hand_count -eq $handsBefore[1] + 1)
    $drawn = @(@($h.components | Where-Object in_hand)[-1].card_ref, @($g.components | Where-Object in_hand)[-1].card_ref)
    Check 'different_cards_dealt' ($pileBefore[-1] -in $drawn -and $pileBefore[-2] -in $drawn -and $drawn[0] -ne $drawn[1])
    Check 'shared_next_card_after_simultaneous_draw' ((Component $h $deckId).draw_pile.Count -eq 1 -and (Component $g $deckId).draw_pile.Count -eq 1 -and (Component $h $deckId).top -eq $pileBefore[0] -and (Component $g $deckId).top -eq (Component $h $deckId).top -and (Component $h $deckId).top_texture -and (Component $g $deckId).top_texture)
    $null = Send-QA $hostId @{op='deck';id='MissingCardDeck';missing_card=$true}
    $null = Send-QA $guestId @{op='draw';id='MissingCardDeck';settle=2}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'failed_lookup_preserves_pile_and_hand' ($g.last_action -like 'จั่วไม่ได้*' -and (Component $h MissingCardDeck).draw_pile.Count -eq 1 -and (Component $g MissingCardDeck).draw_pile.Count -eq 1 -and $g.hand_count -eq $handsBefore[1] + 1)
    $null = Send-QA $hostId @{op='nested_fixture'}
    $null = Send-QA $guestId @{op='request_sync';settle=2}
    $null = Send-QA $guestId @{op='nested_drop'}
    $h = Send-QA $hostId @{op='snapshot'}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'nested_drop_replicates' ($null -ne (Component $h QANestedCard) -and $null -ne (Component $g QANestedCard))
    Check 'nested_drop_position_matches' ((Component $h QANestedCard).x -eq (Component $g QANestedCard).x -and (Component $h QANestedCard).y -eq (Component $g QANestedCard).y)
    $null = Send-QA $guestId @{op='reconnect';settle=6}
    $g = Send-QA $guestId @{op='snapshot'}
    Check 'reconnect_recovers_session' ($g.connected -and $null -ne (Component $g QANestedCard))
    Check 'reconnect_no_duplicates' (@($g.components.id | Select-Object -Unique).Count -eq $g.components.Count)
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
        $path = Join-Path $Results ($client + '_command_' + $seq + '.json')
        [IO.File]::WriteAllText($path + '.tmp', ('{"op":"quit","seq":' + $seq + '}'))
        [IO.File]::Move($path + '.tmp', $path)
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(5000)) { $process.Kill() }
    }
}
