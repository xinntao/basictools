require 'image'
require 'paths'
local lyaml = require 'lyaml'

local cmd = torch.CmdLine()
cmd:option('-json_folder', '')
cmd:option('-anno_folder', '')
local opt = cmd:parse(arg or {})

local look_up_tb = {}
look_up_tb['8'] = 0 --bg
look_up_tb['1'] = 1 --sky
look_up_tb['2'] = 2 -- water
look_up_tb['3'] = 3 -- grass
look_up_tb['4'] = 4 --mountain
look_up_tb['5'] = 5 --building 
look_up_tb['6'] = 6 --plant
look_up_tb['7'] = 7 --animal
look_up_tb.background = 255

local counter = 0
for dir in paths.files(opt.json_folder, '.+_json') do
    counter = counter + 1
    print(counter, dir)
    local file = io.open(paths.concat(opt.json_folder, dir, 'info.yaml'))
    local str = file:read('*a') -- read all content
    local label_tb = lyaml.load(str).label_names
    -- read anno_raw
    local anno_raw = image.load(paths.concat(opt.json_folder, dir, 'label_uint8.png'), 1, 'byte'):squeeze()
    -- change label
    local anno = anno_raw:clone():zero()
    for i = 0, #label_tb-1 do
        local mask = torch.eq(anno_raw, i)
        local dst_label = look_up_tb[label_tb[i+1]]
        anno:add(mask*dst_label)
    end
    image.save(paths.concat(opt.anno_folder, dir:sub(1, -6)..'.png'), anno)
    os.execute('rm -rf '..paths.concat(opt.json_folder, dir))
end