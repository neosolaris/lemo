#!/usr/bin/env luajit
-- Luajit console memo program
-- update version: 0.1.1 (22-10-10)
-- first version: 0.1beta (22-10-05)

-- ## TODO
-- * 메모파일 암호화: 아주 나중에... 
-- * 전체 메모 개수와 함께 파일 사이즈 및 기타 통계 출력: -i option
-- * [x] 0.1.1: do_add() : lastid 확인해서 보여주기 추가
-- * [x] 0.1.0: do_list() 일수 별 입력 추가: 1 3 4 5 0
-- * [x] 0.1.0: do_list(): 추가 옵션 기능 구현: today, week...
-- * [x] 0.1.0: do_search(): ignorecase key search enabled: and search also
-- * [x] 0.1.beta: 최초 beta 버전 완성 및 업로드

--## Require

local m = require'mjlib'

--## Var Set
local PREFIX = os.getenv('MEMO')
if not PREFIX then PREFIX = m.prefix(arg[0]) end
local EDITOR = os.getenv('EDITOR')
if not EDITOR then EDITOR = 'vim' end
local PREFIX_DATA = PREFIX..'/data'
--local HOSTNAME = m.gethostname()
--local DBFILE = PREFIX_DATA..'/memo.db'
local progname = m.basename(PREFIX)
local version = '0.1.1'
--print(MCONF, MCONF_DATA)

-- LIMIT OF DAYS default
local DAY_LIMIT = 3
-- COLOR SET OF DAYS
local COL_TODAY = 'lred'
local COL_INDAY = 'lpurple'
local COL_LIMIT = 'lyellow'
local COL_OTHER = 'lgray'

--## under functions
-- 출력 마지막에 결과를 표시
local function print_title(title, sub)
  if not sub then sub = '' end
  local icon = nil
  local t = string.lower(title)
  if t == 'search' then
    icon = ''
  elseif t == 'help' then
    icon = ''
  elseif t == 'list' then
    icon = ''
  elseif t == 'add' then
    icon = ''
  elseif t == 'edit' then
    icon = ''
  elseif t == 'delete' then
    icon = ''
  elseif t == 'view' then
    icon = ''
  else
    icon = ''
  end
  --local str = string.format('﮶_%s_%s %s %s ﰲ %s', progname, version, icon, title, sub)
  local lua = m.cstr('','lred')
  local ptitle = m.cstr(''..progname..'_'..version, 'lpurple')
  local mtitle = m.cstr(icon..' '..title..' ﰲ '..sub, 'lcyan')
  --local str = string.format(' _%s_%s %s %s ﰲ %s', progname, version, icon, title, sub)
  print(string.format('%s %s %s', lua, ptitle, mtitle))
end

-- help 도움말
local function help()
  m.cprint('Usage: '..progname..' "strings"', 'lyellow')
  print('  -a|add "strings"             -- add memo')
  print('  -d|delete id[s]              -- delete id[s]')
  print('  -e|edit id[s]                -- edit id[s]')
  print('  -l|list [d|w|m|y|a]          -- list')
  print('           d:today w:week m:month y:year a:all')
  print('  -s|search keyword[s]         -- keyword[s] search: and-search')
  print('  -v|view id[s]                -- view id[s]')
  print_title('help','Console Memo Powered by LuaJit')
end


-- time() 형식의 시간을 date로 변환
local function time2date(time)
  -- os.date() 함수는 time이 숫자로된 문자열이 들어와도 동작한다.
  return os.date('%F %T', time)
end

-- time() 형식의 시간을 현재로부터 비교하여 그 갯수를 반환
local function get_datecount(time,today,week,month)
  if os.date('%y%m%d') == os.date('%y%m%d',time) then today = today+1 end
  if os.date('%y%m%W') == os.date('%y%m%W',time) then week = week+1 end
  if os.date('%y%m') == os.date('%y%m',time) then month = month+1 end
  return today, week, month
end

-- 메모파일의 정보와 첫줄 표시
local function fileinfo(id,f)
  local file = assert(io.open(PREFIX_DATA..'/'..f, 'r'))
  --title = file:read('*l')
  local first_line = file:read()
  file:close()
  if not first_line then first_line = '' end
  --local str = string.format(' '..i..' '..f..' ('..time2date(f)..')')
  local str = string.format(' %d %s (%s)',id,f,time2date(f))
  m.cprint(str,'yellow')
  print('  '..first_line)
end

local function getfline(f)
  local file = assert(io.open(PREFIX_DATA..'/'..f, 'r'))
  local fline = file:read()
  file:close()
  if not fline then fline = '' end
  return fline
end

-- 숫자로된 이름의 파일만 테이블을 만들어 반환
local function getflist(dir)
  local flist = {}
  for f in m.listfiles(dir) do
    -- .과 ..은 넘어감
    if f ~= '.' and f ~= '..' then
      -- 넘어 온 파일이름이 맞는 형식인지 검사
      if tonumber(f) then table.insert(flist, f) end
    end
  end
  -- table sort for flist before return
  table.sort(flist)
  return flist
