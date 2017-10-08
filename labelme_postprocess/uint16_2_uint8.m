function uint16_2_uint8(json_folder)
    folders = dir(fullfile(json_folder, '*_json'));
    for i = 1: length(folders)
        im_uint16 = imread(fullfile(json_folder, folders(i).name, 'label.png'));
        im_uint8 = uint8(im_uint16);
        imwrite(im_uint8, fullfile(json_folder, folders(i).name, 'label_uint8.png'))
    end
end