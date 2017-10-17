require 'paths'

local train_img_folder = '/media/xintao/3TB_XT/SegDatasets/grass_crawl_resize'
local file_train_list = io.open('grass_crawl_resize_list.txt', 'w')

local N = 0
for f in paths.files(train_img_folder, '.+%.%a+') do
   local img_name = f:sub(1,-5)
   local train_img_full_path = paths.concat(train_img_folder, img_name..'.png')
   if paths.filep(train_img_full_path)  then
      if N ~= 0 then file_train_list:write('\n') end
      file_train_list:write(f)
      N = N + 1
      print(N)
   end
end
file_train_list:close()

