Add-Type -AssemblyName System.Web

# Values for AAD Service Principal
$ClientID = 'guid'
$client_Secret = 'Hi3.......Pla'
$resource = 'https://management.core.windows.net/'
$tenant_id = 'guid'

# If ClientId or Client_Secret has special characters, UrlEncode before sending request
$clientIDEncoded = [System.Web.HttpUtility]::UrlEncode($ClientID)
$client_SecretEncoded = [System.Web.HttpUtility]::UrlEncode($client_Secret)
$resource_Encoded = [System.Web.HttpUtility]::UrlEncode($resource)

$Uri = "https://login.microsoftonline.com/$tenant_id/oauth2/token"
$Body = "grant_type=client_credentials&client_id=$clientIDEncoded&client_secret=$client_SecretEncoded&resource=$resource_Encoded"
$ContentType = "application/x-www-form-urlencoded"

echo $Body

#Login via REST
$admAuth = Invoke-RestMethod -Uri $Uri -Body $Body -ContentType $ContentType -Method Post

echo  $admauth.access_token

#Source SubscriptionId
$SubscriptionId = "guid"

#Construct the header value with the access_token just recieved
$HeaderValue = "Bearer " + $admauth.access_token
#endregion

$RGListUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups?api-version=2019-10-01"

#header info
$rglheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$rglheaders.Add("authorization", $HeaderValue)

#Get all resources in resource group
$rglresponse = ""

$rglresponse = Invoke-RestMethod -Method GET -Uri $RGListUri -Header $rglheaders

foreach ($rg in $rglresponse)
{
    $rgl = $rg.value.name

    foreach ($rgn in $rgl)
    {

        Write-Output "Resource Group Name: $rgn"


        $RGVUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rgn/resources?`$filter=resourceType%20ne%20'Microsoft.Compute/virtualMachines/extensions'%20and%20resourceType%20ne%20'Microsoft.Sql/servers/databases'%20and%20resourceType%20ne%20'Microsoft.Automation/automationAccounts/runbooks'&api-version=2019-10-01"

        #header info
        $rgvheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $rgvheaders.Add("authorization", $HeaderValue)
        
        #Get all resources in resource group
        $response = Invoke-RestMethod -Method GET -Uri $RGVUri -Header $rgvheaders
        
        $r = ""
        $r = $response | ConvertTo-Json
        $rc = $r | ConvertFrom-Json

        ###Testing###
        foreach ($rv in $rc)
        {
            Write-Output "Resource IDs:   "
            Write-Output $rv.value.id
        }

        #Test RG in target subscription for validating resource move
        #Create body for POST validate resource move
        $targetResourceGroup = "/subscriptions/guid/resourceGroups/RGname"
        
        $rgarray = foreach ($rv in $rc) {$rc.value.id}
        
        ###Source resource group name
        $sourceResourceGroup = $rgn
        
        $jbody = New-Object -TypeName "PSCustomObject"
        
        $jbody | Add-Member -Name resources -Value $rgarray -MemberType NoteProperty -Force
        $jbody | Add-Member -Name targetResourceGroup -Value $targetResourceGroup -MemberType NoteProperty -Force
        
        $jconvert = $jbody | ConvertTo-Json
        
        #Create headers for POST validate resource move
        $vrmheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $vrmheaders.Add("authorization", $HeaderValue)
        
        $vrmuri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$sourceResourceGroup/validateMoveResources?api-version=2019-05-10"
        
        $vrmcontenttype = "application/json"
        
        $vrmresponse = Invoke-WebRequest -Method POST -Uri $vrmuri -Headers $vrmheaders -Body $jconvert -ContentType $vrmcontenttype
        
        #Get location from response headers
        $vrmrlocation = $vrmresponse.Headers.Location
        
        ##Get move validation status
        
        ##header info
        $mvsheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $mvsheaders.Add("authorization", $HeaderValue)
        
        $mvsuri = $vrmrlocation
        
        $mvsresponse = Invoke-WebRequest -Method GET -Uri $mvsuri -Header $mvsheaders
        
        Do {
        
            $responsePending = $false
        
            try
            {
                $response = (Invoke-WebRequest -Method GET -Uri $mvsuri -Header $mvsheaders | Select-Object).StatusCode
        
                if ($response -eq "202") {
                    $responsePending = $true
                    Start-Sleep -Seconds 15
                }
            }
            catch
            {
                $response = $_
            }
        
        }
        
        while ($responsePending)
        
        try
        {
            $oErr = $null
        
            $statuscode = Invoke-WebRequest -Method GET -Uri $mvsuri -Header $mvsheaders -ErrorVariable oErr | Select-Object StatusCode
        
        
                if ((Invoke-WebRequest -Method GET -Uri $mvsuri -Header $mvsheaders | Select-Object).StatusCode -eq 204)
                {
                    Write-Output "Resources can be moved"
                    Add-Content -Value "Resources can be moved" -Path C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt

                    Write-Output "Resources: $rgarray"
                    Add-Content -Value "Resources: $rgarray" -Path C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt
                }
                else
                {
                                
                }
        
        }
        catch
        {
            $statuscode = $_
        
            Write-Output "Error, see details:"
            Add-Content -Value "Error, see details:" -Path C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt

            Write-Output $oErr
            Add-Content -Value $oErr -Path C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt

            Write-Output "Resources: $rgarray"
            Add-Content -Value "Resources: $rgarray" -Path C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt
        }


        Write-Output "********************************************************************************************************************************"
        Add-Content -Value "********************************************************************************************************************************" -Path C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt
    }
}