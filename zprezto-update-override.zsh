# Overrides the zprezto-update function in init.zsh
function zprezto-update {
  (
    function cannot-fast-forward {
      [[ -n "$1" ]] && printf "\n$1"
      printf "\nCannot fast-forward the changes."
      printf "\nAborting.\n\n"
    }

    # Go to your prezto directory.
    cd -q -- "${ZPREZTODIR}" || return 7

    if git checkout master; then
      # Check 'upstream/master' for updates.
      git fetch upstream master || return "$?"

      # LOCAL:    Latest commit hash on 'master'.
      # UPSTREAM: Latest commit hash on 'upstream/master'.
      # BASE:     Hash of the commit at which 'master' and 'upstream/master'
      #           diverge.
      local LOCAL=$(git rev-parse master)
      local UPSTREAM=$(git rev-parse upstream/master)
      local BASE=$(git merge-base master upstream/master)

      if [[ $LOCAL == $UPSTREAM ]]; then
        # 'master' and 'upstream/master' are even.
        printf "\nThere are no updates.\n\n"
        git checkout custom
        return 0
      elif [[ $LOCAL == $BASE ]]; then
        # 'upstream/master' is ahead of 'master'. Need to pull updates.

        # Update 'master' by merging in changes from 'upstream/master' using a
        # fast-forward merge. This should always succeed since you should only
        # commit changes to 'custom', not 'master'. Still, checks will prevent
        # updates being applied if you have accidentally committed changes to
        # 'master'.
        printf "\nAttempting to update.\n\n"
        if git merge upstream/master --ff-only; then
          printf "\nUpdating submodules.\n\n"
          git submodule update --recursive
          # Push changes to 'origin/master' (fork).
          git push

          # Update 'custom' by rebasing it to the tip of 'master'.
          git checkout custom
          git rebase master
          # Push changes to 'origin/custom' (fork).
          git push -f
          return $?
        else
          cannot-fast-forward
          git checkout custom
          return 1
        fi
      elif [[ $UPSTREAM == $BASE ]]; then
        # 'master' is ahead of 'upstream/master' (wont occur unless you have
        # accidentally committed changes to 'master'.
        cannot-fast-forward "'master' is ahead of 'upstream/master'."
        git checkout custom
        return 1
      else
        # 'master' and 'upstream/master' have diverged (wont occur unless you
        # have accidentally committed changes to 'master'.
        cannot-fast-forward "'master' and 'upstream/master' have diverged."
        git checkout custom
        return 1
      fi
    else
      printf "\nUnable to checkout master branch.\n\n"
      return 1
    fi
  )
}
