$projectNameToAnalyze = "Radar"


$vstsOrganizationName = "quadroteam"
$vstsPersonalAccessToken = "2gufmmmun5buysm5kac3getsgpdhtb2p7cjpe2r6lbn3jp5bjzla"

$vstsUsername = "thisIsJustNonsense"

$password = "$vstsPersonalAccessToken" | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($vstsUsername,$password)

$pair = "$($vstsUsername):$($vstsPersonalAccessToken)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}


# Do not modify after this point unless you know what you're doing.
Write-Output "Retrieving Projects"
# Get Projects so we get the Project ID
$projects = Invoke-RestMethod -UseBasicParsing "https://$vstsOrganizationName.visualstudio.com/_apis/projects?api-version=4.1" -ContentType "application/json" -Method GET -Headers $Headers

Write-Output "Retrieving Source Project ID"
$project = ($projects | select -ExpandProperty value | Where-Object name -eq "$projectNameToAnalyze")
if (!$project)
{
    throw "Source Project $projectNameToAnalyze not found in VSTS Account $vstsOrganizationName"
}

$teamProjectId = $project.id
$projectName = [System.Web.HttpUtility]::UrlPathEncode($projectNameToAnalyze) 


$repositories = Invoke-RestMethod -UseBasicParsing "https://dev.azure.com/$vstsOrganizationName/$projectName/_apis/git/repositories?api-version=4.1" -ContentType "application/json" -Method GET -Headers $Headers | select -ExpandProperty value

$commitsResults = New-Object System.Collections.Generic.List[System.Object]

foreach ($repo in $repositories)
{
    Write-output "$($repo.name): $($repo.url)"

    $top = 100
    $skip = 0

    do {
        $url = "$($repo.url)/commits?`$skip=$skip&`$top=$top&api-version=4.1"
        Write-Output "URL: $($url)"

        $commits = Invoke-RestMethod -UseBasicParsing $url -ContentType "application/json" -Method GET -Headers $Headers | select -ExpandProperty value
        $skip = ($skip + $top)

        Write-Output "New SKIP: $skip"

        foreach ($commit in $commits)
        {
            Write-Output "$($repo.name): $($commit.committer.date): $($commit.committer.email): Add: $($commit.changeCounts.Add) Edit: $($commit.changeCounts.Edit) Delete: $($commit.changeCounts.Delete) comment: $($commit.comment)"

            [hashtable]$objectProperty = @{}
            $objectProperty.Add('Repo',$repo.name)
            $objectProperty.Add('Date',$commit.committer.date)
            $objectProperty.Add('Email',$commit.committer.email)
            $objectProperty.Add('Adds',$commit.changeCounts.Add)
            $objectProperty.Add('Edits',$commit.changeCounts.Edit)
            $objectProperty.Add('Deletes',$commit.changeCounts.Delete)
            $objectProperty.Add('Comment',$commit.comment)
            $ourObject = New-Object -TypeName psobject -Property $objectProperty
            $commitsResults.Add($ourObject)
        }

    } while ($commits.Count -gt 0)
}

$commitsResults.ToArray() | Export-Csv -Path D:\temp\commits.csv -Delimiter "|"