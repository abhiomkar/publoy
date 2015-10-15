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

API_REQUEST_TOKEN_URL="https://api.dropbox.com/1/oauth/request_token"
API_ACCESS_TOKEN_URL="https://api.dropbox.com/1/oauth/access_token"
API_USER_AUTH_URL="https://www.dropbox.com/1/oauth/authorize"
API_INFO_URL="https://api.dropbox.com/1/account/info"
APPKEY=1vn4mbkqqsxf3ds
APPSECRET=di4ey3zcej6741k
RESPONSE_FILE=/tmp/droploy_response
ERROR_STATUS=0

function utime
{
    echo $(date +%s)
}

function print
{
    echo -ne "$1";
}

#Remove temporary files
function remove_temp_files
{
    rm -fr "$RESPONSE_FILE"
}

function check_http_response
{
    CODE=$?

    #Checking curl exit code
    case $CODE in

        #OK
        0)

        ;;

        #Proxy error
        5)
            print "\nError: Couldn't resolve proxy. The given proxy host could not be resolved.\n"

            remove_temp_files
            exit 1
        ;;

        #Missing CA certificates
        60|58)
            print "\nError: cURL is not able to performs peer SSL certificate verification.\n"
            print "Please, install the default ca-certificates bundle.\n"
            print "To do this in a Debian/Ubuntu based system, try:\n"
            print "  sudo apt-get install ca-certificates\n\n"
            print "If the problem persists, try to use the -k option (insecure).\n"

            remove_temp_files
            exit 1
        ;;

        6)
            print "\nError: Couldn't resolve host.\n"

            remove_temp_files
            exit 1
        ;;

        7)
            print "\nError: Couldn't connect to host.\n"

            remove_temp_files
            exit 1
        ;;

    esac

    #Checking response file for generic errors
    if grep -q "HTTP/1.1 400" "$RESPONSE_FILE"; then
        ERROR_MSG=$(sed -n -e 's/{"error": "\([^"]*\)"}/\1/p' "$RESPONSE_FILE")

        case $ERROR_MSG in
             *access?attempt?failed?because?this?app?is?not?configured?to?have*)
                echo -e "\nError: The Permission type/Access level configured doesn't match the DropBox App settings!\nPlease run \"$0 unlink\" and try again."
                exit 1
            ;;
        esac

    fi

}

# create droploy supporting files & folders
DROPBOX_ROOT="$HOME/Dropbox"
if [ ! -d $DROPBOX_ROOT ]
then
    echo "Dropbox is not installed in your system? Exiting."
    ERROR_STATUS=1

    exit $ERROR_STATUS
fi

echo ">>> Droploying..."

PUBLIC_ROOT="$HOME/Dropbox/Public"
[ ! -d $PUBLIC_ROOT ] && mkdir -p $PUBLIC_ROOT
[ ! -d $DROPLOY_ROOT ] && mkdir -p $DROPLOY_ROOT
DROPLOY_ROOT="$HOME/Dropbox/Public/droploy"
DROPLOY_METAFILE=$DROPLOY_ROOT'/.droploy'
CONFIG_FILE=$DROPLOY_ROOT'/.droploy_config'
[ ! -d $DROPLOY_ROOT ] && mkdir -p $DROPLOY_ROOT
[ ! -f $DROPLOY_METAFILE ] && touch $DROPLOY_METAFILE
[ ! -f $CONFIG_FILE ] && touch $CONFIG_FILE

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
	TARGET=$DROPLOY_ROOT'/'$PROJECT_NAME$TARGET_SUFFIX

	echo "$PROJECT_NAME:$SOURCE:$TARGET" >> $DROPLOY_METAFILE
fi

if [ -f "$SOURCE/index.html" ]
then
    INDEX_FILE='index.html'
else
    # if we could'nt find index.html, the first .html file would our index file
    INDEX_FILE=$(find . -type f -maxdepth 1 -iname '*.html' | sed 's/^.\///' | head -n 1)
fi

if [[ $INDEX_FILE == "" ]]
then
    ERROR_STATUS=1

    echo ""
    echo -ne "No 'index.html' file. Exiting."
    echo ""
    exit $ERROR_STATUS
fi

