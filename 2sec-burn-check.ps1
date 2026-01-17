# =====================================================================
# 2SEC Burn Vault Monitor + Burn + Math Check (Pure PowerShell)
# =====================================================================

# Log file and HTML file paths
$HTML_FILE = "C:\Users\carlo\OneDrive\Desktop\TwoSecondBurn-Time-based-deflation\index.html"
$LOG_FILE  = "C:\Users\carlo\OneDrive\Desktop\TwoSecondBurn-Time-based-deflation\2sec-burn-log.txt"


$VAULT_ID = "0x02edb12e7affd2ef0e77788ff6596ac854ec9a91645479acca78baad177e589a"
$PACKAGE  = "0xf7323565fb71c360edc39a93b2524f88997a87f2d396c693dbf8185151fb8bce"
$MODULE   = "sec2"
$FUNCTION = "interact"
$AUTH     = "0x6fdbb7911b730eaff65c04613b94c513a95b4d636a047b632fff0d2eeaeddb65"
$CLOCK    = "0x6"
$GAS_BUDGET = 20000000

$DECIMALS = 1000000000   # 9 decimals for token units
$BOOST_RATE = 15         # tokens per second in boost phase

function Get-VaultBalance {
    $json = sui client object $VAULT_ID --json | ConvertFrom-Json
    $raw = [Int64]$json.content.fields.internal_pool
    $tokens = [math]::Round($raw / $DECIMALS, 0)
    
    $last_ts = [Int64]$json.content.fields.last_ts
    $version = $json.version

    return @{
        Raw      = $raw
        Tokens   = $tokens
        LastTs   = $last_ts
        Version  = $version
        FullJson = $json
    }
}

Write-Host "=== 2SEC Burn Vault Check & Burn Cycle ===" -ForegroundColor Cyan
Write-Host "Current time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# Step 1 - Before
Write-Host "Step 1: Getting current vault state..." -ForegroundColor Yellow
$before = Get-VaultBalance

Write-Host "Version: $($before.Version)"
Write-Host "Last timestamp: $($before.LastTs)"
Write-Host "Current balance: $($before.Tokens) 2SEC"
Write-Host "Raw internal_pool: $($before.Raw)`n"

# Wait before burn
Write-Host "Waiting 15 seconds before triggering burn..." -ForegroundColor DarkGray
Start-Sleep -Seconds 5

# Step 2 - Burn
Write-Host "Step 2: Calling interact (burn trigger)..." -ForegroundColor Green
$callOutput = sui client call `
    --package $PACKAGE `
    --module $MODULE `
    --function $FUNCTION `
    --args $VAULT_ID $AUTH $CLOCK `
    --gas-budget $GAS_BUDGET

Write-Host $callOutput -ForegroundColor Gray
Write-Host "Burn call submitted. Waiting 10 seconds for finalization..." -ForegroundColor DarkGray
Start-Sleep -Seconds 5

# Step 3 - After
Write-Host "Step 3: Getting new vault state after burn..." -ForegroundColor Yellow
$after = Get-VaultBalance

Write-Host "New Version: $($after.Version)"
Write-Host "New Last timestamp: $($after.LastTs)"
Write-Host "New balance: $($after.Tokens) 2SEC"
Write-Host "New Raw internal_pool: $($after.Raw)`n"

# Step 4 - Math check
$seconds = $after.LastTs - $before.LastTs
$burned = $before.Tokens - $after.Tokens
$expected = $seconds * $BOOST_RATE

Write-Host "=== Burn Calculation ===" -ForegroundColor Magenta
Write-Host "Time elapsed between snapshots: $seconds seconds (~$([math]::Round($seconds/60,1)) minutes)"
Write-Host "Tokens burned: $burned"
Write-Host "Expected at 15/sec (boost phase): $expected"

if ($burned -eq $expected) {
    Write-Host "→ PERFECT MATCH with boost rate!" -ForegroundColor Green
} elseif ($burned -lt $expected) {
    Write-Host "→ Burned less than expected (possibly pool limit, partial interval or multiple calls)" -ForegroundColor Yellow
} else {
    Write-Host "→ Something unexpected - burned more than theoretical" -ForegroundColor Red
}

Write-Host "`nDone! Run the script again after a longer wait for bigger burns." -ForegroundColor Cyan
# === Logging to text file ===
$logLine = "{0} | Before: {1} | After: {2} | Burned: {3} | Expected: {4}" -f `
    (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
    $before.Tokens,
    $after.Tokens,
    $burned,
    $expected

Add-Content -Path $LOG_FILE -Value $logLine


# === Append burn entry inside <div id="burn-log"> ===

# Build the HTML entry
$entry = "<div>{0} | Before: {1} | After: {2} | Burned: {3} | Expected: {4}</div>" -f `
    (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
    $before.Tokens,
    $after.Tokens,
    $burned,
    $expected

# Read the HTML file
$html = Get-Content $HTML_FILE -Raw

# Insert the entry BEFORE the closing </div> of burn-log
$updated = $html -replace '(?s)(<div id="burn-log".*?)(</div>)', "`$1`n$entry`n`$2"

# Write back to file
Set-Content -Path $HTML_FILE -Value $updated
