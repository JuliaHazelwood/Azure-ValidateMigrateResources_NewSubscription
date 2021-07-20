# Azure - validate migrating resources to new subscription

## Intro / Problem Description

It is possible to move resources to a new subscription using the Azure portal. In order to determine ahead of time and plan accordingly if the resources (entire Resource Group) can be moved, would need to use the REST API - 'Resources - Validate Move Resources' (https://docs.microsoft.com/en-us/rest/api/resources/resources/validate-move-resources)

There are a few existing blogs which provide step by step on how to check one resource at a time. 
* This blog uses Postman which is easy to setup without much scripting experience
* Another blog uses a PowerShell script which for those more familiar with scripts may prefer, still only checks one Resource Group at a time, and provides Response Code of '204' if no error, and must rely on the output for any error details

These are great resources to check individual Resource Group moves before attempting. I have had many customers needing to assess their entire Azure environments where plugging in one Resource Group at a time would be an arduous task.

The script in this repository assesses an entire Azure subscription, and outputs in a text file whether resources can be moved as-is (entire resource group) and any resources needing attention before attempting the move.

To keep things simple, I have chosen to make the target resource group the same for all Resource Group move targets. In real world scenario, when completeing the move would have a target Resource Group mapped to existing Resource Groups.

## Pre-requisitie steps to run script

The target subscription needs to have the required Resource Providers registered, otherwise you will get output full of errors. Can either register one by one in the portal, or if you are like me and do not like doing repetitive things by hand :smile: here is a link to a script I wrote with an input CSV file to loop through and register each one:

The permissions needed to perform the 'Validate Move Resources' operation are outlined here, I found it easiest to create a custom RBAC role and assign at the target Resource Group level, and a custom RBAC role at the subscription level of source subscription with less permissions.

* Custom RBAC role JSON:

"actions": [
                    "*/read",
                    "Microsoft.Resources/subscriptions/resourceGroups/validateMoveResources/action",
                    "Microsoft.Storage/storageAccounts/write",
                    "Microsoft.Logic/workflows/write",
                    "Microsoft.OperationalInsights/workspaces/write",
                    "Microsoft.Web/connections/write"
                ]
