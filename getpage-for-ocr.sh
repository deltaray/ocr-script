#!/bin/bash

# Written by Deltaray for scanning pages from a book.
# 2023-11-23
# I release this under the terms of the GPLv3 license.
#  
# Requires the following programs:
#  gphoto2
#  ImageMagick (for convert)
#  tesseract
#  grep (you have it)
# You might have to change the paths below.

BOOKTITLE="Under the Bleechers"
AUTHOR="Semore Butz"
BOOKFILEPREFIX="under_the_bleechers"


/usr/bin/gphoto2 --force-overwrite --port usb: --capture-image-and-download --filename fromcamera.jpg

# You'll need to adjust the crop according to your needs. Take a fromcamera.jpg
# photo into Gimp or something and figure out what the crop numbers are.

/usr/bin/convert fromcamera.jpg -crop 2275x1700+785+560 output-cropped.jpg

/usr/bin/tesseract output-cropped.jpg ocr-text

number_re='^[0-9]+$'


printf "==============================================================================\n"

/usr/bin/grep -E -v -e "^\ *$" -e "^$BOOKTITLE" -e "^$AUTHOR$" -e "^\ *-[0-9]+-\ *$" ocr-text.txt | /usr/bin/grep -P -v "^\x0C$"
/usr/bin/grep -E -v -e "^[\ \f]*$" -e "^$BOOKTITLE" -e "^$AUTHOR$" -e "^\ *-[0-9]+-\ *$" ocr-text.txt | /usr/bin/grep -P -v "^\x0C$" | xsel -b

printf "==============================================================================\n"

printf "\n\n"

# Assumes that the format of the page number footer is "-N-"
detectedpage=$( /usr/bin/tail ocr-text.txt | /usr/bin/grep --color=no -P -o -e "(?<=^-)[0-9]+(?=-$)" )

if [[ $detectedpage =~ $number_re ]]; then
    read -p "What page is this? [$detectedpage] " page
    if [[ $page =~ $number_re ]]; then
        page=$page
    elif [[ "X$page" == "X" ]]; then
        page=$detectedpage
    else
        printf "ERROR: couldn't determine page\n"
        exit 1
    fi
else
    read -p "What page is this? " page
fi


# Zero pad numbers to 3 digits so files sort nicely.
if [[ $page =~ $number_re ]]; then
    page=$( printf "%03d" $page )
fi

/usr/bin/convert -quality 85 -resize 80% output-cropped.jpg $BOOKFILEPREFIX-${page}.jpg
printf "Done\n"

# In post processing I'm going to have to convert quotes to fancy quotes and -- to emdashes.
# Also check for | and / characters in the output.

