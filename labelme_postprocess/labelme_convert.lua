require 'image'
require 'paths'

local cmd = torch.CmdLine()
cmd:option('-json_folder', '')
local opt = cmd:parse(arg or {})

for f in paths.files(opt.json_folder, '.+%.json') do
    print(f)
    os.execute('labelme_json_to_dataset '..paths.concat(opt.json_folder, f))
end