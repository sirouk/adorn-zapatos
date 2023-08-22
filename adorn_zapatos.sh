#!/bin/bash

# requisites
sudo apt install rename


# settings
log_file_prefix="adorn_zapatos_changelog"
git_org="sirouk"
script_name=$(basename $0)
avoid_paths="-not -path './.git*' -not -path '*/.git/*' -not -path './$script_name' -not -path './$log_file_prefix*'"
repos_to_rename=()
packages_to_test=()

# env
script_dirname=$(cd "$(dirname "$0")" && pwd)
echo "Working Directory: $script_dirname"


# https://github.com/0o-de-lally/libra-framework/blob/publish-move/docs/core_devs/dependency_management.md

# Our code management strategy means we separate some concerns and have clear APIs between each major system component.

# NOTES FROM MENTORS:
# 0D — 05/31/2023 7:16 PM
# Cool. Because my dream is to have a script that can just run in CI service that pulls every major change from Aptos, renames it, and sends a pull request to the Diem original repo.

# 0D — 06/01/2023 4:21 PM
# I expect this can be a bit tricky. Since the module cargo.toml files are what matter, and the names and paths need to match exactly with the root level cargo.toml

# W — 08-21-2023 at 11:55 PM
# We have a aptos fork callled zapatos with a branch that we use as a package/dependency for our software(libra-framework). This decouples the vast majority of the code and also helps because we have a active(very well funded) community building upon it features that we cant afford. But we need to be careful introducing changes into our codebase, having the separation gives us composability that even they dont have.
# the main branch only accepts changes upstream form the parent repo aptos so we always have a clean branch we can bring in changes with as little modification as possible to our dev branch.
# We are now somewhat independant but reliant on the zapatos code but their is nothing saying that we can for example have a similar setup with sui or combine pieces of each together. 

# W — 08-22-2023 at 12:07 AM
# so I think if the dev branch has everything named zapatos from aptos and everytime we pull in changes the renaming script is part of the ci. It should work. 

# In the libra-framework repo then we only ever reference zapatos from the main cargo.toml all the children then just use {workspace = true}. When running the software packages we wont get all of those references to aptos



# zapatos (which remains as-is) and will be our "staging" repo for pulling in changes
# the changes happen in our dev branch, while the main only accepts changes from the upstream parent repo aptos
# https://github.com/0LNetworkCommunity/zapatos
repos_to_rename+=("zapatos")
# Zapatos just needs to compile, this is the aptos code
packages_to_test+=("cargo check -p diem-node")


# this was libra-v7
# Libra Framework: is responsible for the framework source and tools to test and deploy etc. This is mostly original source that wraps or relies heavily on Move Language and Diem Platform (see below).
# https://github.com/0LNetworkCommunity/libra-framework
repos_to_rename+=("libra-framework")
# Just run a compilation check
packages_to_test+=("cargo check -p libra-framework")


# Diem Platform: is infrastructural network node source (database, consensus, networking, configs, testing). There are linear commits to Facebook's Diem and today is maintained primarily by Matonee Inc (Aptos).
# W: this will be deprecated or left for historical purposes
# https://github.com/0LNetworkCommunity/diem-platform
repos_to_rename+=("diem-platform")
# Just run a compilation check
packages_to_test+=("cargo check -p diem-node")



# Carpe: The app is a reference light miner and wallet. This is original source imports our libra-tools and tower
# https://github.com/0LNetworkCommunity/carpe
repos_to_rename+=("carpe")
# List the files
packages_to_test+=("ls -lhat")



