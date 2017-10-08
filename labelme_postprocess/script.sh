#!/usr/bin/env sh
# json files generated by lableme tool
JSON_FOLDER=''
# save annotation images (byte png)
ANNO_FOLDER=''
# save images visulizing annotation
ANNO_COLOR_FOLDER=''

# labelme convert (use tool in labelme, convert to png)
th labelme_convert.lua -json_folder $JSON_FOLDER
# matlab uint16 to uint8 (convert unit16 png to uint8 png)
echo 'Starting Matlab...'
    # matlab commandline with parameter
matlab -nojvm -nodesktop -nodisplay -r "uint16_2_uint8('"$JSON_FOLDER"'); exit()"
echo 'Closing Matlab...'
# convert the png to my required png
th labelme2anno.lua -json_folder $JSON_FOLDER -anno_folder $ANNO_FOLDER
# colorize the anno
th color_segmentation.lua \
    -anno_folder $ANNO_FOLDER \
    -anno_color_folder $ANNO_COLOR_FOLDER

echo 'Finished.'