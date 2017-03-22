--
-- PAVI interface for lua
-- Xintao Wang, 2017.03.22
--
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local cjson = require 'cjson'

local M ={}

local function request_POST(url, reqbody_tb)
   local reqbody = cjson.encode(reqbody_tb)
   local respbody = {} -- for the response body
   local result, respcode, respheaders, respstatus = http.request {
      url = url,
      method = "POST",
      source = ltn12.source.string(reqbody),
      headers = {
         ["Content-Type"] = "application/json",
         ["Content-Length"] = reqbody:len()
      },
      sink = ltn12.sink.table(respbody)
   }
   -- get body as string by concatenating table filled by sink
   respbody = table.concat(respbody)
   return respcode, respstatus, respbody
end

local function PAVI_handshake(tb)
   --[[ tb contains:
   usr: PAVI usrname: also for device usr
   pwd: PAVI password
   main_file: as the session content
   opt: as the sessiontext
   model_dir: the path to save the models
   machine: models on which machine
   --]]

   -- convert opt table to a txt string
   local opt_str = 'Opt:\n'
   for k, v in pairs(tb.opt) do
      opt_str = opt_str..'\t'..k..'\t:\t'..v..'\n'
   end

   local time_json = os.date('%Y-%m-%dT%XZ') -- 2017-03-21T22:41:30Z
   local reqbody_tb = {
      username    = tb.usr,
      password    = tb.pwd,
      model       = tb.model_name,
      session     = tb.main_file,
      sessiontext = opt_str,
      workdir     = tb.model_dir,
      device      = tb.usr..'@'..tb.machine,
      time        = time_json
   }
   local PAVI_url = 'http://pavi.parrotsdnn.org/log'
   -- We try three times for handshake
   local retry = 0
   local respbody, respcode, respstatus
   while retry < 3 do
      respcode, respstatus, respbody = request_POST(PAVI_url, reqbody_tb)
      if respcode == 200 then print('PAVI handshake succeed!') break end
      -- otherwise try it again
      retry = retry + 1
      print(('Fail in PAVI handshake. Return code: %d, error message %s'):format(respcode, respstatus))
   end
   if retry == 3 then print('After 3 retry, handshake still fail. Exit and please check.') os.exit(1) end
   return respbody
end
M.PAVI_handshake = PAVI_handshake

local function PAVI_senddate(tb)
   --[[ tb contains:
   usr: PAVI usrname
   pwd: PAVI password
   id: get from PAVI_shakehand
   phase: train/test
   iter: iteration, we should not send data too frequently, otherwise the brower will be slow.
   data: table containing the data needed to be drawn
   --]]

   local time_json = os.date('%Y-%m-%dT%XZ') -- 2017-03-21T22:41:30Z
   local reqbody_tb = {
      username    = tb.usr,
      password    = tb.pwd,
      instance_id = tb.id,
      flow_id     = tb.phase,
      iter_num    = tb.iter,
      outputs     = tb.data,
      time        = time_json
   }
   local PAVI_url = 'http://pavi.parrotsdnn.org/log'
   -- since we handshake successfully, we suppose that we can also send data successfully through one time
   local respcode, respstatus, respbody = request_POST(PAVI_url, reqbody_tb)
   if respcode ~= 200 then print(('Warning: PAVI send data failed! Return code: %d, error message %s'):format(respcode, respstatus)) end
end
M.PAVI_senddate = PAVI_senddate

local function test()
   -- form a opt
   local cmd = torch.CmdLine()
   cmd:text('Options:')
   cmd:option('-model_name',                 'A_Model',       'desc')
   cmd:option('-iter',                       1000,            'desc')
   cmd:option('-mode',                       'val',           'train_test or val')
   cmd:option('-is_criterion',               'false',         'train_test or val')
   cmd:text()
   local opt = cmd:parse(arg or {})
   -- PAVI_handshake and get an instance_id
   local instance_id = PAVI_handshake({usr='Xintao', pwd='******', model_name='test', main_file='./test/main.lua', opt=opt, model_dir='./parent_file/DIV2K', machine=46})
   print(instance_id)
   -- generate data
   for i= 1,5000 do
      print(i)
      --train
      local train_loss = 10+i/100+torch.normal(0,0.5)
      local train_PSNR = 20+i/200+ torch.normal(0,0.5)
      local send_data_train = {loss=train_loss, acc_PSNR=train_PSNR}
      PAVI_senddate({usr='Xintao', pwd='123456', id=instance_id, phase='train', iter=i, data=send_data_train})
      -- test
      if i%100 == 0 then
         local test_loss = 12+i/167+torch.normal(0,0.1)
         local test_PSNR = 23+i/234+torch.normal(0,0.1)
         local send_data_test = {loss=test_loss, acc_PSNR=test_PSNR}
         PAVI_senddate({usr='Xintao', pwd='******', id=instance_id, phase='test', iter=i, data=send_data_test})
      end
   end
   print('Test finish. Please check the PAVI website.')
end
M.test = test

return M

