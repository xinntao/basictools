require 'torch'
require 'paths'
require 'image'

torch.setdefaulttensortype('torch.FloatTensor')

local cmd = torch.CmdLine()
cmd:option('-anno_folder', '')
cmd:option('-anno_color_folder', '')
local opt = cmd:parse(arg or {})

if paths.dirp(opt.anno_color_folder) then
   print('Warning: anno_color_folder has already existed. It will cover it.')
else
   if paths.mkdir(opt.anno_color_folder) then print('Succeed mkdir!') else print('Failed mkdir, exit!') os.exit(0) end
end

-- lookup_table is a double RGB tensor #categories * 3
local lookup_table = torch.Tensor({
   {153, 153, 153}, -- 0, background
   {0, 255, 255}, --1, sky
   {109, 158, 235}, --2, water
   {183, 225, 205}, --3, grass
   {153, 0, 255}, -- 4, mountain
   {17, 85, 204}, -- 5, building
   {106, 168, 79}, -- 6, plant
   {224, 102, 102}, -- 7, animal
   --{241, 194, 50}, -- 8, person
   --{133, 32, 12}, -- 9, road
   --{244, 204, 204}, -- 10, vehicle
   {255, 255, 255}, -- 8/255, void
   })
lookup_table = lookup_table / 255

local counter = 1
for f in paths.files(opt.anno_folder, '.+%.%a+') do
   -- read images
   local img_name = f:sub(1, -5)
   print(counter, img_name); counter = counter + 1
   local img = image.load(paths.concat(opt.anno_folder, f), 1, 'byte'):add(1):squeeze()
   local im_h, im_w = img:size(1), img:size(2)
   local color = torch.Tensor(3, im_h, im_w):zero() -- black
   for i = 1,8 do -- have add 1
      local mask = torch.eq(img, i)
      color:select(1,1):maskedFill(mask, lookup_table[i][1]) -- R
      color:select(1,2):maskedFill(mask, lookup_table[i][2]) -- G
      color:select(1,3):maskedFill(mask, lookup_table[i][3]) -- B
   end
   -- void
   local mask = torch.eq(img, 256)
   color:select(1,1):maskedFill(mask, lookup_table[9][1]) -- R
   color:select(1,2):maskedFill(mask, lookup_table[9][2]) -- G
   color:select(1,3):maskedFill(mask, lookup_table[9][3]) -- B

   image.save(paths.concat(opt.anno_color_folder, f), color)

end

