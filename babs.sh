#!/bin/bash

#
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
#
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.
#

# user configuration menu functionality
source binfo/user_config.sh

# allow enable doing some user specific extra actions before the build start
# source ./envsetup_pre.sh

source build/system_utils.sh
source build/build_handler.sh
source build/config.sh
source build/git_utils.sh
source build/repo_management.sh
source build/binfo_operations.sh

func_repolist_binfo_list_print #From repo_management.sh

func_repolist_find_app_index_by_app_name #From repo_management.sh

func_user_help_print() {
    func_build_system_name_and_version_print #Fron config.sh
    echo "babs (babs ain't patch build system)"
    echo "usage:"
    echo "-c or --configure        Select AMD GPU's for which the machine learning library support and optimization is builded."
    echo "                         Note that each selected GPU will increase the build time."
    echo "-b or --build:           Start or continue the building of rocm_sdk core applications."
    echo "                         If source directory does not yet exist, it will first checkout source code and apply patches."
    echo "                         Build files are located under 'builddir' directory and install is done to"
    echo "                         '/opt/rocm_sdk_version' directory."
    echo "                         Optional parameter can be given to build additional libraries and applications after core build:"
    echo "                              binfo/extra/my_apps_list.blist or binfo/extra/my_app.binfo"
    echo "-i or --init:            Download git repositories listed in binfo directory to 'src_projects' directory"
    echo "                         and apply all patches from 'patches' directory."
    echo "                         Optional parameter: binfo/extra/mytoollist.blist or binfo/extra/myapp.binfo"
    echo "-ca or --checkout_apply: Checkout source code repositories to versions listed in binfo files for each git repository"
    echo "                         in src_projects directory and apply patches on top of the checked out source code versions."
    echo "                         Optional parameter: binfo/extra/my_apps_list.blist or binfo/extra/my_app.binfo"
    echo "-ap or --apply_patches:  Scan 'patches/rocm-version' directory and apply each patch"
    echo "                         on top of the repositories in 'src_projects' directory."
    echo "                         Optional parameter: binfo/extra/my_apps_list.blist or binfo/extra/my_app.binfo"
    echo "-co or --checkout:       Checkout source code repositories to versions listed in binfo files for each git repository."
    echo "                         Apply of patches of top of the checked out version needs to be performed separately"
    echo "                         with '-ap' command."
    echo "                         Optional parameter: binfo/extra/my_apps_list.blist or binfo/extra/my_app.binfo"
    echo "--clean:                 Clean directories which has been used to build core or extra repositories that are listed"
    echo "                         in binfo files. Cleaned directories are located under 'builddir' directory."
    echo "                         This will cause these repositories to be rebuild on next build attempt."
    echo "                         Optional parameter: binfo/extra/mytoollist.blist or binfo/extra/myapp.binfo"
    echo "-f or --fetch:           Fetch latest source code for each git repository listed in binfo files."
    echo "                         Checkout of fetched source code to versioins specified in binfo files needs to be performed"
    echo "                         separately with '-ca' or '-co' command."
    echo "                         Optional parameter: binfo/extra/my_apps_list.blist or binfo/extra/my_app.binfo"
    echo "-up or --update:         Update ROCM SDK Builder source code to latest version in current git branch and then check"
    echo "                         which projects has updated binfo file or patches directory. Then do the do the checkout_apply"
    echo "                         and clean commands for the updated projects so that they can be rebuild easily."
    echo "                         Optional parameter: binfo/extra/mytoollist.blist or binfo/extra/myapp.binfo"
    echo "-h or --help:            Show this help"
    echo "-v or --version:         Show babs build system version information"
    #echo "-cp or --create_patches: generate patches by checking git diff for each repository"
    #echo "-g or --generate_repo_list: generates repo_list_new.txt file containing current repository revision hash for each project"
    #echo "-s or --sync: checkout all repositories to base git hash"
    echo ""
    if [ ! -d src_projects ]; then
        echo ""
        echo "----------------Advice ---------------"
        echo "No ROCm project source codes detected in 'src_projects 'directory."
        echo "I recommend downloading them first with command './babs.sh -i'"
        echo ""
        echo "Projects will be loaded to 'src_projects' directory"
        echo "and will require about 20gb of space."
        echo "If download of some projects fails, you can issue './babs.sh -i' command again"
        echo "--------------------------------------"
        echo ""
    else
        if [ ! -d builddir ]; then
            echo ""
            echo "----------------Advice ---------------"
            echo "No ROCm 'builddir' directory detected."
            echo "Once projects source code has been downloaded with './babs.sh -i' command"
            echo "you can start building with command './babs.sh -b'"
            echo "--------------------------------------"
            echo ""
        fi
    fi
    exit 0
}

