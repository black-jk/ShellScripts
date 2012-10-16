#!/bin/bash
  config_path="${BASH_SOURCE[0]%/*}/includes/config.sh"
  [ ! -e "${config_path}" ] && echo "Missing ${config_path}!" && exit 1
  read_params=("action")
  source "${config_path}"
  
  ### ====================================================================================================
  
  function _check {
    if [ "${#params[@]}" -ge "1" ]; then
      for arg in ${params[@]// /%space%}
      do
        file="${arg//%space%/ }"
        [ -d "${file}" ] && continue;
        
        echo "[${file}]"
        ${grep} -Ev '^\-|\/dev\/null' "${file}" | ${grep} -E '^\+\+\+|\( | \)|if\(|\){|(for|each|while)\(|}(else|catch)|else{'
      done
    else
      ${grep} -Ev '^\-|\/dev\/null' ${STDIN} | ${grep} -E '^\+\+\+|\( | \)|if\(|\){|(for|each|while)\(|}(else|catch)|else{'
    fi
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function _fix {
    echo
    
    for arg in ${params[@]// /%space%}
    do
      file="${arg//%space%/ }"
      echo "[Fixed] ${file}"
      [ -d "${file}" ] && continue;
      
      sed -ri 's/if\( ?/if \(/g;   s/ ?\)\{/) {/g;   s/(for|each|while|switch)\( ?/\1 \(/g;   s/\}(else|catch)/\} \1/g; s/else\{/else {/g;       s/\( +/\(/g; s/ +\)/\)/g;' "${file}"
    done
    echo "[Done]"
    echo
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function _help {
    echo
    echo 'Usage:'
    echo '  .git/scripts/format.sh check [FILE...]'
    echo '  .git/scripts/format.sh fix FILE...'
    echo '  '
    echo
  }
  
  ### ====================================================================================================
  
  case "${action}" in
    
    "c" | "check")
      _check
    ;;
    
    ### --------------------------------------------------
    
    "f" | "fix")
      _fix
    ;;
      
    ### --------------------------------------------------
    
    "" | "help")
      _help
    ;;
    
    *)
      echo -e "\nUnknown action: ${action}"
      _help
    ;;
    
  esac
