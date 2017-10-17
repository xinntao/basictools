-- crop patches from ADE images according to segmentations
-- use cv package, it is not necessary.

require 'image'
require 'paths'
local cv = require 'cv'
require 'cv.imgcodecs'
require 'cv.imgproc'

local anno_folder = '../ADE_COCO/train/anno'
local img_folder = '../ADE_COCO/train/images'
local txt_file = './A_building_position_desc.txt'
local dst_folfer = './A_building'
local label = 6
local default_crop_per_img = 81
local square_size = 96
local threshold = 0.8

-- create folder
if paths.dirp(dst_folfer) then
   print('Warning: Model '..dst_folfer..' exits.\nDo you want to remove and recreate it ?  y for yes.')
   local res = io.read()
   if 'y' == res then
      paths.rmall(dst_folfer, 'yes')
      if paths.mkdir(dst_folfer) then print('Succeed: mkdir '..dst_folfer..'!') else print('Failed: mkdir '..dst_folfer..', exit!'); os.exit(1) end
   else
      print('keep the foder and exit...'); os.exit(0)
   end
else -- create the folder
   if paths.mkdir(dst_folfer) then print('Succeed: mkdir '..dst_folfer..'!') else print('Failed: mkdir '..dst_folfer..', exit!'); os.exit(1) end
end



local w_file = io.open(txt_file, 'w')
local counter = 0
local counter_imgs = 0
for f in paths.files(anno_folder, '.+%.%a+') do
   -- read anno to tensor
   local ext = paths.extname(f)
   local img_name = paths.basename(f, ext)
   local anno = cv.imread{paths.concat(anno_folder, f), flags=cv.IMREAD_GRAYSCALE}:float()
   anno = cv.resize{src=anno, fx=0.95, fy=0.95, interpolation=cv.NEAREST}
   if torch.sum(torch.eq(anno, label)) > square_size*square_size then
      -- annotation with particular class and has enough large area
      --print(img_name)
      local h, w = anno:size(1), anno:size(2)
      local img = cv.imread{paths.concat(img_folder, img_name..'.jpg'), flags=cv.IMREAD_COLOR}:float()
      img = cv.resize{src=img, fx=0.95, fy=0.95, interpolation=cv.INTER_AREA}
      local candidate_tb = {}

      for x = 1, h-square_size+1, 3 do
         for y = 1, w-square_size+1, 3 do
            -- loop for all the image with stride 3
            if label == anno[x][y] and
               label == anno[x+square_size-1][y+square_size-1] and
               label == anno[x][y+square_size-1] and
               label == anno[x+square_size-1][y] and
               label == anno[x+square_size/2][y+square_size/2] and
               -- four corners and center points
               torch.sum(torch.eq(anno[{{x,x+square_size-1},{y,y+square_size-1}}], label)) > square_size*square_size*threshold then
               -- put it into a candidate table
               table.insert(candidate_tb, {x,y})
            end
         end
      end
      --print('\tNo. of candidates is '..(#candidate_tb))

      -- choose some cropped images
      local counter_save = 0
      local index_tb = {}
      local save_tb = {}
      local stride = math.ceil(#candidate_tb/default_crop_per_img)
      if #candidate_tb > 1 then
         for i=1, #candidate_tb, stride do
            table.insert(index_tb, i)
         end
         for i=1, #index_tb-1 do
            local rnd = torch.random(index_tb[i], index_tb[i+1]-1)
            table.insert(save_tb, rnd)
         end
      elseif #candidate_tb == 1 then table.insert(save_tb, 1)
      end

      if #save_tb > 0 then
         counter_imgs = counter_imgs+1
         for i=1, #save_tb do
            local index = save_tb[i]
            local x, y = candidate_tb[index][1], candidate_tb[index][2]
            counter_save = counter_save+1
            if 1 == counter_save then
               w_file:write(counter_imgs..'\t'..img_name..'\t No. of candidates: '..#candidate_tb..'\n')
               print(counter_imgs..'\t'..img_name..'\t No. of candidates: '..#candidate_tb)
            end
            w_file:write('\t'..counter_save..'\t('..x..', '..y..')\n')
            print('\t'..counter_save..'\t('..x..', '..y..')')
            local img_crop = img[{{x,x+square_size-1},{y,y+square_size-1},{}}]
            cv.imwrite{paths.concat(dst_folfer, img_name..'_'..counter_save..'.png'), img = img_crop, params = {cv.IMWRITE_PNG_COMPRESSION, 0}}
         end
      end

      counter = counter+counter_save
   end
end
w_file:write('#total cropped images: '..counter..'\n')
w_file:write('from '..counter_imgs..' images.')
print('#total cropped images: '..counter..' from '..counter_imgs..' images.')
w_file:close()