[ ! -d $TARGET ] && mkdir -p $TARGET

echo ">>> Syncing to Dropbox..."

rsync -a --stats . $TARGET > /dev/null && echo ">>> done."

if [ -s $CONFIG_FILE ]
then
    source "$CONFIG_FILE" 2>/dev/null
else
    # first time the user is running the script
    echo -ne "\nThis is the first time you run this script. Talking to Dropbox, Please wait..."

    curl -k -s --show-error --globoff -i -o "$RESPONSE_FILE" --data "oauth_consumer_key=$APPKEY&oauth_signature_method=PLAINTEXT&oauth_signature=$APPSECRET%26&oauth_timestamp=$(utime)&oauth_nonce=$RANDOM" "$API_REQUEST_TOKEN_URL" 2> /dev/null

    check_http_response
    OAUTH_TOKEN_SECRET=$(sed -n 's/oauth_token_secret=\([a-z A-Z 0-9]*\).*/\1/p' "$RESPONSE_FILE")
    OAUTH_TOKEN=$(sed -n 's/.*oauth_token=\([a-z A-Z 0-9]*\)/\1/p' "$RESPONSE_FILE")

    if [[ $OAUTH_TOKEN != "" && $OAUTH_TOKEN_SECRET != "" ]]; then
        echo -ne "\n Please open the following URL in your browser, and allow Droployer\n"
        echo -ne " to access your Dropbox Public folder:\n\n --> ${API_USER_AUTH_URL}?oauth_token=$OAUTH_TOKEN\n"
        echo -ne "\nPress enter when done...\n"
        read

        echo -ne " > Access Token request... "
        curl -k -s --show-error --globoff -i -o "$RESPONSE_FILE" --data "oauth_consumer_key=$APPKEY&oauth_token=$OAUTH_TOKEN&oauth_signature_method=PLAINTEXT&oauth_signature=$APPSECRET%26$OAUTH_TOKEN_SECRET&oauth_timestamp=$(utime)&oauth_nonce=$RANDOM" "$API_ACCESS_TOKEN_URL" 2> /dev/null
        check_http_response
        OAUTH_ACCESS_TOKEN_SECRET=$(sed -n 's/oauth_token_secret=\([a-z A-Z 0-9]*\)&.*/\1/p' "$RESPONSE_FILE")
        OAUTH_ACCESS_TOKEN=$(sed -n 's/.*oauth_token=\([a-z A-Z 0-9]*\).*/\1/p' "$RESPONSE_FILE")

        if [[ $OAUTH_ACCESS_TOKEN != "" && $OAUTH_ACCESS_TOKEN_SECRET != "" ]]; then
            # now get dropbox user id
            echo -ne " OK\n"

            curl -k -s --show-error --globoff -i -o "$RESPONSE_FILE" --data "oauth_consumer_key=$APPKEY&oauth_token=$OAUTH_ACCESS_TOKEN&oauth_signature_method=PLAINTEXT&oauth_signature=$APPSECRET%26$OAUTH_ACCESS_TOKEN_SECRET&oauth_timestamp=$(utime)&oauth_nonce=$RANDOM" "$API_INFO_URL" 2> /dev/null
            check_http_response

            if grep -q "^HTTP/1.1 200 OK" "$RESPONSE_FILE"; then
                uid=$(sed -n 's/.*"uid": \([0-9]*\).*/\1/p' "$RESPONSE_FILE")
                echo "uid=$uid" >> "$CONFIG_FILE"
                echo "https://dl.dropboxusercontent.com/u/$uid/droploy/$PROJECT_NAME$TARGET_SUFFIX/index.html"
            else
                echo -ne " FAILED\n"
                ERROR_STATUS=1
            fi
        else
            echo -ne " FAILED\n"
            ERROR_STATUS=1
        fi
    else
        echo -ne " FAILED\n"
        ERROR_STATUS=1
    fi
fi

if [ $ERROR_STATUS -eq 0 ]
then
    echo ""
    echo "> Share link: (Syncing...)"
    echo "https://dl.dropboxusercontent.com/u/$uid/droploy/$PROJECT_NAME$TARGET_SUFFIX/$INDEX_FILE"
fi

# remove_temp_files
exit $ERROR_STATUS
