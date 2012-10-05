#!/bin/bash
  
  ### ./example.sh --var1 111 --var2 "2 2 2" -flag1 opt1 opt2 opt3 aa bb cc "d d d"
  
  echo "--------------------------------------------------"
  
  #->echo "example.sh: ${BASH_SOURCE%/*} (${BASH_SOURCE}:${LINENO})"
  config_path="${BASH_SOURCE%/*}/includes/config.sh"
  [ ! -e "${config_path}" ] && echo "Missing ${config_path}!" && exit 1
  read_params=("option1" "option2" "option3")
  source "${config_path}"
  
  echo "--------------------------------------------------"
  
  echo "option1: '${option1}'"
  echo "option2: '${option2}'"
  echo "option3: '${option3}'"
  echo "flag1:   '${flag1:-0}'"
  echo "flag2:   '${flag2:-0}'"
  echo "var1:    '${var1}'"
  echo "var2:    '${var2}'"
  for param in ${params[@]// /%space%}
  do
    echo "param: '${param//%space%/ }'"
  done
  
  echo "--------------------------------------------------"
  echo
  
  ### ----------------------------------------------------------------------------------------------------
  
  prompt="`echo -e "\n====================\nMake choice\n====================\nYes or No"`"
  
  yes_or_no "`ls -l; echo -e "\nNext line...\n"`${prompt}" && echo -e "\nYES\n" || echo -e "\nNO\n"
  
  bash_variable=null
  yes_or_no "`ls -l`${prompt}" && {
    echo -e "\nYES\n"
    bash_variable=yes
  } || {
    echo -e "\nNO\n"
    bash_variable=no
  }
  echo -e "bash_variable: ${bash_variable}\n\n"
  
  ### ----------------------------------------------------------------------------------------------------
  