func_handle_user_configure_help_and_version_args() {
    for arg in "${LIST_USER_CMD_ARGS[@]}"; do
        case $arg in
        -c | --configure)
            func_build_cfg_user
            exit 0
            ;;
        -h | --help)
            func_user_help_print
            exit 0
            ;;
        -v | --version)
            func_build_system_name_and_version_print #from config.sh
            exit 0
            ;;
        esac
    done
}

func_handle_user_command_args() {
    local ii=0
    local res
    local ARG__USER_CMD
    local ARG__USER_CMD_PARAM1

    while [[ -n "${LIST_USER_CMD_ARGS[ii]}" ]]; do
        unset ARG__USER_CMD_PARAM1
        ARG__USER_CMD=${LIST_USER_CMD_ARGS[ii]}
        if [[ ${ARG__USER_CMD:0:1} == '-' ]]; then
            echo "ARG__USER_CMD: ${ARG__USER_CMD}"
            if [ -n "${LIST_USER_CMD_ARGS[ii + 1]}" ]; then
                ARG__USER_CMD_PARAM1=${SDK_ROOT_DIR}/${LIST_USER_CMD_ARGS[ii + 1]}
                if [[ ! ${ARG__USER_CMD_PARAM1:0:1} == '-' ]]; then
                    # should be a valid parameter for command
                    ((ii++))
                    echo "ARG__USER_CMD_PARAM1: ${ARG__USER_CMD_PARAM1}"
                else
                    # another command starting with "-"-character
                    unset ARG__USER_CMD_PARAM1
                    echo "ARG__USER_CMD_PARAM1 not provided for ${ARG__USER_CMD}"
                fi
            fi
            case "${ARG__USER_CMD}" in
            -ap | --apply_patches)
                func_is_git_configured
                func_babs_handle_apply_patches ${ARG__USER_CMD_PARAM1} #From babs_handler.sh
                exit 0
                ;;
            -b | --build)
                echo "build"
                func_babs_handle_build ${ARG__USER_CMD_PARAM1} #From babs_handler.sh
                exit 0
                ;;
            --clean)
                func_babs_handle_build_direcory_clean ${ARG__USER_CMD_PARAM1} #From repo_management.sh
                exit 0
                ;;
            -cp | --create_patches)
                # deprected and not officially supported functionality at the moment.
                func_repolist_appliad_patches_save #From repo_management.sh
                exit 0
                ;;
            -co | --checkout)
                func_babs_handle_checkout ${ARG__USER_CMD_PARAM1} #From babs_handler.sh
                exit 0
                ;;
            -ca | --checkout_apply)
                # Combined checkout and apply patches
                func_is_git_configured
                func_babs_handle_checkout_and_apply_patches ${ARG__USER_CMD_PARAM1} #From babs_handler.sh
                exit 0
                ;;
            -up | --update)
                func_babs_handle_update ${ARG__USER_CMD_PARAM1} #From babs_handler.sh
                exit 0
                ;;
            -f | --fetch)
                func_babs_handle_repository_fetch ${ARG__USER_CMD_PARAM1} #From babs_handler.sh
                exit 0
                ;;
            -fs | --fetch_submod)
                # deprected and not officially supported functionality at the moment. fetch, ca, co methods should now do these steps automatically in the end.
                if [[ -n "${ARG__USER_CMD_PARAM1}" ]]; then
                    func_babs_fetch_submodules_by_binfo ${ARG__USER_CMD_PARAM1} #From binfo_operations.sh
                else
                    func_repolist_fetch_submodules #From repo_management.sh
                fi
                exit 0
                ;;
            -g | --generate_repo_list)
                # deprected and not officially supported functionality at the moment.
                func_repolist_export_version_tags_to_file #From repo_management.sh
                exit 0
                ;;
            -i | --init)
                func_is_git_configured
                func_babs_handle_repository_init ${ARG__USER_CMD_PARAM1} #From binfo_operations.sh
                exit 0
                ;;
            -s | --sync)
                # deprected and not officially supported functionality at the moment.
                func_repolist_checkout_by_version_tag_file
                exit 0
                ;;
            *)
                echo "Unknown user command parameter: ${LIST_USER_CMD_ARGS[ii]}"
                exit 0
                ;;
            esac
        fi
        ((ii++))
    done
}

if [ "$#" -eq 0 ]; then
    func_user_help_print
else
    LIST_USER_CMD_ARGS=("$@")
    # Initialize build version
    func_build_version_init #From config.sh
    # Handle help and version commands before prompting the user config menu
    func_handle_user_configure_help_and_version_args
    # Initialize environment setup
    func_envsetup_init #From config.sh
    # Handle user command arguments
    func_handle_user_command_args
fi
