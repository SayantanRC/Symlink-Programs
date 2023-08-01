#!/usr/bin/env bash

# Run this script to remove all the symlinks created by setup.sh.

# https://stackoverflow.com/a/246128/10967630
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# https://stackoverflow.com/a/192337/10967630
SCRIPT_NAME=$(basename "$0")

echo

if [[ -d $SCRIPT_DIR ]]
then
  echo "cd to install location..."
  pushd $SCRIPT_DIR >> /dev/null
else
  echo "Install / script location not found / invalid: $SCRIPT_DIR. Exiting."
  exit
fi

doUnlink() {
  link="$1"
  dirName="$2"
  
  if [[ ! -e $link ]]; then
    echo "⚠️⚠️ Does not exist: $link"
  elif [[ $(readlink -f "${link}") == "${SCRIPT_DIR}/${dirName}" ]]; then
    echo "✅✅ Removing link: \"$link\""
    rm "${link}"
  else
    echo "❗❗❗ Not removed, file related to something else: $link"
  fi
}

# Array basics: https://siytek.com/bash-arrays/
declare -A CustomDirs

CUSTOM_LIST="custom_list"

# First we remove links of the custom locations,
# and store them in an array,
# then remove the rest of the directories links under home.

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
    dirName=$(eval echo ${lineArr[0]})
    link="$(eval echo ${lineArr[1]})"
    CustomDirs[$dirName]="$link"
    
    if [[ $link == "IGNORE" ]]
    then
      echo "Ignoring de-linking \"$dirName\""
      continue
    fi

    doUnlink "$link" "$dirName"

  done < $CUSTOM_LIST

else
  echo "No custom list found"
fi

# Remove link of the rest under home
echo
echo "Unlinking other directories"
echo

# Loop over output: https://stackoverflow.com/a/35927896/10967630
while read -r line ; do
  dirName=${line}
  link=${HOME}/${line}

  # Link only directories which are not linked above
  if [[ -z "${CustomDirs[$dirName]}" && $dirName != $SCRIPT_NAME && $dirName != $CUSTOM_LIST  && $dirName != "setup.sh" ]]
  then
    doUnlink "$link" "$dirName"
  fi
done <<< $(ls -A -1)

popd >> /dev/null
