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
    if [ "${use_svn}" ]; then
      [ "${use_git_svn}" ] && git_svn_st || svn_st -u
      echo
    fi
    git_st
    echo
    git_log
    echo
    echo "================================================== [Git] =================================================="
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function _svn_update {
    [ ! "${use_svn}" ] && echo -e "\n\e[1;31mSVN NOT SUPPORT!?\e[0m\n" && exit 1
    [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\n\nCommit git before rebase!\n\e[0m" && exit 1
    
    log_name="svn_update.log"
    
    svn_branch="${svn_branch:-master}"
    check_branch "${svn_branch}" "quit"
    
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
  
  function _git_svn_update {
    [ ! "${use_svn}" ] && echo -e "\n\e[1;31mSVN NOT SUPPORT!?\e[0m\n" && exit 1
    [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\n\nCommit git before rebase!\n\e[0m" && exit 1
    
    log_name="git_svn_update.log"
    
    
    ### switch to svn branch
    svn_branch="${svn_branch:-master}"
    check_branch "${svn_branch}" "quit"
    
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
    
    git svn rebase
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  function _git_rebase {
    [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\n\nCommit git before rebase!\n\e[0m" && exit 1
    
    log_name="git_rebase.log"
    
    ALL_BRANCHES="${all:-""}"
    if [ "${ALL_BRANCHES}" ]; then
      ### make branches list
      branches_tmp="${tmp_root}/branches.tmp"
      prev_branches_tmp="${tmp_root}/branches.tmp.prev"
      if [ "${prev:-""}" ] && [ -e "${prev_branches_tmp}" ]; then
        cp "${prev_branches_tmp}" "${branches_tmp}"
      else
        echo -e "# Format: branche[:master]\n" > "${branches_tmp}"
        git checkout master && git branch --no-color | ${grep} -v '\*' | ${grep} -Ev '^[ \t]*(develop|release|.*\.debug)[ \t]*$' | awk '{print $1}' >> "${branches_tmp}"
        [ "${keep_branch}" ] && echo -e "\n# --------------------------------------------------\n\n${current_branch}"  >> "${branches_tmp}"
      fi
      
      if [ ! "${rebase_all_branch_without_ask}" ]; then
        ${joe} "${branches_tmp}"
        
        [ -e "${prev_branches_tmp}.bak2" ] && cp "${prev_branches_tmp}.bak2" "${prev_branches_tmp}.bak3"
        [ -e "${prev_branches_tmp}.bak1" ] && cp "${prev_branches_tmp}.bak1" "${prev_branches_tmp}.bak2"
        [ -e "${prev_branches_tmp}"      ] && cp "${prev_branches_tmp}"      "${prev_branches_tmp}.bak1"
        cp "${branches_tmp}"           "${prev_branches_tmp}"
      fi
      
      ${grep} -vE '^(#.*|[ \t]*)$' "${branches_tmp}" | sed 's/ //g' > "${branches_tmp}.tmp"
      rm "${branches_tmp}"
      
      if [ "`check_branch "develop" && echo 1`" ]; then
        echo "develop:master" >> "${branches_tmp}"
        base_branch="develop"
      else
        base_branch="master"
      fi
      if [ "`check_branch "release" && echo 1`" ]; then
        echo "release:${base_branch}" >> "${branches_tmp}"
      fi
      
      cat "${branches_tmp}.tmp" >> "${branches_tmp}"
      
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
      
      if [ "`check_branch "develop" && echo 1`" ]; then
        default_target_branch="develop"
      else
        default_target_branch="master"
      fi
      
      if [ "${ALL_BRANCHES}" ]; then
        
        if [ "`awk 'END {print NR}' "${branches_tmp}"`" == "0" ]; then
          break
        fi
        
        branch=`head -1 "${branches_tmp}"`
        sed -i '1d' "${branches_tmp}"
        
        ### keep on last branch
        if [ "${keep_branch}" ]; then
          if [ "`awk 'END {print NR}' "${branches_tmp}"`" == "0" ]; then
            git checkout "${branch}"
            break
          fi
        fi
        
        ### specified target branch
        echo "${branch}" | ${grep} -Eq ':' && bool="1" || bool=""
        if [ "${bool}" == "1" ]; then
          target="${branch##*:}"
          branch="${branch%%:*}"
        else
          target="${default_target_branch}"
        fi
        
        ### debug branch
        if [ "${target}" == "${default_target_branch}" ]; then
          debug_branch="${branch}.debug"
          if [ "`check_branch "${debug_branch}" && echo 1`" ]; then
            sed -i 1i"${branch}:${debug_branch}" "${branches_tmp}"
            branch="${debug_branch}"
            #index=$(($index - 1))
            branches_count=$(($branches_count + 1))
          fi
        fi
        
        echo "[branch: ${branch}] [target: ${target}]"
        
      else
        branch="${params[0]:-""}"
        target="${params[1]:-"$default_target_branch"}"
      fi
      
      ### --------------------------------------------------
      
      index=$(($index + 1))
      
      if [ "`check_branch "${branch}" "warn" || echo 1`" ] || [ "`check_branch "${target}" "warn" || echo 1`" ]; then
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
        git_sb "${target}" "${branch}"
        [ "${use_svn}" ] && [ ! "${use_git_svn}" ] && git checkout master && \
        [ "`svn_has_changes`" != "0" ] && echo -e "\n\e[1;31m`svn_st`\e[0m"
        [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31m`git_st`\e[0m"
        
        onto="${onto:-""}"
        if [ "${onto}" ] && [ "${target}" == "develop" ]; then
          if [ "`check_branch "${onto}" && echo 1`" ] || [ "`check_object "${onto}:${branch}" && echo 1`" ]; then
            cmd="git rebase --onto \"${target}\" \"${onto}\" \"${branch}\""
          else
            echo -e "\e[1;31mCheck object '${onto}' fail! Skip rebase '${branch}'.\e[0m"
            break_while=""
            break
          fi
        else
          cmd="git rebase \"${target}\" \"${branch}\""
        fi
        
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
          if [ "${onto}" ] && [ "${target}" == "develop" ]; then
            git rebase --onto "${target}" "${onto}" "${branch}"
          else
            git rebase "${target}" "${branch}"
          fi
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
    
    [ ! "${keep_branch}" ] && git checkout master
    
    if [ "${ALL_BRANCHES}" ]; then
      echo
      git_sb
      echo
      echo "All done."
    fi
    
    echo
  }
  
  ### ----------------------------------------------------------------------------------------------------
  
  ARCHIVE_REMOTE_NAME="archive"
  
  function _git_archive {
    [ "${ARCHIVE_REMOTE_NAME}" == "" ] && echo -e "\n\e[1;31mSet \$ARCHIVE_REMOTE_NAME first!\n\e[0m" && exit 1
    git remote | ${grep} -q "^${ARCHIVE_REMOTE_NAME}\$" || { echo -e "\n\e[1;31mRemote ${ARCHIVE_REMOTE_NAME} not exist!\n\e[0m" && exit 1; }
    
    from_branch="${1}"
    to_branch="${2}"
    force="${3}"
    remove="${4}"
    
    [ "${from_branch}" == "" ] && echo -e "\n\e[1;31mMissing \$from_branch!\n\e[0m" && exit 1
    [ "${to_branch}" == "" ]   && echo -e "\n\e[1;31mMissing \$to_branch!\n\e[0m" && exit 1
    check_branch "${from_branch}" "quit"
    
    push_option=""
    [ "${force}" == "1" ] && push_option="${push_option} -f"
    
    ### 1. push to archive
    git push archive ${push_option} "${from_branch}:${to_branch}" || exit 1
    
    ### 2. remove local branch
    if [ "${remove}" == "1" ]; then
      if [ "`git_current_branch`" == "${from_branch}" ]; then
        git checkout master
      fi
      git branch -D "${from_branch}"
    fi
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
    echo '  .git/scripts/git.sh git-archive <local-branch> [<remote-branch>] [-force] [-remove]'
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
    echo '      -prev           User previous branches list'
    echo '      '
    echo '      --onto $object  Use rebase --onto'
    echo '      '
    echo '    git-archive | git-ar:'
    echo '      '
    echo '      <local-branch>  The local branch you want to archive'
    echo '      '
    echo '      <remote-branch> The remote branch name (default = <local-branch>)'
    echo '      '
    echo '      -f | -force     Use `git push -f` for archive'
    echo '      '
    echo '      -r | -remove    Remove <local-branch> after archived'
    echo '      '
    echo
  }
  
  
  
  ### ====================================================================================================
  ### [Main]
  ### ====================================================================================================
  
  #[ "$(git config local.svn)"     == "true" ] && use_svn="1"     || use_svn=""
  #[ "$(git config local.git-svn)" == "true" ] && use_git_svn="1" || use_git_svn=""
  use_svn="$(     [ "$(git config local.svn)"     == "true" ] && printf 1)"
  use_git_svn="$( [ "$(git config local.git-svn)" == "true" ] && printf 1)"
  
  keep_branch="${k:-""}"
  if [ "${keep_branch}" ]; then
    current_branch="`git_current_branch`"
  else
    current_branch=""
  fi
  
  case "${action}" in
    
    "st" | "status")
      [ "${l-:""}" ] && clear
      _status
    ;;
    
    ### --------------------------------------------------
    
    "sync")
      action=""
      while [ "${action-""}" == "" ]
      do
        echo
        
        if [ "${use_svn}" ]; then
          [ "${use_git_svn}" ] && \
            cmd="git svn rebase" || \
            cmd="${0} svn-update up"
        else
          check_remote "origin" && \
          cmd="git pull origin --rebase"
        fi
        
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
      
      if [ "${use_svn}" ]; then
        [ "${use_git_svn}" ] && \
        _git_svn_update || ( \
          params[0]="up"
          _svn_update
        )
      else
        check_remote "origin" && \
        git co master && git pull --rebase origin master
      fi
      
      ### ------------------------------
      
      rebase_all_branch_without_ask=""
      
      [ ! "${keep_branch}" ] && action="" || action="Y"
      while [ "${action-""}" == "" ]
      do
        echo
        cmd="${0} git-rebase -all"
        read -n 1 -p "${cmd} ? (Y/n/A): " action
        echo
        
        if [ "${action:-"y"}" == "y" -o "${action}" == "Y" ]; then
          break
        elif [ "${action}" == "A" ]; then
          rebase_all_branch_without_ask="1"
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
    
    "git-ar" | "git-archive")
      [ "`git_has_changes`" != "0" ] && echo -e "\n\e[1;31mCommit git before ${action}!\n\e[0m" && exit 1
      
      from_branch="${params[0]}"
      to_branch="${params[1]:-$from_branch}"
      _git_archive "${from_branch}" "${to_branch}" "${force:-$f}" "${remove:-$r}"
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
