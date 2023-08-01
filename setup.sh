#!/usr/bin/env bash

# Run this file to create symlinks to "install" the program.
# To "uninstall" the program i.e. remove all symlinks created, 
# bys the script, run unlink.sh

# https://stackoverflow.com/a/246128/10967630
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# https://stackoverflow.com/a/192337/10967630
SCRIPT_NAME=$(basename "$0")

FORCE=0

# https://www.howtogeek.com/778410/how-to-use-getopts-to-parse-linux-shell-script-options/
# https://www.geeksforgeeks.org/getopts-command-in-linux-with-examples/
while getopts ":f" flag; do
  if [[ "$flag" == "f" ]]; then
    FORCE=1
    echo "Deleting existing directories"
    echo
  fi
done

echo

if [[ -d $SCRIPT_DIR ]]
then
  echo "cd to install location..."
  pushd $SCRIPT_DIR >> /dev/null
else
  echo "Install / script location not found / invalid: $SCRIPT_DIR. Exiting."
  popd
  exit
fi

doLink() {
  link="$1"
  dirName="$2"
  linkParent=$(dirname "$link")
  
  if [[ $FORCE == 1 ]]; then
    if [[ -f $link ]]; then
      echo "❗🗑️ Deleting existing file \"$link\""
      rm -f "$link"
    elif [[ -d $link ]]; then
      echo "❗🗑️ Deleting existing directory \"$link\""
      rm -rf "$link"
    elif [[ -e $link ]]; then
      echo "❗🗑️ Deleting \"$link\""
      rm -rf "$link"
    fi
  fi

  if [[ ! -e $linkParent ]]; then
    echo "📂📂 Creating link parent directory \"$linkParent\""
    mkdir -p "$linkParent"
  fi

  if [[ ! -e $link ]]; then
    echo "✅✅ Linking \"$dirName\" to \"$link\""
    ln -s "${SCRIPT_DIR}/${dirName}" "$link"
  else
    echo "⚠️⚠️ Exists: \"$link\", skipping..."
  fi
}

# Array basics: https://siytek.com/bash-arrays/
declare -A CustomDirs

CUSTOM_LIST="custom_list"

# First we link the custom locations,
# store them in an array,
# then link the rest directories directly under home.
if [[ -e $CUSTOM_LIST ]]
then
  echo
  echo "Reading custom list"
  echo

  # Read a file: https://linuxhint.com/read_file_line_by_line_bash/
  while read line; do

    # Check blank line: https://stackoverflow.com/a/37398168/10967630
    if [[ $line == "#"* || -z "${line// /}" ]]
    then
      # Bash break / continue: https://linuxize.com/post/bash-break-continue/
      continue
    fi
    
    # Split string: https://stackoverflow.com/a/5257398/10967630
    IFS=':'; lineArr=($line); unset IFS;
    dirName="$(eval echo ${lineArr[0]})"
    link="$(eval echo ${lineArr[1]})"
    CustomDirs[$dirName]="$link"
    
    if [[ $link == "IGNORE" ]]
    then
      echo "Ignoring linking \"$dirName\""
      continue
    fi
    
    doLink "$link" "$dirName"

  done < $CUSTOM_LIST

else
  echo "No custom list found"
fi

# Link the rest directly under home
echo
echo "Linking other directories"
echo

# Loop over output: https://stackoverflow.com/a/35927896/10967630
while read -r line ; do
  dirName=${line}
  link=${HOME}/${line}

  # Link only directories which are not linked above
  if [[ -z "${CustomDirs[$dirName]}" && $dirName != $SCRIPT_NAME && $dirName != $CUSTOM_LIST  && $dirName != "unlink.sh" ]]
  then
    doLink "$link" "$dirName"
  fi
done <<< $(ls -A -1)

popd >> /dev/null