end


--## do functions

-- 메모를 추가하는 함수: readlines 추가 기능 필요
local function do_add(args)
  args = args or {}
  local memo = ''
  -- check whether args is
  if not next(args) then
    memo = io.read('*a')
  else
    for i,a in pairs(args) do
      if i ~= 1 then a = ' '..a end
      memo = memo..a
    end
  end
  -- write memo to file
  local lastid = 0  -- lastid number
  local fname = os.time()
  local file = assert(io.open(PREFIX_DATA..'/'..fname,'a+'))
  if file:write(memo) then
    file:close()
    -- get lastid from filelist
    for _ in pairs(getflist(PREFIX_DATA)) do lastid=lastid+1 end
    -- print add file info
    m.cprint('-> add: ('..lastid..') '..fname..' is added!')
  else
    m.cprint('-> add: '..fname..' is failed!')
  end
end

-- delete files from ids
local function do_delete(ids)
  -- check ids is null
  if not next(ids) then
    print('delete: next is not exists!')
    return 1
  end
  -- set delted file count
  local dc = 0
  -- delete ids loop
  for _, id in pairs(ids) do
    id = tonumber(id)
    for i, f in pairs(getflist(PREFIX_DATA)) do
      if i == id then
        fileinfo(i,f)
        io.write(m.cstr('-> Are you sure (y/N)? ','lred'))
        local input = io.read()
        if input == 'y' or input == 'Y' then
          assert(os.remove(PREFIX_DATA..'/'..f))
          m.cprint('-> deleted! '..i..' '..f, 'lred')
          dc = dc + 1
        end
      end
    end
  end
  print_title('delete', 'total:'..dc)
end

-- ids로 선택하여 파일을 편집
local function do_edit(ids)
  --ids = ids or {os.date('%y%m%d')} -- table ids는 값이 없을 경우 아래와 같이 해야 함
  if not next(ids) then
    -- 입력한 Id가 없다면 현재시간으로 메모파일을 만들고 nvim으로 편집 후 종료
    assert(os.execute(EDITOR..' '..PREFIX_DATA..'/'..os.time()))
    return
  end
  local match = 0
  -- loop ids
  for _,id in pairs(ids) do
    id = tonumber(id)
    -- check if input id is number
    if id then
      -- loop list
      for i, f in pairs(getflist(PREFIX_DATA)) do
        --print(id, i, f)
        -- check id is in the list and edit
        if i == id then
          match = match + 1
          assert(os.execute('nvim '..PREFIX_DATA..'/'..f))
          m.cprint('-> add: '..i..' '..f..' is edited!')
        end
      end
      -- print id is not match in the list
      if match < 1 then
        m.cprint('-> edit: "'..id..'" is not exists. check please!')
      end
    -- print id is not number
    else
      m.cprint('-> edit: "'..id..'" is wrong id. check please!')
    end
  end
end

-- file is in date time
--[[
local function is_intime(ftime, limit)
  --ftime = 1665111863
  if limit == 'day' then
    if os.date('%Y%m%d') == os.date('%Y%m%d',ftime) then return true end
  elseif limit == 'week' then
    if os.date('%Y%m%W') == os.date('%Y%m%W',ftime) then return true end
  elseif limit == 'month' then
    if os.date('%Y%m') == os.date('%Y%m',ftime) then return true end
  elseif  limit == 'year' then
    if os.date('%Y') == os.date('%Y',ftime) then return true end
  elseif  limit == 'all' then
    return true
  else -- default: week
    if os.date('%y%m%W') == os.date('%y%m%W',ftime) then return true end
  end
end
--]]

-- file이 days 날수 이내라면 true 리턴: fitime, days are numbers
local function is_intime(ftime, days)
  days = days or 0
  local q,_ = math.modf( (os.time() - ftime) / 86400 )
  if days == 0 or q < days then
    return true
  end
end

-- file이 today인지 판별
local function is_today(ftime)
  if os.date('%Y%m%d',os.time()) == os.date('%Y%m%d',ftime) then
    return true
  end
end

