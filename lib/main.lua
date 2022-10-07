#!/usr/bin/env luajit
-- Luajit memo 관리 프로그램: memo
-- first version: 0.1 (22-10-05)

-- ## TODO
-- * list와 search시 여러 표시(오늘날짜,기타정보)를 주어 편리를 제공한다.
-- * mjlib 모듈에 함수부분 모두 코멘트: 코딩시 vim에서 함수 설명이 보이게 된다.
-- * 기본 테스트하기
-- * 메모파일 암호화: 아주 나중에... 
-- * 구글드라이브에 올리기: 암호폴더에 백업하기
-- * do_list(): 추가 옵션 기능 구현: today, yesterday...
-- * [x] 22.10.07: do_search(): ignorecase key search enabled: and search also
-- * [x] 22.10.05: EDITOR 변수에 따라 do_edit()에서 처리하도록 설정
-- * [x] 22.10.05: 코드 정리
-- * [x] 22.10.05: 깃허브에 올리기: 소스만 올리고 관리
-- * [x] 22.10.05: fileinfo(): memo 한 줄 보여주기 함수 구현
-- * [x] 22.10.04: do_delete(): 기능 구현
-- * [x] 22.10.04: do_list(): 기본 구현, 표시 방법 정리
-- * [x] 22.10.04: do_search(): 한줄에서 두개의 다른 키워드가 검색될 경우 라인 중복 문제
-- * [x] 22.10.04: help 수정
--
-- ## NOTICE
-- * 프로그램과 라이브러리는 모두 lib/* 이하에 존재한다.
-- * 실행스크립트만 bin/ 이하에 존재하여 환경변수와 함께 exec로 실행된다.
-- * 이것이 갖는 장점은 다음과 같다. (환경변수 MCONF, mlib.prefix(arg[0]) 활용)
-- * 1) 개발시
--      - lib/main.lua로 lib 디렉토리 내에서 개발하고 테스트 가능
-- * 2) 배포및 사용시
--      - setup.sh로 실행스크립트를 생성한다. bin/mconf
--      - 프로젝트 폴더 이름을 활용하여 MCONF prefix를 구할 수 있다.
--      - 이로서 bin을 PATH에 추가해주면 스크립트 bin/mconf를 어디서나 사용가능
--      - 사용자가 복잡하게 설정해 줄 필요없이  PATH만 잡아주면 된다.
-- * 다만 바이너리를 컴파일해서 사용할 경우에도 스크립트로 실행해야 한다.
-- * 바이너리 직접실행의 경우에는 쉘에서 환경변수를 잡고 설정파일도 만들어야 한다.
-- * 백업할 파일이 심볼릭 링크라면 업데이트 정보를 확인할 수 없다.

--## Require

local m = require'mjlib'

--## Var Set
local HOSTNAME = m.gethostname()
local PREFIX = os.getenv('MEMO')
if not PREFIX then PREFIX = m.prefix(arg[0]) end
local EDITOR = os.getenv('EDITOR')
if not EDITOR then EDITOR = 'vim' end
local PREFIX_DATA = PREFIX..'/data'
local DBFILE = PREFIX_DATA..'/memo.db'
local progname = m.basename(PREFIX)
local version = '0.1'
--print(MCONF, MCONF_DATA)

--## under functions

-- help 도움말
local function help()
  print('Usage: '..progname..' "strings"')
  print()
  print('-a|add "strings"             add memo')
  print('-d|delete id[s]              delete id[s]')
  print('-e|edit id[s]                edit id[s]')
  print('-l|list [d|dd|ddd|w|m|y|a]   list')
  print('   d:today dd:yesterday ddd:day before yesterday')
  print('   w:week m:month y:year a:all')
  print('-s|search keyword[s]         keyword[s] search: and-search')
  print('-v|view id[s]                view id[s]')
end

-- 출력 마지막에 결과를 표시
local function print_title(title, sub)
  if not sub then sub = '' end
  local icon = nil
  local t = string.lower(title)
  if t == 'search' then
    icon = ''
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
  file = assert(io.open(PREFIX_DATA..'/'..f, 'r'))
  --title = file:read('*l')
  first_line = file:read()
  file:close()
  if not first_line then first_line = '' end
  --local str = string.format(' '..i..' '..f..' ('..time2date(f)..')')
  local str = string.format(' %d %s (%s)',id,f,time2date(f))
  m.cprint(str,'yellow')
  print('  '..first_line)
end

-- 숫자로된 이름의 파일만 테이블을 만들어 반환
local function get_flist(dir)
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
  local fname = os.time()
  local file = assert(io.open(PREFIX_DATA..'/'..fname,'a+'))
  if file:write(memo) then
    file:close()
    m.cprint('-> add: '..fname..' is added!')
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
    for i, f in pairs(get_flist(PREFIX_DATA)) do
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
      for i, f in pairs(get_flist(PREFIX_DATA)) do
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

-- 리스트를 출력
local function do_list(args)
  local tot = 0
  local file = nil
  local title = ''
  for i,f in pairs(get_flist(PREFIX_DATA)) do
    fileinfo(i,f)
    tot = tot + 1
  end

  print_title('list', 'total:'..tot)
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
  for i,f in pairs(get_flist(PREFIX_DATA)) do
    -- 검색해서 해당라인들을 테이블로 넘겨줌
    local lines = match_lines(PREFIX_DATA..'/'..f, keys)
    if lines then
      tot = tot + 1
      --local str = string.format(' '..i..' '..f..' ('..time2date(f)..')')
      local str = string.format(' %d %s (%s)', i, f, time2date(f))
      m.cprint(str, 'yellow')
      for _, line in pairs(lines) do
        print('  '..line)
      end
    end
  end
  print_title('search', string.format('tot:'..tot))
end

-- 메모 보기
local function do_view(ids)
  local tot = 0
  for _,id in pairs(ids) do
    id = tonumber(id)
    for i,f in pairs(get_flist(PREFIX_DATA)) do
      if i == id then
        tot = tot + 1
        m.cprint(i..') '..f)
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

if #arg == 0 then
  do_add(args)
  os.exit()
end

-- receive opt, args from arg
opt, args = m.getopt()


-- execute function in case
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
  help()
end
print()
