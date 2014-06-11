#!/bin/bash
  
  ### ====================================================================================================
  ### [Path]
  ### ====================================================================================================
  
  ### http://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
  
  src_root="${PWD}/"
  #->echo "includes/config.sh: ${BASH_SOURCE%/*/config.sh} (${BASH_SOURCE[0]}:${LINENO})"
  script_root="${BASH_SOURCE%/*/config.sh}"
  tmp_root="${script_root}/tmp/"
  log_root="${script_root}/logs/"
  
  cd "${src_root}"
  [ ! -d "${tmp_root}" ] && mkdir "${tmp_root}"
  [ ! -d "${log_root}" ] && mkdir "${log_root}"
  
  
  
  ### ====================================================================================================
  ### [ENV]
  ### ====================================================================================================
  
  QUIT_DONE="DONE"
  QUIT_ERROR="ERROR"
  QUIT_CANCEL="CANCEL"
  
  
  
  ### ====================================================================================================
  ### [Alias]
  ### ====================================================================================================
  
  STDIN="/dev/stdin"
  STDOUT="/dev/stdout"
  STDERR="/dev/stderr"
  
  joe="joe"
  grep="grep"
  
  
  
  ### ====================================================================================================
  ### [Parameters]
  ### ====================================================================================================
  
  params_count="${#}"
  
  ### [Array] http://www.rootninja.com/how-to-push-pop-shift-and-unshift-arrays-in-bash/
  
  for arg in ${@// /%space%}
  do
    #->echo "params_src=(\"${params_src[@]}\" \"${arg}\")"
    params_src=("${params_src[@]}" "${arg}")
  done
  #->echo; echo;
  
  params=()
  
  _params_index_=0
  while [ "${_params_index_}" -lt "${params_count}" ];
  do
    param="${params_src[$_params_index_]}"
    #->echo "[$_params_index_] $param"
    head="${param%%[^-]*}"
    
    if [ "${head}" == "-" ]; then
      #->echo "  ${param##-}=1"
      eval "${param##-}=1"
    elif [ "${head}" == "--" ]; then
      #->echo "  ${param##--}='${params_src[$_params_index_+1]//%space%/ }'"
      eval "${param##--}='${params_src[$_params_index_+1]//%space%/ }'"
      _params_index_=$((${_params_index_} + 1))
    else
      if [ "${#read_params[*]}" -gt "0" ]; then
        param_name=${read_params[0]}
        unset read_params[0]
        read_params=("${read_params[@]}")
        #->echo "  ${param_name}='${param//%space%/ }'"
        eval "${param_name}='${param//%space%/ }'"
      else
        #->echo "  params=(\"${params[@]}\" \"${param//%space%/ }\")"
        params=("${params[@]}" "${param//%space%/ }")
      fi
    fi
    
    _params_index_=$((${_params_index_} + 1))
  done
  
  unset _params_index_
  
  
  
  ### ====================================================================================================
  ### [Functions]
  ### ====================================================================================================
  
  log_root="${script_root}/logs"
  
  function log {
    
    log_file="${log_root}/${log_name:-default.log}"
    
    msg="${1:-""}"
    label="${2:-"LOG"}"
    date="`date "+%Y-%m-%d %H:%M:%S"`"
    
    if [ "${msg}" != "" ]; then
      echo "[${date}][${label}] ${msg}" >> "${log_file}"
    else
      title="${3:-""}"
      if [ "${title}" != "" ]; then
        echo "[${date}][${label}] [${title}]" >> "${log_file}"
      fi
      cat ${STDIN} | tee -a "${log_file}"
      echo "----------------------------------------------------------------------------------------------------" >> "${log_file}"
    fi
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function quit {
    msg="${1}"
    type="${2:-ERROR}"
    
    case "${type}" in
      "${QUIT_DONE}")
        color="\e[0;32m"
        code="0"
      ;;
      
      "${QUIT_ERROR}")
        color="\e[0;31m"
        code="1"
      ;;
      
      "${QUIT_CANCEL}")
        color="\e[1;30m"
        code="1"
      ;;
      
      *)
        color="\e[0;31m"
        code="1"
      ;;
    esac
    
    echo -e "${color}${msg}\e[0m"
    exit "${code}"
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function yes_or_no {
    prompt="${1:-"Make choice"}"
    while [ "1" ]
    do
      echo >> /dev/stderr
      read -n 1 -p "${prompt} ? (Y/n): " input
      
      if [ "${input:-"y"}" == "y" ] || [ "${input}" == "Y" ]; then
        return 0
      elif [ "${input}" == "n" -o "${input}" == "N" ]; then
        return 1
      fi
      echo >> /dev/stderr
    done
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function select {
    echo "comming soon..."
  }
  
  
  
  ### ====================================================================================================
  ### [Git Functions]
  ### ====================================================================================================
  
  function backup_logs {
    return
    file="${1:-"git-log_all"}"
    
    [ ! -d ../git_logs/ ] && mkdir ../git_logs/
    
    (
    git log --all --oneline --graph
    echo "--------------------------------------------------"
    git show-branch
    ) > "../git_logs/${file}"
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function git_log {
    echo "[git log]"
    echo "--------------------------------------------------"
    [ "$(git config local.git-svn)" == "true" ] || [ "$(git config local.svn)" != "true" ] && \
    git log --pretty='format:%C(yellow)%h%Creset %C(cyan)%an%Creset %s %Cblue(%cr)%Creset' | head || \
    git log --oneline | head
    echo "--------------------------------------------------"
  }
  
  function git_st {
    echo "[git status]"
    echo "--------------------------------------------------"
    git status | ${grep} -Ev  '^(nothing to commit.*|# ?([ \t]*|On branch.*|Your branch .* have diverged,|and have [0-9]+ and [0-9]+ different commit(s|\(s\))? each, respectively\.))$'
    echo "--------------------------------------------------"
  }
  
  function git_remote_st {
    echo "[git remote status]"
    echo "--------------------------------------------------"
    git fetch origin --prune
    git show-branch master origin/master
    
    if [ "$(git lo master -1 --pretty=%H)" != "$(git lo origin/master -1 --pretty=%H)" ]; then
      echo -e "\n\e[1;31m  Has new revisions!\e[0m"
    fi
    
    echo "--------------------------------------------------"
  }
  
  function git_sb {
    echo "[git show-branch] ${@}"
    echo "--------------------------------------------------"
    git show-branch ${@}
    echo "--------------------------------------------------"
  }
  
  function git_current_branch {
    git branch --no-color | ${grep} '^\*' | awk '{print $2}'
  }
  
  ### --------------------------------------------------
  
  function svn_st {
    echo "[svn status]"
    echo "--------------------------------------------------"
    svn status ${@} | ${grep} -vE '^\.git$|^[ \t]*$' | ${grep} -B 100000 'Status against revision'
    echo "--------------------------------------------------"
  }
  
  function git_svn_st {
    echo "[git-svn status]"
    echo "--------------------------------------------------"
    git svn fetch > /dev/null
    git show-branch master git-svn
    
    if [ "$(git lo master -1 --pretty=%H)" != "$(git lo git-svn -1 --pretty=%H)" ]; then
      echo -e "\n\e[1;31m  Has new revisions!\e[0m"
    fi
    
    echo "--------------------------------------------------"
  }
  
  function svn_versions {
    cur=`svn_get_current_revision`
    top=`svn_get_top_revision`
    
    echo "[SVN Version]"
    echo "--------------------------------------------------"
    echo -n "Current: "
    [ "${cur}" == "${top}" ] \
      && echo "${cur}" \
      || echo "${cur}" | awk '{print $1 "\t(next = " ($1+1) ")"}'
    echo "Top:     ${top}"
    echo "--------------------------------------------------"
  }
  
  ### --------------------------------------------------
  
  function svn_get_current_revision {
    svn info | ${grep} -E -m 1 '(修訂版|Revision): ' | awk '{print $2}'
  }
  
  function svn_get_top_revision {
    svn status -u | ${grep} 'Status against revision' | sed 's/^.*: *//g'
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  ### 1 = Have changes
  ### 0 = ok for update / rebase
  
  function svn_has_changes {
    svn status | ${grep} -B 100000 'Status against revision' | ${grep} -qvE '^(.*\.git)*$' && echo 1 || echo 0
  }
  
  function git_has_changes {
    git status | ${grep} -qEv  '^(nothing to commit.*|# ?([ \t]*|On branch.*|Your branch .* have diverged,|and have [0-9]+ and [0-9]+ different commit(s|\(s\))? each, respectively\.|Your branch is ahead of .* by [0-9]+ commit(s|\(s\))?\.))$' && echo 1 || echo 0
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function check_branch {
    local branch="${1}"
    local when_missing="${2:-""}"
    local remote="${3:-""}"
    
    branch="${branch//^*}"
    branch="${branch//\~*}"
    [ "${branch}" == "" ] && quit "Missing branch name!" "${QUIT_ERROR}"
    
    local branch_params="--no-color"
    if [ "${remote}" == "1" ]; then
      branch_params="${branch_params} -r"
    elif [ "${remote}" == "2" ]; then
      branch_params="${branch_params} -a"
    fi
    
    git branch ${branch_params} | ${grep} -qE "^[\* ] (remotes/)?${branch}"'$' && exist="1" || exist="0"
    
    if [ "${exist}" == "1" ]; then
      return 0
    else
      msg="Branch '${branch}' not exist!"
      if [ "${when_missing}" == "quit" ]; then
        quit "${msg}" "${QUIT_ERROR}"
      elif [ "${when_missing}" == "warn" ]; then
        echo -e "\e[0;31m${msg}\e[0m" > ${STDERR}
      fi
      return 1
    fi
  }
  
  ### --------------------------------------------------
  
  function check_remote {
    remote="${1}"
    when_missing="${2:-""}"
    [ "${remote}" == "" ] && quit echo "Missing remote name!" "${QUIT_ERROR}"
    
    git remote | ${grep} -q "^${remote}\$" && exist="1" || exist="0"
    
    if [ "${exist}" == "1" ]; then
      return 0
    else
      msg="Remote '${remote}' not exist!"
      if [ "${when_missing}" == "quit" ]; then
        quit "${msg}" "${QUIT_ERROR}"
      elif [ "${when_missing}" == "warn" ]; then
        echo -e "\e[0;31m${msg}\e[0m" > ${STDERR}
      fi
      return 1
    fi
  }
  
  ### --------------------------------------------------
  
  function check_object {
    if [ "`echo "${1}" | ${grep} -Eq ':' && echo 1 `" ]; then
      object="${1%%:*}"
      object_parent="${1##*:}"
    else
      object="${1}"
      object_parent="--all"
    fi
    when_missing="${2:-""}"
    [ "${object}" == "" ] && quit echo "Missing object name!" "${QUIT_ERROR}"
    
    git rev-list "${object_parent}" | ${grep} -q "^${object}" && exist="1" || exist="0"
    
    if [ "${exist}" == "1" ]; then
      return 0
    else
      msg="Object '${object}' not exist!"
      if [ "${when_missing}" == "quit" ]; then
        quit "${msg}" "${QUIT_ERROR}"
      elif [ "${when_missing}" == "warn" ]; then
        echo -e "\e[0;31m${msg}\e[0m" > ${STDERR}
      fi
      return 1
    fi
  }
  
  ### ====================================================================================================
  
