-- Module Name: mjlib.lua - LuaJit only my lib
-- version: 221007
-- first version: 22094

-- ## TODO
-- * 최종목표: ffi만 로드하고 lfs_ffi도 mjlib 내에 포함시킨다.
-- * 내부 함수 및 문서 정리: Document 생성 가능하도록 포멧을 정한다.
-- * lfs_ffi 의존성을 조금씩 벗어나기
-- * [x] 221007: lib table name modify: mlib -> _M
-- * [x] 221007: ipattern(): add: ignorecase pattern return 
-- * [x] 221006: flist(dir): listfiles(dir) 함수 대체용: lfs_ffi.lua 적용(luajit only)
-- * [x] 220928: gethostname(): ffi.c.gethostname()으로 전환
-- * [x] 220928: mtime(): lfs_ffi로 전환: 실행속도 개선
-- * [x] 220928: lfs_ffi.lua를 적용
-- * [x] 220928: mlib.lua 에서 mjlib.lua로 분기

local ffi = require'ffi'
local lfs = require'lfs_ffi'

local _M = {}
-----------------------------------------------------------
--## 시스템 정보 관련 함수
-----------------------------------------------------------

-- gethostname()
--[[
function _M.gethostname()
    local f = assert(io.popen ("/bin/hostname"))
    local hostname = f:read("*a") or ""
    f:close()
    hostname = string.gsub(hostname, "\n$", "")
    return hostname
end
--]]

-- get hostname: Using Luajit ffi
function _M.gethostname()
  local n = 64
  local hostname = ffi.new('char[?]', n+1)

  ffi.cdef[[
  int gethostname(char *name, size_t namelen);
  ]]

  if ffi.C.gethostname(hostname, n+1) then
    return ffi.string(hostname)
  end
end

-----------------------------------------------------------
--## String 관련 함수
-----------------------------------------------------------

-- ignorecase code from stackoverflow
--[[
function case_insensitive_pattern(pattern)

  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)

  return p
end

print(case_insensitive_pattern("xyz = %d+ or %% end"))
--]]

-- ignorecase pattern return: hello -> [hH][eE][lL][lL][oO]
function _M.ipattern(word)
  local pattern = ''
  for c in word:gmatch'.' do
  pattern = pattern..'['..c:lower()..c:upper()..']'
  end
  return pattern
end

-----------------------------------------------------------
--## 입력 관련 함수
-----------------------------------------------------------

-- simple getopt: user input -> opt, args
function _M.getopt()
  local opt = ''
  local args = {}
  for i,v in pairs(arg) do
       if i == 1 then opt = v
    elseif i > 1 then table.insert(args, v)
    end
  end
  return opt, args
end

-----------------------------------------------------------
--## 출력 관련 함수
-----------------------------------------------------------

-- verbose switch level 
_M.VLOG = 0

-- verbose log for debugging
function _M.vlog(level, func, str)
  --level = tonumber(level) or 0
  if _M.VLOG >= level then
    print('VLOG_'..level.. ' [ ' ..func.. ' ] ' ..str)
  end
end

-- change string to color string
function _M.cstr(str, color)
    color = color or 'lcyan'
    color_list = {
      lred='00;31',red='01;31', lgreen='00;32', green='01;32',
      lyellow='00;33', yellow='01;33', lblue='00;34', blue='01;34',
      lpurple='00;35', purple='01;35', lcyan='00;36', cyan='01;36',
      lgray='01;37', gray='00;37',
    }
    for key,value in pairs(color_list) do
        if (key == color) then 
            return "\27[" .. value .. "m" .. str .. "\27[0m"
        end
    end
    -- if not color match, return str original
    return str
end


-- color print line
function _M.cprint(text, color)
    color = color or 'lcyan'
    color_list = {
      lred='00;31',red='01;31', lgreen='00;32', green='01;32',
      lyellow='00;33', yellow='01;33', lblue='00;34', blue='01;34',
      lpurple='00;35', purple='01;35', lcyan='00;36', cyan='01;36',
      lgray='01;37', gray='00;37',
    }
    for key,value in pairs(color_list) do
        if (key == color) then 
            print("\27[" .. value .. "m" .. text .. "\27[0m")
            return 1
        end
    end
    print(text)
end

