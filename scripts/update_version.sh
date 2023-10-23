#!/bin/bash

# Function to get the latest published version from npm
get_current_version() {
    npm show @cubeca/cubecommons-api-client version
}

# Function to increment the version number
increment_version() {
    local version=$1
    npx semver $version -i minor
}

# Function to update the version in package.json
update_package_json() {
    local new_version=$1
    ./node_modules/.bin/jq ".version = \"$new_version\"" package.json > temp.json && mv temp.json dist/cubecommons-api-client/package.json
}

# Ensure dependencies to run this script are installed
dependencies() {
    if ! command -v jq &> /dev/null
    then
        echo "jq could not be found, installing locally..."
        npm install jq
    fi

    if ! npx semver -v &> /dev/null
    then
        echo "semver could not be found, installing locally..."
        npm install semver
    fi
}

# Main script logic
main() {
    dependencies

    local current_version=$(get_current_version)
    if [ -z "$current_version" ]; then
        echo "Could not fetch current version. Exiting."
        exit 1
    fi
    echo "Current version: $current_version"

    local new_version=$(increment_version $current_version)
    if [ -z "$new_version" ]; then
        echo "Could not increment version. Exiting."
        exit 1
    fi
    echo "New version: $new_version"

    update_package_json $new_version
    if [ $? -ne 0 ]; then
        echo "Failed to update package.json. Exiting."
        exit 1
    fi
    echo "Updated package.json with the new version."
}

# Execute the main script logic
main