-- list memo from data
local function do_list(args)
  local tot, tot_today, tot_1day, tot_limit = 0,0,0,0
  -- set limit: default w(eek)
  --local limit = args[1] or '3'
  local limit = tonumber(args[1])
  -- if no args, limit is default = 3 days
  if #args == 0 then limit = DAY_LIMIT end
  --- check arg[1] is valid
  if not limit then
    if args[1] == 'd' or args[1] == 'day' then limit = 1
    elseif args[1] == 'w' or args[1] == 'week' then limit = 7
    elseif args[1] == 'm' or args[1] == 'month' then limit = 30
    elseif args[1] == 'y' or args[1] == 'year' then limit = 365
    elseif args[1] == 'a' or args[1] == 'all' then limit = 0
    else print('-> option is not accepted! See help: -h'); return
    end
  end

  -- loop file list
  local fline = ''
  local icon = ''
  for i,f in pairs(getflist(PREFIX_DATA)) do
    tot = tot + 1
    -- check file is in limit days
    --if is_intime(tonumber(f),limit) then
    if is_intime(f,limit) then
      tot_limit = tot_limit + 1
      fline = getfline(f) or ''
      --outline = string.format('%4d  %s %s', i, time2date(f), fline)
      outline = string.format('%4d  %s', i, fline)
      -- show color days in 1 day files
      if is_intime(f, 1) then
        if is_today(f) then
          icon = m.cstr('', COL_TODAY)
          tot_today = tot_today + 1
        else
          icon = m.cstr('', COL_INDAY)
          tot_1day = tot_1day + 1
        end
      else
        if is_intime(f, DAY_LIMIT) then
          icon = m.cstr('', COL_LIMIT)
        else
          icon = m.cstr('', COL_OTHER)
        end
      end
      print(string.format('%4d %s %s',i,icon,fline))
    end
  end

  print_title('list', string.format('total(%d), limit(%d), yesterday(%d), today(%d)', tot, tot_limit, tot_1day, tot_today))
  --print_title(string.format('list[%s]',limit
end


-- 한 파일에 해당 키워드가 있는 라인을 테이블로 리턴
local function match_lines(f, keys)
  local mlines = {}
  local ct = {}  -- count table for keys
  -- init count table set
  for _,key in pairs(keys) do ct[key] = 0 end
  -- Start line loop
  for line in assert(io.lines(f)) do
    -- check iskey is true in keys loop
    local iskey = false
    for _,key in pairs(keys) do
      --if string.match(string.lower(line), string.lower(key)) then
      -- change the line to color: unchanged orginal keyword Case
      for k in line:gmatch(m.ipattern(key)) do
        -- if matched, iskey is true
        iskey = true
        -- if matched, ct[key] is counted 1 more
        ct[key] = ct[key] + 1
        -- change the line to color only : preserve the key case
        line = string.gsub(line, k, m.cstr(k,'lyellow'))
      end
      --end
    end
    -- check whether this line is suitable adding to mlines
    if iskey then table.insert(mlines, line) end
  end
  -- check whether all keys counted
  --for _,key in pairs(keys) do print(key, ct[key]) end
  for _,key in pairs(keys) do
    if ct[key] == 0 then return end
  end

  -- return matched lines if exist
  return mlines
end

-- 키워드로 검색
local function do_search(keys)
  --local lines = {}
  local tot = 0
  for i,f in pairs(getflist(PREFIX_DATA)) do
    -- 검색해서 해당라인들을 테이블로 넘겨줌
    local lines = match_lines(PREFIX_DATA..'/'..f, keys)
    if lines then
      tot = tot + 1
      m.cprint(string.format('%d  %s %s', i, f, time2date(f)))
      for _, line in pairs(lines) do
        print('  '..line)
      end
    end
  end
  -- keyword info sum: input keywords to allkey str
  local allkey = ''
  for i,k in pairs(keys) do
    if i == 1 then allkey = k
    else allkey = allkey..' & '..k end
  end
  print_title('search', '['..allkey..'] total:'..tot)
end

-- 메모 보기
local function do_view(ids)
  local tot = 0
  local icon = ''
  for _,id in pairs(ids) do
    id = tonumber(id)
    for i,f in pairs(getflist(PREFIX_DATA)) do
      if i == id then
        tot = tot + 1
        m.cprint(string.format('%4d  %s %s', i, f, time2date(f)))
        for line in io.lines(PREFIX_DATA..'/'..f) do
          print('  '..line)
        end
      end
    end
  end
  print_title('view', string.format('tot:'..tot))
end

---------------------------------------------------------------------------
-- ## Main
-------------------------------------------------------------------------

-- receive opt, args from arg
local opt, args = m.getopt()

if #arg == 0 then
  do_add(args)
  os.exit()
end

-- execute function by select option
print()
if opt == '-h' or opt == 'help' or opt == 'h' then
  help()
elseif opt == '-a' or opt == 'add' or opt == 'a' then
  do_add(args)
elseif opt == '-d' or opt == 'delete' or opt == 'd' then
  do_delete(args)
elseif opt == '-e' or opt == 'edit' or opt == 'e' then
  do_edit(args)
elseif opt == '-l' or opt == 'list' or opt == 'l' then
  do_list(args)
elseif opt == '-s' or opt == 'search' or opt == 's' then
  do_search(args)
elseif opt == '-v' or opt == 'view' or opt == 'v' then
  do_view(args)
else
  if tonumber(opt) then
    do_view({opt})
  else
    help()
  end
end
print()
