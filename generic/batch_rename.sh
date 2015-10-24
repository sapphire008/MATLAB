#!/bin/sh
#works with systematically named folders that contains systematically named
#files

ext=.nii;
for foo in .
do 
	cd $foo
	for image in f*.nii; 
 	do 
        	filename=`file "$image"|cut -d- -f3|sed s/^00/""/g`;
        	ln -s $image $filename$ext;
 	done
	cd ..
done
