#!/bin/sh
# Script to create MD5 hashes for only video files

#  Create / Update MD5 files.  Usage: UpdateMD5.sh
#
# Switches:
#	-i *.ext	only create / update *.ext files. if multiple file types, use multiple -i
#	-s sharename	traverse only certain share (default = all shares)
#	-u 		Update changed md5's for files whose date stamps are newer than the date stamp of the md5 file
#	-U		Don't update md5's for  files whose date stamps are newer than the date stamp of the md5 file (default)
#	-m		If the MD5 doesn't exist on the same drive as the media file, move it to the same drive (default)
#	-M		do not move the MD5
#	-h		Usage help


# Get command arguments

INCL_EXCL=""
INCL_PARA=0
UPDATE=0
MOVE=1
SHARES=""
SHAREFLAG=0
while getopts i:s:uUmMh OPT;
do
	case "$OPT" in
		i)
			if [ $INCL_PARA -gt "0" ]
			then
				INCL_EXCL="$INCL_EXCL -o"
			fi

			INCL_EXCL="$INCL_EXCL -iname $OPTARG"
			INCL_PARA=1
			;;
		u)
			UPDATE=1
			;;
		U)
			UPDATE=0
			;;
		m)
			MOVE=1
			;;
		M)
			MOVE=0
			;;
		s)
			SHARES="$(echo "$SHARES $OPTARG")"
			SHAREFLAG=1
			;;
		h)
			echo "Usage:"
			echo "-i *.ext   only create / update *.ext files.  If using multiple file types, use multiple -i  At least one entry is required"
			echo "-s  share name - required.  Use multiple if required"
			echo "-u  Update changed md5 for modified files (datestamp > datestamp of md5)"
			echo "-U  Don't update changed md5 for modified files (default)"
			echo "-m  Move the .md5 from user shares to disk shares (ensure on same drive as media file)(default)"
			echo "-M  Don't move the .md5 from user share to disk share"

			exit 0
			;;
		\?)
			echo "you are an idiot"
			exit 0
			;;
	esac
done

if [ $SHAREFLAG -eq 0 ]
then
#	echo "here"
	SHARES="."
fi

echo $SHAREFLAG
echo "Parameters = $INCL_EXCL"
echo "Update is $UPDATE"
echo "Move is $MOVE"
echo "$SHARES"

for SHARE in $SHARES
do
	if [ ! -d "/mnt/user/$SHARE" ];
	then
		echo "$SHARE does not exist"
	fi
done

# PASS #1 -> create MD5's on the user shares

for CURRENTSHARE in $SHARES
do


	cd "/mnt/user/$CURRENTSHARE"

	find $DIR -type f $INCL_EXCL | while read FILENAME
	do
		MD5FILE="$FILENAME.md5"

# Does the md5 already exist?
		if [ -e "$MD5FILE" ]
		then
# Do we update if the file is newer?
			echo "$MD5FILE already exists"
			if [ $UPDATE -eq "1" ]
			then

        	                if [ $(date +%s -r "$FILENAME") -gt $(date +%s -r "$MD5FILE") ];
                	        then
#                        	        cd "${FILENAME%/*}"
					echo "Going to md5 $FILENAME"
#                                	logger "$FILENAME changed... Updating MD5"
	                                md5sum -b "$FILENAME" > /tmp/md5file.md5
        	                        mv /tmp/md5file.md5 "$MD5FILE"
                	        fi
			fi


                else
			echo "$MD5FILE does NOT exist"
#                        cd "${FILENAME%/*}"

#                        logger "Creating MD5 for $FILENAME"
			echo "going to md5 $FILENAME" 
                        md5sum -b "$FILENAME" > /tmp/md5file.md5
                        mv /tmp/md5file.md5 "$MD5FILE"
                fi
	done

done

# PASS 2 - > ensure the MD5 files are on the same disk as the file itself

echo $MOVE
if [ $MOVE -eq "1" ]
then
	ALLDISK=$(ls /mnt --color="never" | egrep "disk")

	for DISK in $ALLDISK
	do
		DIR="/mnt/$DISK"
		for SHARE in $SHARES
		do
			TESTDIR="$DIR/$SHARE"
			SHAREDIR="/mnt/user/$SHARE"

			find $TESTDIR $INCL_EXCL | while read FILENAME
			do
				MD5FILE="$FILENAME.md5"

				if [ -e "$MD5FILE" ]
				then
					TRUE=1
				else
	#				echo "$MD5FILE does NOT exist"
					MD5="$(basename "$FILENAME").md5"

					SHAREFILE=$(find /mnt/user/$SHARE -name "$MD5")

					if [ -e "$SHAREFILE" ]
					then
						echo "$MD5FILE exists elsewhere in user shares"
						echo "moving from $SHAREFILE to $MD5FILE"
						mv "$SHAREFILE" /tmp/md5file.md5
						mv /tmp/md5file.md5 "$MD5FILE"
					else
						echo "$MD5FILE does not exist"
					fi
				fi

#		TESTDIR="$DIR/$SHARE"
#		echo "$TESTDIR"
			done
		done
	done
fi



exit 0
