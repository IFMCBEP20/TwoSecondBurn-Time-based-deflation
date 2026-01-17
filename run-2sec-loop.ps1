while ($true) {

    # Run your burn script
    & "C:\Users\carlo\OneDrive\Desktop\TwoSecondBurn-Time-based-deflation\2sec-burn-check.ps1"

    # Navigate to your repo
    Set-Location "C:\Users\carlo\OneDrive\Desktop\TwoSecondBurn-Time-based-deflation"

    # Configure Git (only needed once)
    git config user.name "2SECSUI"
    git config user.email "molmcd15@gmail.com"

    # Stage and commit the updated files
    git add index.html
    git add 2sec-burn-log.txt

    git commit -m "Auto-update burn log $(Get-Date)" --allow-empty

    # Push using your token
    git push https://$env:GITHUB_TOKEN@github.com/2SECSUI/TwoSecondBurn-Time-based-deflation.git

    # Wait 10 minutes
    Start-Sleep -Seconds 600
}
