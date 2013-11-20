#!/bin/bash
  config_path="./.git/scripts/includes/config.sh" #"${BASH_SOURCE%/*}/includes/config.sh"
  [ ! -e "${config_path}" ] && echo "Missing ${config_path}!" && exit 1
  read_params=("action")
  source "${config_path}"
  
  ### // ====================================================================================================
  
  [ "$(git config local.svn)" == "true" ] && use_svn="1" || use_svn=""
  [ "$(git config local.git-svn)" == "true" ] && use_git_svn="1" || use_git_svn=""
  
  if [ ! "${f:-""}" ] && [ ! "${force:-""}" ]; then
    if [ "${use_svn}" ] && [ ! "${use_git_svn}" ] && [ "`svn_has_changes`" != "0" ]; then
      quit "Commit svn changes before this!" "${QUIT_ERROR}"
      exit 1
    fi
    if [ "`git_has_changes`" != "0" ]; then
      quit "Commit git changes before this!" "${QUIT_ERROR}"
      exit 1
    fi
  fi
  
  if [ "${R:-""}" != "1" ]; then
    for file in `(cd EditorComponentsDev/src && find . \( -name '*.as' -o -name '*.mxml' \) | sed 's/^\.\///g')`
    do
      cp -v "EditorComponents/${file}" "EditorComponentsDev/src/${file}"
    done
  else
    for file in `(cd EditorComponentsDev/src && find . \( -name '*.as' -o -name '*.mxml' \) | sed 's/^\.\///g')`
    do
      cp -v "EditorComponentsDev/src/${file}" "EditorComponents/${file}"
    done
  fi
  echo
  
  echo -e "\033[1m`git_st`\033[0m\n"
