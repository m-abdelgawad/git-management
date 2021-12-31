#!/usr/bash 
# The above line so the interpreter knows it is a Bash script and to use
# Bash located in /usr/bash

# Declare the paths of the public and private directories with a wildcard
# to list only all directories; as a directory always end with a slash '/'
public_dir="../Public/*/"
private_dir="../Private/*/"

# Create a variable to save our working directory
current_dir=$(pwd)


function list_all_dirs () {
    # A function to echo a list of all directories paths in a specific path,
    # All returned paths are absolute and match windows format rather than linux
    # format.
    # Arguments: 
    #   $1: a string of a relative or absolute path

    # Loop over all directories in the argument path
    for repo in $1
    do
        # Change the current working directory to the current repo
        cd $repo
        # Generally, the output of echo $(pwd) alone will be just like that:
        # /d:/Repos/Public/AIRs-UCIPs-automation-from-Oracle-DB
        # The second part: sed 's/./&:/2' inserts a ':' after the second
        # character to become: /d --> /d:
        # Finally, the third part sed 's/.//1' removes the first character '/'
        # resulting in an output like that:
        # d:/Repos/Public/AIRs-UCIPs-automation-from-Oracle-DB
        echo $(pwd) | sed 's/./&:/2' | sed 's/.//1'
        cd $current_dir
    done
}


function print_array (){
    # A function to print the elements of an array.
    # Arguments: 
    #   $@: an array to be printed element by element

    # Loop over all the elements in the argument array
    for repo in $@
    do
        # echo the current element/path
        printf "\n$repo"
    done
}


function check_clean_repos (){
    # A function to echo all clean git repos paths.
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the repos in the argument array
    for repo in $@
    do
        # Check if the status of the current repo declares that it's clean, and
        # if so, echo the current repo/path
        if git -C $repo status | grep -q "working tree clean"; then
            echo $repo
        fi
    done
}


function check_commit_repos (){
    # A function to echo all git repos paths that have changes that need to 
    # be committed.
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the repos in the argument array
    for repo in $@
    do
        # Check if the status of the current repo declares that it has changes 
        # not staged or untracked files. If so, echo the current repo/path
        if git -C $repo status | grep -q -e "Changes not staged" -e "Untracked files"; then
            echo $repo
        fi
    done
}


function check_push_repos (){
    # A function to echo all git repos paths that have commits that need to 
    # be pushed.
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the repos in the argument array
    for repo in $@
    do
        # Check status of the current repo and filter only repos that have 
        # commits need to be pushed
        if git -C $repo status | grep -q "publish your local commits"; then
            echo $repo
        fi
    done
}


function check_pull_repos (){
    # A function to echo all git repos paths that need to make pull requests.
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the repos in the argument array
    for repo in $@
    do
        # Check status of the current repo and filter only repos that have 
        # pending pull requests
        if git -C $repo status | grep -q "pull"; then
            echo $repo
        fi
    done
}


function check_repos_no_commits_yet (){
    # A function to echo all git repos paths that has no commits yet!
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the repos in the argument array
    for repo in $@
    do
        # Check status of the current repo and filter only repos that don't 
        # have any commits yet!
        if git -C $repo status | grep -q "No commits yet"; then
            echo $repo
        fi
    done
}

# Create an array of all public repos by appending the output of a 
# shell-in-a-shell
declare -a public_repos
public_repos+=($(list_all_dirs "$public_dir"))

# Create an array of all private repos
declare -a private_repos
private_repos+=($(list_all_dirs "$private_dir"))

# Combine the public repos and private repos arrays in one big array
all_repos=("${public_repos[@]}" "${private_repos[@]}")

# Create an array of all clean repos
clean_repos+=($(check_clean_repos ${all_repos[@]}))

# Create an array of changed repos that need to be committed
repos_to_commit+=($(check_commit_repos ${all_repos[@]}))

# Create an array of repos that have commits and need to be pushed
repos_to_push+=($(check_push_repos ${all_repos[@]}))

# Check repos that need to perform a pull request
repos_to_pull+=($(check_pull_repos ${all_repos[@]}))

# Check repos with no commits yet!
repos_no_commits_yet+=($(check_repos_no_commits_yet ${all_repos[@]}))

# Echo a summary of all the results:
# EOS: End of string; which is a flag that we can name it as we like; to
# indicate the end of a string.
cat << EOS

Summary:
    > We have total of ${#all_repos[@]} Repos: ${#public_repos[@]} \
are Public, and ${#private_repos[@]} are Private.
    > Repos to commit = ${#repos_to_commit[@]}
    > Repos to push = ${#repos_to_push[@]}
    > Repos to pull = ${#repos_to_pull[@]}
    > Repos with no commits yet = ${#repos_no_commits_yet[@]}
    > Clean Repos = ${#clean_repos[@]}
EOS

# Check if number of repos to commit is larger than zero; then print theses
# repos paths.
if [ ${#repos_to_commit[@]} -gt 0 ]; then
    cat << EOS

Repos to commit:
$(for repo in ${repos_to_commit[@]}
do  
    printf "    > "
    echo $repo
done)
EOS
fi

# Check if number of repos to push is larger than zero; then print theses
# repos paths.
if [ ${#repos_to_push[@]} -gt 0 ]; then
    cat << EOS

Repos to push:
$(for repo in ${repos_to_pull[@]}
do  
    printf "    > "
    echo $repo
done)
EOS
fi

# Check if number of repos to pull is larger than zero; then print theses
# repos paths.
if [ ${#repos_to_pull[@]} -gt 0 ]; then
    cat << EOS

Repos to pull:
$(for repo in ${repos_to_push[@]}
do  
    printf "    > "
    echo $repo
done)
EOS
fi

# Check if number of repos to push is larger than zero; then print theses
# repos paths.
if [ ${#repos_no_commits_yet[@]} -gt 0 ]; then
    cat << EOS

Repos with no commits yet:
$(for repo in ${repos_no_commits_yet[@]}
do  
    printf "    > "
    echo $repo
done)
EOS
fi