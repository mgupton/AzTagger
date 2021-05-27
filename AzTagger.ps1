#
# Created: 2021-5-24
# Created By: Michael Gupton
#
# This script will apply tags to Azure resources based on the tags
# specified in the CSV file AzTagger.csv in the current directory.
#
# The existing tags on the resources will be preserved.
#
# Dependencies:
#
#  - Azure Powershell extensions
#  - An authenticated session with the Azure subscription.
#
#       Connect-AzAccount
#       Select-AzSubscription -SubscriptionId <id>
#
#
# The CSV file will have the following format.
#
# resource_name,tag_name,tag_value
#
# - There will be a row for every tag.
#

$AT_TAG_INFO_FILE = "AzTagger.csv"

function main() {
    $tag_info = get_tag_info

    [array]$resource_names = $tag_info | Select-Object -Unique -Property resource_name | Foreach-object {$_.resource_name}

    $resources = get_resources $resource_names

    foreach ($resource in $resources) {
        $existing_tags = get_existing_tags $resource.id
        $new_tags = @{}
        $new_tags += $existing_tags

        [array]$specified_tags = $tag_info | Where-Object {$_.resource_name -eq $resource.name} |  ForEach-Object {@{"name" = $_.tag_name ; "value" = $_.tag_value}}

        foreach ($tag in $specified_tags) {
            if ($(check_for_tags -nameonly $true -existing_tags $existing_tags -name $tag.name)) {                
                $new_tags.Remove($tag.name)
            }
        }

        foreach ($tag in $specified_tags) {
            $new_tags.Add($tag.name, $tag.value)
        }

        apply_tags $resource.id $new_tags
    }
}

function get_tag_info() {
    $tag_info = $(Import-Csv ".\$AT_TAG_INFO_FILE")

    return $tag_info
}

function get_resources($resource_names) {
    $resource_ids = @()

    foreach ($name in $resource_names) {
        
        foreach ($id in $(Get-AzResource -Name $name).ResourceId) {
            $resource_ids += @{"name" = $name; "id" = $id}
        }
    }

    return $resource_ids
}

function get_existing_tags($ResourceId) {
    $tags = $null

    $tags = $(get-AzTag -ResourceId $ResourceId).Properties.TagsProperty
    
    return $tags
}

function apply_tags($ResourceId, $tags) {
    Write-Output "Applying tag"
    New-AzTag  -ResourceId $ResourceId -Tag $tags
}

function check_for_tags([bool]$nameonly, $existing_tags, $name, $value) {

    if ($nameonly -eq $null) {
        foreach ($tag in $existing_tags.GetEnumerator()) {
            if ($name -eq $tag.Key -and $value -eq $tag.Value) {
                return $true
            }
        }
    } else {
        foreach ($tag in $existing_tags.GetEnumerator()) {
            if ($name -eq $tag.Key) {
                return $true
            }
        }        
    }

    return $false
}

main
