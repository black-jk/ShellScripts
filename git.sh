#!/bin/bash
  #config_path="./.git/scripts/includes/config.sh"
  config_path="${BASH_SOURCE[0]%/*}/includes/config.sh"
  [ ! -e "${config_path}" ] && echo "Missing ${config_path}!" && exit 1
  read_params=("action")
  source "${config_path}"
  
  ### [TODO] http://www.ypwang.info/blog/blog/2012/06/26/bash-completion/
  
  
  
  ### ====================================================================================================
  ### [Actions]
  ### ====================================================================================================
  
  function _status {
    echo "================================================== [Git] =================================================="
    echo
    svn_st -u
    echo
    git_st
    echo
    git_log
    echo
    echo "================================================== [Git] =================================================="
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function _svn_update {
    [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\n\nCommit git before rebase!\n\e[0m" && exit 1
    
    log_name="svn_update.log"
    
    svn_branch="${svn_branch:-master}"
    [ "`check_branch "${svn_branch}"`" == "0" ] && exit 1
    
    while [ "1" ] ###  update to top
    do
      break_while="1"
      
      git branch --no-color | ${grep} '\*' | ${grep} -q "${svn_branch}" && master=1 || master=0
      if [ "${master}" != "1" ]; then
        
        act=""
        while [ "${act-""}" == "" ]
        do
          echo
          git_st
          echo -e "\nNot at \e[1m${svn_branch}\e[0m!"
          read -n 1 -p "Switch to ${svn_branch} ? (Y/n): " act
          echo
          
          if [ "${act:-"y"}" == "y" -o "${act}" == "Y" ]; then
            break
          elif [ "${act}" == "n" -o "${act}" == "N" ]; then
            echo "Canceled!"
            exit 0
          else
            act=""
          fi
        done
        
        git checkout "${svn_branch}"
      fi
      
      ### ----------------------------------------------------------------------------------------------------
      
      echo -en "\nGetting svn informations ... "
      
      svn_current_version=`svn_get_current_revision`
      svn_next_version=$(($svn_current_version + 1))
      svn_top_version=`svn_get_top_revision`
      
      if [ "${svn_current_version}" != "" ] && [ "${svn_top_version}" != "" ]; then
        echo -e "[\e[0;32mOK\e[0m]\n"
      else
        echo -e "[\e[0;31mFAIL\e[0m]\n\n  \e[1;31mCan not do svn-svnupdate!\e[0m\n"
        exit 1
      fi
      
      ### ----------------------------------------------------------------------------------------------------
      
      ### [Backup]
      backup_logs "svn_update.git-log_all.svn_v${svn_current_version}.logs"
      
      ### ----------------------------------------------------------------------------------------------------
      
      revision="${params[0]:-"up"}"
      if [ "${revision}" == "up" ]; then
        if [ "${svn_current_version}" -lt "${svn_top_version}" ]; then
          revision="${svn_next_version}"
        else
          echo "Already updated!"
          revision=""
        fi
      elif [ "${revision}" == "top" ]; then
        if [ "${svn_current_version}" -lt "${svn_top_version}" ]; then
          revision="${svn_top_version}"
        else
          echo "Already updated!"
          revision=""
        fi
      fi
      
      if [ "${revision}" != "" ] && [ "${svn_current_version}" -ge "${svn_top_version}" ]; then
        echo "Already updated!"
        revision=""
      fi
      
      if [ "${revision}" == "" ]; then
        echo
        git_log
        echo
        svn_versions
        echo
        return 0
      fi
      
      ### --------------------------------------------------
      
      ### [Check svn and git status]
      
      if [ "`svn_has_changes`" == "0" ] && [ "`git_has_changes`" == "0" ]; then
        act="y"
      else
        act=""
      fi
      
      while [ "${act-""}" == "" ]
      do
        echo
        svn_st
        echo
        git_st
        echo
        read -n 1 -p "status ok ? (Y/n): " act
        echo
        
        if [ "${act:-"y"}" == "y" -o "${act}" == "Y" ]; then
          break
        elif [ "${act}" == "n" -o "${act}" == "N" ]; then
          echo "Canceled!"
          exit 0
        else
          act=""
        fi
      done
      
      ### --------------------------------------------------
      
      svn_log_msg="[svn:${revision}] svn update (v${revision})"
      
      act=""
      while [ "${act-""}" == "" ]
      do
        echo
        svn_st -u
        echo
        git_log
        echo
        svn_versions
        echo
        
        if [ "${params[0]:-""}" == "up" ] && [ "`svn_has_changes`" == "0" ] && [ "`git_has_changes`" == "0" ]; then
          ### skip ask
          act="y"
          sleep 2
        else
          echo "1. svn update -r ${revision}"
          echo "2. git add ."
          echo "3. git commit -m \"${svn_log_msg}\""
          read -n 1 -p "sure ? (Y/n): " act
          echo
        fi
        
        echo
        
        if [ "${act:-"y"}" == "y" -o "${act}" == "Y" ]; then
          echo "--------------------------------------------------"
          log "svn update -r ${revision}"
          svn update -r ${revision} | log
          echo
          log "git add ."
          git add .
          git status | ${grep} -q 'delete' && git rm `git status | ${grep} 'delete' | awk '{print $3}'`
          git status | log
          echo
          log "git commit -m \"${svn_log_msg}\""
          git commit -m "${svn_log_msg}" | log
          echo
          svn_versions
          echo
          git_st
          echo
          
          if [ "`svn_has_changes`" == "0" ] && [ "`git_has_changes`" == "0" ]; then
            echo -e "\e[1;32m[Done] Sync to revision ${revision} OK!\e[0m"
            if [ "${params[0]:-""}" == "up" ]; then
              if [ "${max:-""}" == "" ] || [ "${revision}" -lt "${max:-""}" ]; then
                break_while=""
              fi
            fi
          else
            #git_log
            echo
            svn_st
            echo
            git_st
            echo
            echo "[Done] (have problem?)"
          fi
          
          break
        elif [ "${act}" == "n" -o "${act}" == "N" ]; then
          echo "Canceled!"
          exit 0
        else
          act=""
        fi
      done
      
      echo
      echo
      
      if [ "${break_while}" == "1" ]; then
        break
      fi
    done ### while [ "1" ]
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function _git_rebase {
    [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\n\nCommit git before rebase!\n\e[0m" && exit 1
    
    log_name="git_rebase.log"
    
    ALL_BRANCHES="${all:-""}"
    if [ "${ALL_BRANCHES}" ]; then
      ### make branches list
      branches_tmp="${tmp_root}/branches.tmp"
      echo -e "# Format: branche[:master]\n" > "${branches_tmp}"
      
      git checkout master && git branch --no-color | ${grep} -v '\*' | awk '{print $1}' >> "${branches_tmp}"
      joe "${branches_tmp}"
      
      ${grep} -vE '^(#.*|[ \t]*)$' "${branches_tmp}" | sed 's/ //g' > "${branches_tmp}.tmp"
      mv "${branches_tmp}.tmp" "${branches_tmp}"
      
      index="0"
      branches_count="`awk 'END {print NR}' "${branches_tmp}"`"
    else
      index="0"
      branches_count="1"
    fi
    
    echo -e "\n\n\n"
    
    ### ----------------------------------------------------------------------------------------------------
    
    break_while=""
    
    while [ "1" ] ###  update to top
    do
      
      if [ "${break_while}" == "1" ]; then
        break
      fi
      
      break_while="1"
      
      ### ----------------------------------------------------------------------------------------------------
      
      ### [Get branch]
      if [ "${ALL_BRANCHES}" ]; then
        
        if [ "`awk 'END {print NR}' "${branches_tmp}"`" == "0" ]; then
          break
        fi
        
        branch=`head -1 "${branches_tmp}"`
        target="master"
        
        echo "${branch}" | ${grep} -Eq ':' && bool="1" || bool=""
        if [ "${bool}" == "1" ]; then
          target="${branch##*:}"
          branch="${branch%%:*}"
        fi
        
        sed -i '1d' "${branches_tmp}"
        
        echo "[branch: ${branch}] [target: ${target}]"
        
      else
        branch="${params[0]:-""}"
        target="${params[1]:-"master"}"
      fi
      
      ### --------------------------------------------------
      
      index=$(($index + 1))
      
      if [ "`check_branch "${branch}"`" == "0" ] || [ "`check_branch "${target}"`" == "0" ]; then
        ### Missing branch
        if [ "${ALL_BRANCHES}" ]; then
          echo "Next ..." && sleep 3
          break_while=""
          continue
        else
          return 0
        fi
      fi
      
      ### ----------------------------------------------------------------------------------------------------
      
      ### [Backup]
      backup_logs "git_rebase_master.${branch}.logs"
      
      action=""
      while [ "${action-""}" == "" ]
      do
        
        ### colors: http://www.hkcode.com/programming/591
        echo -e "====================================================================================================\n" \
                "\n\e[1m[${index} / ${branches_count}] \e[1;32m[${target}] <- [${branch}]\e[0m\n"
        
        ### [Check svn and git status]
        git checkout master
        echo
        git_sb "${target}" "${branch}"
        [ "`svn_has_changes`" != "0" ] && echo -e "\n\e[1;31m`svn_st`\e[0m"
        [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\e[0m"
        
        cmd="git checkout \"${branch}\" && git rebase \"${target}\""
        
        if [ "${i:-""}" == "1" ]; then
          read -n 1 -p "${cmd} ? (Y/n): " action
        else
          action="y"
          echo "# ${cmd}"
          sleep 2
        fi
        
        echo
        
        if [ "${action:-"y"}" == "y" -o "${action}" == "Y" ]; then
          
          log "${cmd}"
          git checkout "${branch}" && \
          git rebase "${target}" && \
          echo | log
          
          log "===================================================================================================="
          
          if [ "${ALL_BRANCHES}" ]; then
            if [ "`git_has_changes`" == "0" ]; then
              echo -e "\e[1;32m[Done] All OK!\e[0m\n\n\n"
            else
              echo -e "\e[1;32m[${target}] <- [${branch}]\e[0m"
              echo -e "\e[1;31mDrop to bash. Finish rebase and exit bash to continue.\e[0m\n"
              bash --login -i
            fi
            break_while=""
          fi
          
          break
        elif [ "${action}" == "n" -o "${action}" == "N" ]; then
          echo "Canceled!"
          continue
        else
          echo
          action=""
        fi
      done
      
      echo
    done ### while [ "1" ]
    
    echo -e "\n====================================================================================================\n"
    
    [ "${k:-""}" != "1" ] && git checkout master
    
    if [ "${ALL_BRANCHES}" ]; then
      echo
      git_sb
      echo
      echo "All done."
    fi
    
    echo
  }
  
  
  
  ### ----------------------------------------------------------------------------------------------------
  ### [Document]
  ### ----------------------------------------------------------------------------------------------------
  
  function _help {
    echo
    echo 'Usage:'
    echo '  .git/scripts/git.sh status'
    echo '  .git/scripts/git.sh sync [SVN|GIT OPTIONS]'
    echo '  .git/scripts/git.sh svn-update <mode> [--svn_branch $branch] [--revision $revision]'
    echo '  .git/scripts/git.sh git-rebase -all [-i] | <branch> <target>'
    echo '  '
    echo '  [SVN OPTIONS]'
    echo '    '
    echo '    svn-update | svn-up:'
    echo '      '
    echo '      <mode>'
    echo '          up    update to top revision (step by revision)(default)'
    echo '         top    update to top revision'
    echo '        $rev    update to revision $rev'
    echo '      '
    echo '      --max $rev             The max revision for svn update'
    echo '      '
    echo '      --svn_branch $branch   The branch for sync to svn. default is master'
    echo '      '
    echo '  [GIT OPTIONS]'
    echo '    '
    echo '    git-rebase | git-rb:'
    echo '      '
    echo '      -all            Rebase all branch by list. (You can edit list before rebase)'
    echo '      '
    echo '      -i              Interactive'
    echo '      '
    echo '      -k              Keep branch after rebase (Or auto switch to master)'
    echo '      '
    echo
  }
  
  
  
  ### ====================================================================================================
  ### [Main]
  ### ====================================================================================================
  
  case "${action}" in
    
    "st" | "status")
      _status
    ;;
    
    ### --------------------------------------------------
    
    "sync")
      action=""
      while [ "${action-""}" == "" ]
      do
        echo
        cmd="${0} svn-update up"
        read -n 1 -p "${cmd} ? (Y/n): " action
        echo
        
        if [ "${action:-"y"}" == "y" -o "${action}" == "Y" ]; then
          break
        elif [ "${action}" == "n" -o "${action}" == "N" ]; then
          echo "Canceled!"
          exit 0
        else
          action=""
        fi
      done
      
      params[0]="up"
      _svn_update
      
      ### ------------------------------
      
      action=""
      while [ "${action-""}" == "" ]
      do
        echo
        cmd="${0} git-rebase -all"
        read -n 1 -p "${cmd} ? (Y/n): " action
        echo
        
        if [ "${action:-"y"}" == "y" -o "${action}" == "Y" ]; then
          break
        elif [ "${action}" == "n" -o "${action}" == "N" ]; then
          echo "Canceled!"
          exit 0
        else
          action=""
        fi
      done
      
      all="1"
      _git_rebase
    ;;
    
    ### --------------------------------------------------
    
    "svn-up" | "svn-update")
      _svn_update
    ;;
    
    ### --------------------------------------------------
    
    "git-rb" | "git-rebase")
      _git_rebase
    ;;
    
    ### --------------------------------------------------
    
    "test")
      [ "`svn_has_changes`" != "0" ] && echo -e "\n\e[1;31m`svn_st`\e[0m" || echo -e "\n\e[1;32m`svn_st`\e[0m"
      [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\e[0m" || echo -e "\n\e[1;32m`git_st`\e[0m"
      echo "svn_get_current_revision: `svn_get_current_revision`"
      echo "svn_get_top_revision: `svn_get_top_revision`"
    ;;
    
    ### ----------------------------------------------------------------------------------------------------
    
    "" | "help")
      _help
    ;;
    
    *)
      echo -e "\nUnknown action: ${action}"
      _help
    ;;
    
  esac
