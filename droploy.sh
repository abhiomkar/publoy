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
# ~/Sites/save-martina $ droploy --> ~/Dropbox/Public/droploy/save-martian

# check if dropbox is installed
# check if rsync command is available

# create a folder 'droploy' in ~/Dropbox/Public if not exists
# create a new file in the above folder called '.droploy' if not exists
# read .droploy, if project folder path in this file matches with the original project folder then proceed with sync
# if the folder path not found in .droploy file then create a new entry where source: original project path, target: ~/Dropbox/Public/droploy/<project_name>((project_name exists) ? '-$count('project:project_name') : '')
# create a new folder $target
# sync project folder $ rsync -av . $target
# get Dropbox share link of $target
