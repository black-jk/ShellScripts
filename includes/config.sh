#!/bin/bash
  
  ### ====================================================================================================
  ### [Path]
  ### ====================================================================================================
  
  ### http://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
  
  src_root="${PWD}/"
  #->echo "includes/config.sh: ${BASH_SOURCE%/*/config.sh} (${BASH_SOURCE}:${LINENO})"
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
      cat /dev/stdin | tee -a "${log_file}"
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
  ### [Extend Functions]
  ### ====================================================================================================
  
