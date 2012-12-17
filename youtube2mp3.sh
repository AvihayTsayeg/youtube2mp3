#!/bin/bash
#
# youtube2mp3
#
# Author: Petur Ingi Egilsson <petur at petur.eu>
# Version Date: 27 March 2010
# The most recent version of this program can be found on http://www.petur.eu/
#
# Please email me any changes or suggestions.
#
# Dependencies on Ubuntu 9.10:
#	* ffmpeg
#	* youtube-dl
#	* libavcodec-unstripped-52

##
## Check for dependencies
##
which youtube-dl >/dev/null
if [ "$?" != '0' ]
	then
		zenity \
		--error \
		--title="Error" \
		--text="youtube-dl was not found in `echo $PATH`"
	exit
fi
which ffmpeg >/dev/null
if [ "$?" != '0' ]
	then
		zenity \
		--error \
		--title="Error" \
		--text="ffmpeg was not found in `echo $PATH`"
	exit
fi

##
## Prompt the user for details
##
youtubeURL=`zenity --entry \
	--title="youtube2mp3" \
	--text="Enter URL (http://www.youtube.com/location-of-video/"`

## Remove everything after & in the url, as youtube-dl is not design to handle it.

myVar=${myVar%&*}

if [ ! -n "$youtubeURL" ]
	then
		zenity \
		--error \
		--title="Error" \
		--text="URL cannot be empty."
	exit
fi

FILE=`zenity --file-selection \
	--file-filter=*.mp3 \
	--file-filter=* \
	--confirm-overwrite \
	--save \
	--title="Save"`

if [ ! -n "$FILE" ]
	then
		zenity \
		--error \
		--title="Error!" \
		--text="You must select a destination file."
		exit
	else
	
	## makes sure the filename ends with .mp3	
	if [[ $FILE != *.mp3 ]]
        then
                FILE=${FILE}.mp3
	fi
fi 

##
## Set a temporary file and start the download process
##

tmpFile=~/.youtube-dl-$RANDOM-$RANDOM.flv

zenity \
--info \
--text="The download procecss will be started in the background. I will let you know once I'm finished. Please be patient."

youtube-dl --output=$tmpFile --format=18 "$youtubeURL"




##
## youtube-dl does not alway honor the "return 0 if no problems" rule
## So i check if the tmpFile gets created. If it's missing then something is wrong.
##
if [ ! -e $tmpFile ]; then
        zenity \
	--error \
	--text="Error from youtube-dl, run from the console to see more details."
	exit
fi
if [ "$?" != '0' ]; then
	echo $?
        zenity \
	--error \
	--text="Error from youtube-dl, run from the console for more details."
	## delete temporary files
	rm $tmpFile
fi

## Convert the tmp youtube vid to .mp3
ffmpeg -i $tmpFile -acodec libmp3lame -ac 2 -ab 128k -vn -y "$FILE"


##
## ffmpeg returns only 0 if all is ok
##
if [ "$?" != '0' ]; then
	echo $?
        zenity \
	--error \
	--text="Error from ffmpeg, run from the console to see more details."
	## delete temporary files	
	rm $tmpFile
	rm $FILE
	exit
fi
if [ ! -e $FILE ]; then
        zenity \
	--error \
	--text="Unknown error from ffmpeg. The mp3 file has not been created."
	## delete temporary files	
	rm $tmpFile
	exit
fi

## delete the temporary file
rm $tmpFile

## Alert user
zenity \
--info \
--text="Download complete."