# RENAME
#### = disabled temp for testing
for i in ${!repos_to_rename[@]}; do
    
    # Base test dir
    cd $script_dirname/

    # Log and Std Output
    exec > >(tee -i $script_dirname/$log_file_prefix-renaming-${repos_to_rename[$i]}.log) 2>&1
    
    echo "Now Renaming: ${repos_to_rename[$i]}"

    # wipe and fetch anew
    rm -Rf $script_dirname/${repos_to_rename[$i]}
    
    git clone https://github.com/$git_org/${repos_to_rename[$i]}
    cd $script_dirname/${repos_to_rename[$i]}

    # work under a new branch
    git checkout -b adorn-zapatos

    # Files 
    find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i -e 's/aptos/diem/g' -e 's/Aptos/Diem/g' -e 's/APTOS/DIEM/g' {} \;

    # Directories
    find $script_dirname/${repos_to_rename[$i]}/ -depth -iname '*aptos*' $avoid_paths -exec rename -d -v 's/aptos/diem/g' {} \;
    find $script_dirname/${repos_to_rename[$i]}/ -depth -iname '*aptos*' $avoid_paths -exec rename -d -v 's/Aptos/Diem/g' {} \;
    find $script_dirname/${repos_to_rename[$i]}/ -depth -iname '*aptos*' $avoid_paths -exec rename -d -v 's/APTOS/DIEM/g' {} \;


    # FIRST PRIORITY 
    # Revert aptos-core, aptos-labs, and strings like aptos_account.test.ts
    #### find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -E -i 's#(github\.com/)([^/]*)diem#\1\2aptos#g; s#(github\.com/[^ ]*)diem#\1aptos#g' {} \;

    #find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -E -i 's#(github\.com/)([^/]*)diem-node#\1\2aptos-node#g; s#(github\.com/[^ ]*)diem-node#\1aptos-node#g' {} \;

    # Revert nuanced strings
    # replace @diem-labs with @aptos-labs
    find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i 's/diem-labs/aptos-labs/g' {} \;
    #find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i 's/diemlabs/aptoslabs/g' {} \;

    # replace diem.dev with aptos.dev
    #### find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i 's/diem.dev/aptos.dev/g' {} \;


    # SECONDARY
    # update Copyright © Diem with Aptos credits
    #### find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i 's/© Diem Foundation/© Diem (wtih contributions from © Aptos Foundation)/g' {} \;

    # replace Diem Foundation with Aptos Foundation
    #### find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i 's/Diem Foundation/© Diem (wtih contributions from © Aptos Foundation)/g' {} \;

    # replace -diem@ with -aptos@
    #### find $script_dirname/${repos_to_rename[$i]}/ -type f $avoid_paths -exec sed -i 's/-diem@/-aptos@/g' {} \;

    # Manage log
    sed -i "s#$script_dirname##g" $script_dirname/$log_file_prefix-renaming-${repos_to_rename[$i]}.log
    mv $script_dirname/$log_file_prefix-renaming-${repos_to_rename[$i]}.log $script_dirname/${repos_to_rename[$i]}/


    # Git Commit
    # Add all changed files to the staging area
    git add .

    # Commit the changes with a message
    git commit -m "Renaming operations completed on $(date +'%Y-%m-%d %H:%M:%S')"

    
done



# TEST
for i in ${!packages_to_test[@]}; do

    # Base test dir
    cd $script_dirname/${repos_to_rename[$i]}

    # Log and Std Output
    exec > >(tee -i $script_dirname/$log_file_prefix-testing-${repos_to_rename[$i]}.log) 2>&1

    echo "Now Testing: ${repos_to_rename[$i]} via '${packages_to_test[$i]}'"
    cd $script_dirname/${repos_to_rename[$i]}
    ${packages_to_test[$i]}


    #Manage log
    sed -i "s#$script_dirname##g" $script_dirname/$log_file_prefix-testing-${repos_to_rename[$i]}.log
    mv $script_dirname/$log_file_prefix-testing-${repos_to_rename[$i]}.log $script_dirname/${repos_to_rename[$i]}/

    # Git Commit
    # Add all changed files to the staging area
    git add .

    # Commit the changes with a message
    git commit -m "Testing completed and necessary modifications done on $(date +'%Y-%m-%d %H:%M:%S')"
done


echo "Renaming & Testing Complete!"