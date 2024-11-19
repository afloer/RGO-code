#!/bin/bash
# Use image extension many times - takes 3 input parameters, the path to the executable and the input/output files
$1/image-ext.x $2 $2.temp.ext1
$1/image-ext.x $2.temp.ext1 $2.temp.ext2
$1/image-ext.x $2.temp.ext2 $3
rm -f $2.temp.ext1 $2.temp.ext1 $2.temp.ext2
