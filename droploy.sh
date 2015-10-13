#!/bin/bash
# ~/Dropbox/Public/droploy/.droploy
# [{
# 	project: "save-martian",
# 	source: "~/code/save-martian",
# 	target: "~/Dropbox/Public/droploy/save-martian"
# },
# {
# 	project: "save-martian",
# 	source: "~/Sites/save-martian",
# 	target: "~/Dropbox/Public/droploy/save-martian-1"
# },
# {
# 	project: "save-martian",
# 	source: "~/www/save-martian",
# 	target: "~/Dropbox/Public/droploy/save-martian-2" <-- where '2' is calculated as - count('project:save-martian')
# }]

# ~/code/save-martian $ droploy --> ~/Dropbox/Public/droploy/save-martian
# ~/Sites/save-martian $ droploy --> ~/Dropbox/Public/droploy/save-martian-1
# ~/www/save-martian $ droploy --> ~/Dropbox/Public/droploy/save-martian-2

# check if dropbox is installed
# check if rsync command is available

# create a folder 'droploy' in ~/Dropbox/Public if not exists
# create a new file in the above folder called '.droploy' if not exists
# read .droploy, if project folder path in this file matches with the original project folder then proceed with sync
# if the folder path not found in .droploy file then create a new entry where source: original project path, target: ~/Dropbox/Public/droploy/<project_name>((project_name exists) ? '-$count('project:project_name') : '')
# create a new folder $target
# sync project folder $ rsync -av . $target
# get Dropbox share link of $target


# Good to have

# able to clone & sync projects from droploy on other computers

echo ">>> Droploying..."

# create droploy supporting files & folders
DROPLOY_ROOT="$HOME/Dropbox/Public/droploy"
DROPLOY_METAFILE=$DROPLOY_ROOT'/.droploy'
[ ! -d $DROPLOY_ROOT ] && mkdir -p $DROPLOY_ROOT
[ ! -f $DROPLOY_METAFILE ] && touch $DROPLOY_METAFILE

# Info about Project Name, Source & Target - save it to .droploy file if necessary
PROJECT_NAME=$(basename `pwd`)
SOURCE=$(pwd)
PROJECT_NAME_COUNT=0
# TARGET=$DROPLOY_ROOT'/'$PROJECT_NAME

while IFS='' read -r line || [[ -n "$line" ]]; do
    IFS=':' read -ra FIELDS <<< "$line"
    if [ ${FIELDS[0]} == $PROJECT_NAME ]
    then
    	PROJECT_NAME_COUNT=$(($PROJECT_NAME_COUNT+1))
    fi
		for i in "${FIELDS[@]}"; do
			if [ ${FIELDS[1]} == $SOURCE ]
			then
				TARGET=${FIELDS[2]}
			fi
		done
		IFS=''
done < $DROPLOY_METAFILE

if [ -z $TARGET ]
then
	if [ $PROJECT_NAME_COUNT -eq 0 ]
	then
		TARGET_SUFFIX=""
	else
		TARGET_SUFFIX="-$PROJECT_NAME_COUNT"
	fi
	TARGET=$DROPLOY_ROOT'/'$PROJECT_NAME''$TARGET_SUFFIX

	echo "$PROJECT_NAME:$SOURCE:$TARGET" >> $DROPLOY_METAFILE
fi

[ ! -d $TARGET ] && mkdir -p $TARGET

echo ">>> Syncing to Dropbox..."

rsync -a --stats . $TARGET && echo ">>> done."
