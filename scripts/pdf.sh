#!/bin/bash

#Automatic scan/conversion script
#Requires sane, imagemagick, and pdftk

#Scan in the pages
scanadf --mode "Black & White" --resolution 200

#Convert each page to a pdf file and delete the original image file for file in image-*
do
convert $file $file.pdf
rm $file
done

#Concatenate all the individual pdf files into one single file and delete the original pdf files
pdftk image-*.pdf cat output $1.pdf
rm image-*.pdf

exit 0