-----------------------------------------------------------
--## 파일 관련 함수
-----------------------------------------------------------

-- get ext name from filepath: '.ext', 'ext' are ok 
function _M.extname(filepath)
  if filepath then
    return string.gsub(filepath, "(.*%.)(.*)", "%2")
  end
end

-- dirname return in filepath
function _M.dirname(filepath)
  if filepath then
    return string.gsub(filepath, "(.*)/(.*)", "%2")
  end
end

-- get basename: '.ext', 'ext' are ok 
function _M.basename(filepath, ext)
  local name = ''
  name = string.gsub(filepath, "(.*/)(.*)", "%2")
  if ext then
    -- check if 'ext' is '.ext' and remove '.'
    ext = _M.extname(ext)
    name = string.gsub(name, '%.'.. ext, '')
  end
  return name
end

-- command full path in: /../../{lib|bin}/cmd.lua to /../..
function _M.prefix(cmdpath)
  if string.match(cmdpath, '^/') then
    return string.gsub(cmdpath, '/%a+/%a+%.lua','')
  else
    return string.gsub(os.getenv('PWD'), '/%a+$','')
  end
end

-- file copy from src to des
function _M.fcp(src, des)
  local infile = assert(io.open(src, 'r'))
  local instr = infile:read('*a')
  infile:close()
  local outfile = assert(io.open(des,'w'))
  outfile:write(instr)
  outfile:close()
end

-- open, read filename and then return lines
function _M.readlines(filename)
  return io.lines(filename)
end

--[[
-- listfiles(dir): 디렉토리 내 파일리스트를 출력: 소트하고 테이블로 반환
function _M.listfiles(dir)
 --find .  -maxdepth 1 -print0
 local list = {}
 local files = assert(io.popen('find '..dir..' -type f'))
 --for f in files:lines() do print(f) end
   local fname = ''
   for f in files:lines() do
     fname = _M.basename(f)
     table.insert(list, fname)
   end
   table.sort(list)
 return list
end
--]]

-- 디렉토리 내 파일리스트를 출력: 소트하고 테이블로 반환
function _M.listfiles(dir)
  return lfs.dir(dir)
end

--- Check if a file or directory exists in this path
function _M.isfile(file)
 local ok, err, code = os.rename(file, file)
 if not ok then
    if code == 13 then
       -- Permission denied, but it exists
       return true
    end
 end
 return ok, err
end

--- Check if a directory exists in this path
function _M.isdir(path)
   -- "/" works on both Unix and Windows
   return _M.isfile(path.."/")
end

-- mtime(file) : get modification time
-- https://stackoverflow.com/questions/33296834/how-can-i-get-last-modified-timestamp-in-lua
--[[
function _M.mtime(file)
	local f = io.popen("stat -c %Y "..file)
	local last_modified = f:read()
	return last_modified
end
--]]

-- get modification time
function _M.mtime(file)
  return assert(lfs.attributes(file).modification)
end

-- check src file is modified 
function _M.ismodified(src, des)
  --_M.vlog(1, 'ismodified', _M.mtime(src)..' '.._M.mtime(des))
  if _M.mtime(src) > _M.mtime(des) then
    return true
  end
end

-- remove dir include files : 내부에 폴더가 있는 경우 처리 못함
function _M.remove_dir(path)
  if _M.isdir(path) then
    for f in lfs.dir(path) do
      if f ~= '.' and f ~= '..' then
        f = path .. '/' .. f
        print('remove file -> ', f)
        os.remove(f)
      end
    end
    print('remove dir -> ', path)
    os.remove(path)
  end
end

-----------------------------------------------------------
--## 기타
-----------------------------------------------------------

-- get_gentime(gentime_file) : get generation time
function _M.get_gentime(gentime_file)
	-- gentime_file check first
	if not _M.exists(gentime_file) then
    fd = io.open(gentime_file,"w")
    io.output(fd)
    io.write('1234567890')
    io.close(fd)
	end

	fd = io.open(gentime_file,"r")
	io.input(fd)
	local data = io.read()
	io.close(fd)

  return data
end

-- put_gentime(gentime_file) : put generation time
function _M.put_gentime(gentime_file)
	fd = io.open(gentime_file,"w")
	io.output(fd)
	io.write(os.date("%s"))
	io.close(fd)
end

return _M
