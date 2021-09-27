# Azure - validate migrating resources to new subscription

## Intro / Problem Description

While it is possible to move resources to a new subscription using the Azure portal, if you want to first validate whether or not resources can be moved or if there are errors, this is not yet a capability that exists in the portal.

In order to determine ahead of time and plan accordingly if the resources (entire Resource Group) can be moved or need to make adjustments, this requires the use of the REST API 'Resources - Validate Move Resources' (https://docs.microsoft.com/en-us/rest/api/resources/resources/validate-move-resources)

There are a few existing blogs which provide step by step on how to check one Resource Group at a time utilizing the REST API: 
* This blog uses Postman which is easy to setup without much scripting experience (https://www.cloudcorner.gr/microsoft/azure/validate-azure-resource-move-with-postman/)
* Another blog uses a PowerShell script which some may prefer, but only checks one Resource Group at a time (https://www.pedholtlab.com/migrate-between-azure-subscriptions-like-a-pro/)

While these are great resources to check individual Resource Group moves before attempting, I have had many customer scenarios needing to assess their entire Azure environments, namely moving out of CSP type subscriptions. In these cases plugging in one Resource Group at a time would be an arduous task.

The script in this repository assesses an entire Azure subscription, and outputs in a text file whether resources can be moved as-is (entire resource group) and lists any resources needing attention before attempting the move.

To keep things simple, I have chosen to make the target resource group the same for all. In a real world scenario, when completeing the move would have a target Resource Group mapped to existing Resource Groups. Since we are not actually moving anything, only validating, using the same Resource Group as a target should not be an issue.

## Pre-requisite steps to run script

### Resource Providers

The target subscription needs to have the required Resource Providers registered, otherwise you will get output full of errors. 

Either register one by one in the portal, or if you are like me and do not like doing repetitive things by hand :smile: here is a link to a script I wrote to use an input CSV file to loop through and register each one: https://github.com/JuliaHazelwood/Azure-Register_MultipleAzResourceProviders_fromCSV

### Service Principal

Create a Service Principal in Azure AD, make sure to notate the Application (client) ID, Tenant ID, and Client secret - this disappears after you leave the page so write it down!

More information on creating a Service Principal if needed can be found here: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal

### Subscription / Resource Group permissions needed

The permissions needed to perform the 'Validate Move Resources' operation are outlined below, I found it easiest to create a custom RBAC role and assign at the target Resource Group level, and a custom RBAC role at the subscription level of source subscription with less permissions can also be created, outlined below separately.

#### * Resource Group level (target Resource Group) - custom RBAC role JSON:

Some of the actions listed showed up when analyzing an environment, when testing in your environment depending on the resource type, may need more / less actions. The standard required actions are:
* '*/read'
* 'Microsoft.Resources/subscriptions/resourceGroups/validateMoveResources/action'

**Full actions section from my environment testing for convenience:**

`"actions": [
                    "*/read",
                    "Microsoft.Resources/subscriptions/resourceGroups/validateMoveResources/action",
                    "Microsoft.Storage/storageAccounts/write",
                    "Microsoft.Logic/workflows/write",
                    "Microsoft.OperationalInsights/workspaces/write",
                    "Microsoft.Web/connections/write"
                ]`

#### * Subscription level (source subscription) - custom RBAC role JSON:

`"actions": [
                    "*/read",
                    "Microsoft.Resources/subscriptions/resourceGroups/validateMoveResources/action"
                ]`
                
### File path for output text

The script writes to the following path: `C:\Users\$env:USERNAME\Documents\ValidateResourceMoves.txt`
ensure that when running, the user has rights to this path for the output otherwise change to some other path.

### Variables to update in PowerShell script

In the PowerShell file located in this repo titled **Validate_AzResourceMoveToNewSubscription.ps1**, will need to update some of the variables in the file. Below is a list and the corresponding line number describing what needs to be updated before running the script:

* `$ClientID` - Line 4 - this is the in the portal labeled **Application (client) ID** in Azure AD
* `$client_Secret` - Line 5 - this is gathered from the portal upon creation of Service Principal, upon leaving the page you can no longer go back to this. If did not notate, simply create a new secret.
* `$tenant_id` - Line 7 - this is the tenant ID of the Azure Active Directory associated with the subscription that the resources currently exist in.
* `$SubscriptionID` - Line 26 - subscription ID of the source where resources currently exist
* `$targetResourceGroup` - Line 75 - for this variable, update the guid for target subscription and resource group name. In my example, I am hardcoding the same target resource group simply to determine can the resources be moved. Of course, when actually going through with moving resources more than one target resource group would be used. 
