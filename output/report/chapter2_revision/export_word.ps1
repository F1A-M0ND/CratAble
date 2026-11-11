$ErrorActionPreference = 'Stop'
$taskDoc = Join-Path $PSScriptRoot 'CratAble_บทที่2_ฉบับปรับปรุง.docx'
$taskPdf = Join-Path $PSScriptRoot 'qa/CratAble_บทที่2_ฉบับปรับปรุง.pdf'
$wordApp = $null
$wordDoc = $null
try {
    $wordApp = New-Object -ComObject Word.Application
    $wordApp.Visible = $false
    $wordApp.DisplayAlerts = 0
    $wordDoc = $wordApp.Documents.Open($taskDoc, $false, $false)
    $wordDoc.Content.LanguageID = 1054
    $wordDoc.Content.Font.Name = 'Angsana New'
    $wordDoc.Content.Font.NameBi = 'Angsana New'
    $wordDoc.Content.Font.Size = 16
    $wordDoc.Content.Font.SizeBi = 16
    $wordDoc.Content.ParagraphFormat.DisableLineHeightGrid = $true
    $wordDoc.Repaginate()
    $wordDoc.Fields.Update() | Out-Null
    $wordDoc.Save()
    $wordDoc.ExportAsFixedFormat($taskPdf, 17)
    Write-Output ('Pages: ' + $wordDoc.ComputeStatistics(2))
} finally {
    if ($null -ne $wordDoc) { $wordDoc.Close(0); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordDoc) | Out-Null }
    if ($null -ne $wordApp) { $wordApp.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null }
}
