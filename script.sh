#!/usr/bash 
# The above line so the interpreter knows it is a Bash script and to use
# Bash located in /usr/bash

# Get the current date/time to mark the start of execution
start=`date +%s`

# Declare the paths of the public and private directories with a wildcard
# to list only all directories; as a directory always end with a slash '/'
public_dir="../Public/*/"
private_dir="../Private/*/"

# Create a variable to save our working directory
current_dir=$(pwd)


function list_repos () {
    # A function to echo a list of all git repo paths in a specific path,
    # All returned paths are absolute and match windows format rather than linux
    # format.
    # Arguments: 
    #   $1: a string of a relative or absolute path

    # Loop over all directories in the argument path
    for repo in $1
    do  
        # Check if the current directory is a git repo or not
        if git -C $repo status &>/dev/null; then
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
        fi
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


function check_not_repos (){
    # A function to echo all directories paths that aren't git repos.
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the rdirectoriesepos in the argument array
    for dir in $public_dir $private_dir
    do
        # Check if the current path isn't a git repo
        if ! git -C $dir status &>/dev/null; then
            # Change the current working directory to the current directory
            cd $dir
            # echo the absolute path of the current directory in windows format
            echo $(pwd) | sed 's/./&:/2' | sed 's/.//1'
            # Return back to the working directory
            cd $current_dir
        fi
    done
}


function repos_with_no_remote (){
    # A function to echo all git repos paths that has no remote configured!
    # Arguments: 
    #   $@: an array of git repos paths

    # Loop over all the repos in the argument array
    for repo in $@
    do
        # Check status of the current repo and filter only repos that don't 
        # have a remote configured
        if ! git -C $repo remote -v | grep -q "push"; then
            echo $repo
        fi
    done
}


function print_summary(){
    # Check the length of argument array
    if [ $1 -gt 0 ]; then
        # Print the headline of the list to be printed
        printf "\n$2:\n"
        # Loop over the public array "array_to_print"
        for item in ${array_to_print[@]}
        do  
            # Print the elements of the array
            printf "    > "
            echo $item
        done
    fi
}


# Create an array of all public repos by appending the output of a 
# shell-in-a-shell
declare -a public_repos
public_repos+=($(list_repos "$public_dir"))

# Create an array of all private repos
declare -a private_repos
private_repos+=($(list_repos "$private_dir"))

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

# Check repos that don't have remote configured
repos_with_no_remote+=($(repos_with_no_remote ${all_repos[@]}))

# Check directories that aren't git repos
not_repos+=($(check_not_repos ${all_repos[@]}))

# Echo a summary of all the results:
# EOF: End of string; which is a flag that we can name it as we like; to
# indicate the end of a string.
cat << EOF

Summary:
    > We have total of ${#all_repos[@]} Git repositories: ${#public_repos[@]} \
are Public, and ${#private_repos[@]} are Private.
    > Repos to Commit = ${#repos_to_commit[@]}
    > Repos to Push = ${#repos_to_push[@]}
    > Repos to Pull = ${#repos_to_pull[@]}
    > Repos With no Commits yet = ${#repos_no_commits_yet[@]}
    > Repos with no remote configured = ${#repos_with_no_remote[@]}
    > Not-a-git Directories = ${#not_repos[@]}
    > Clean Repos = ${#clean_repos[@]}
EOF

# Check if number of repos to commit is larger than zero; then print theses
# repos paths.
array_to_print=( "${repos_to_commit[@]}" )
print_summary ${#array_to_print[@]} "Repos to Commit"

# Check if number of repos to push is larger than zero; then print theses
# repos paths.
array_to_print=( "${repos_to_push[@]}" )
print_summary ${#array_to_print[@]} "Repos to Push"

# Check if number of repos to pull is larger than zero; then print theses
# repos paths.
array_to_print=( "${repos_to_pull[@]}" )
print_summary ${#array_to_print[@]} "Repos to Pull"

# Check if number of repos to push is larger than zero; then print theses
# repos paths.
array_to_print=( "${repos_no_commits_yet[@]}" )
print_summary ${#array_to_print[@]} "Repos With no Commits yet"

# Check if number of repos with no remote configured is larger than zero; then 
# print theses repos paths.
array_to_print=( "${repos_with_no_remote[@]}" )
print_summary ${#array_to_print[@]} "Repos With no Remote Configured"

# Check if number of directories that aren't repo is larger than zero; then 
# print theses repos paths.
array_to_print=( "${not_repos[@]}" )
print_summary ${#array_to_print[@]} "Directories That are not Git Repos"

# Get the current date/time to mark the end of execution
end=`date +%s`

# Calculate total execution time in minutes
runtime=$((($end - $start)/60))

# Print total executation time
printf "\n\nTotal Executation Time = $runtime minutes.\n"
