$ErrorActionPreference = 'Stop'
$reportPath = Join-Path $PSScriptRoot 'CratAble_บทที่1-3_แผนประเมิน.docx'
$pdfPath = Join-Path $PSScriptRoot 'CratAble_บทที่1-3_แผนประเมิน.pdf'
$wordApp = $null
$reportDoc = $null
try {
    $wordApp = New-Object -ComObject Word.Application
    $wordApp.Visible = $false
    $wordApp.DisplayAlerts = 0
    $reportDoc = $wordApp.Documents.Open($reportPath, $false, $false)
    $reportDoc.Content.LanguageID = 1054
    $reportDoc.Content.Font.Name = 'Angsana New'
    $reportDoc.Content.Font.NameBi = 'Angsana New'
    $reportDoc.Content.Font.Size = 16
    $reportDoc.Content.Font.SizeBi = 16
    $reportDoc.Content.ParagraphFormat.DisableLineHeightGrid = $true
    $reportDoc.Repaginate()
    $reportDoc.Fields.Update() | Out-Null
    $reportDoc.Save()
    $reportDoc.ExportAsFixedFormat($pdfPath, 17)
    Write-Output ('Pages: ' + $reportDoc.ComputeStatistics(2))
    Write-Output $pdfPath
} finally {
    if ($null -ne $reportDoc) { $reportDoc.Close(0); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($reportDoc) | Out-Null }
    if ($null -ne $wordApp) { $wordApp.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null }
}
