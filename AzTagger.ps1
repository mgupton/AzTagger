#
#
#
# Set-Variable AT_CONFIG_FILE -option constant -Value "AzTagger.json"
$AT_CONFIG_FILE = "AzTagger.json"

function main() {
    $config = load_config

    foreach ($asset in $config.assets) {
        $existing_tags = get_existing_tags($asset.resource_id)
        $new_tags = @{}
        $new_tags += $existing_tags
        foreach ($tag in $asset.tags) {
            if (-not (check_for_tags $existing_tags $tag.name $tag.value)) {
                $new_tags.Add($tag.name, $tag.value)
            }
        }
        apply_tags $asset.resource_id $new_tags
    }
}

function load_config() {
    $config = (Get-Content ".\${AT_CONFIG_FILE}" | Out-String | ConvertFrom-Json)

    return $config
}

function get_vms() {
    $ResourceIds = New-Object -TypeName "System.Collections.ArrayList"
    $vms = get-AzVM

    foreach ($vm in $vms) {
        $ResourceIds.Add($vm.Id)
    }

    return $ResourceIds
}

function get_existing_tags($ResourceId) {
    $tags = $null

    $tags = $(get-AzTag -ResourceId $ResourceId).Properties.TagsProperty
    
    return $tags
}

function apply_tags($ResourceId, $tag) {
    Write-Output "Applying tag"
    New-AzTag  -ResourceId $ResourceId -Tag $tag
}

function check_for_tags($existing_tags, $name, $value) {
    foreach ($tag in $existing_tags.GetEnumerator()) {
        if ($name -eq $tag.Key -and $value -eq $tag.Value) {
            return $true
        }
    }

    return $false
}

main
