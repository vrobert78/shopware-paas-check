#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo ' __        __   __             __   ___     __   __        ___    __      __        ___  __       '
echo '/__` |__| /  \ |__) |  |  /\  |__) |__     /  ` /  \ |\ | |__  | / _`    /  ` |__| |__  /  ` |__/ '
echo '.__/ |  | \__/ |    |/\| /~~\ |  \ |___    \__, \__/ | \| |    | \__>    \__, |  | |___ \__, |  \ '
echo ''


compare_versions() {
    local current_version="$1"
    local target_version="$2"

    IFS='.' read -ra current_version_components <<< "$current_version"
    IFS='.' read -ra target_version_components <<< "$target_version"

    local comparison_result=2  # Default value (equal)

    for i in "${!current_version_components[@]}"; do
        local current_component="${current_version_components[i]}"
        local target_component="${target_version_components[i]}"

        if [[ "$current_component" -lt "$target_component" ]]; then
            comparison_result=0  # Below
            break
        fi

        if [[ "$current_component" -gt "$target_component" ]]; then
            comparison_result=1  # Above
            break
        fi
    done

    # Return the comparison_result
    return "$comparison_result"
}


###
### Check shopware/core version
###

#Get version installed
SHOPWARE_INSTALLEDVERSION=`composer show shopware/core -d $PLATFORM_APP_DIR --no-cache | sed -n '/version/s/^[^0-9]\+\([^,]\+\).*$/\1/p'`

#Get latest version available
SHOPWARE_LATESTVERSION=`curl -s https://repo.packagist.org/p2/shopware/core.json | jq -r '.packages."shopware/core"[0].version' | sed -n 's/^[^0-9]\+\([^,]\+\).*$/\1/p'`

if [[ "$SHOPWARE_INSTALLEDVERSION" == "$SHOPWARE_LATESTVERSION" ]]; then
  STATUS="${GREEN}ok${NC}"
else
  STATUS="${RED}upgrade recommended${NC}"
fi

echo -e "shopware/core installed=$SHOPWARE_INSTALLEDVERSION latest=$SHOPWARE_LATESTVERSION ... $STATUS"


###
### Check Fastly VCL snippets
###
export HOME=/tmp

if [[ -f "/tmp/fastly/fastly" ]]; then
    FASTLY_VCL_SNIPPETS_CONFIGURED=`/tmp/fastly/fastly vcl snippet list --version=active -j | jq 'map(select(.Name | test("shopware_(deliver|fetch|hash|hit|recv)"; "i"))) | length == 5'`

    if [[ "$FASTLY_VCL_SNIPPETS_CONFIGURED" == "true" ]]; then
        STATUS="${GREEN}configured${NC}"
    else
        STATUS="${RED}not configured${NC}"
    fi
else
    STATUS="${RED}not tested: fastly CLI not found${NC}"
fi

echo -e "Fastly VCL snippets ... $STATUS"


###
### Check Fastly Enabled
###
FASTLY_ENABLED=`$PLATFORM_APP_DIR/bin/console debug:container --parameter storefront.reverse_proxy.fastly.enabled --raw --format json | jq '.["storefront.reverse_proxy.fastly.enabled"]'`

if [[ "$FASTLY_ENABLED" == "true" ]]; then
    STATUS="${GREEN}enabled${NC}"
else
    STATUS="expected: true - value:${RED}$FASTLY_ENABLED${NC}"
fi

echo -e "Fastly ... $STATUS"


###
### Check Soft-Purges
###
FASTLY_SOFT_PURGES_ENABLED=`$PLATFORM_APP_DIR/bin/console debug:container --parameter storefront.reverse_proxy.fastly.soft_purge --raw --format json | jq '.["storefront.reverse_proxy.fastly.soft_purge"]=="1"'`

if [[ "$FASTLY_SOFT_PURGES_ENABLED" == "true" ]]; then
    STATUS="${GREEN}enabled${NC}"
else
    STATUS="${RED}not enabled${NC}"
fi

echo -e "Fastly soft-purges ... $STATUS"


###
### Check CSRF if Shopware < 6.5
###
compare_versions "$SHOPWARE_INSTALLEDVERSION" "6.5"
version_comparison="$?"
if [ "$version_comparison" -eq 0 ]; then
    CSRF_CONFIGURED=`$PLATFORM_APP_DIR/bin/console debug:container --parameter storefront.csrf --raw --format json | jq '(.["storefront.csrf"].enabled == false) or (.["storefront.csrf"].enabled == true and .["storefront.csrf"].mode == "ajax")'`

    if [[ "$CSRF_CONFIGURED" == "true" ]]; then
        STATUS="${GREEN}valid configuration${NC}"
    else
        STATUS="${RED}incorrect configuration${NC}"
    fi

    echo -e "CSRF ... $STATUS"
fi
