local tbl = require "utils.tbl"
local fn = require "utils.fn"
local curl = require "utils.curl"
local fs = require "utils.fs"
local log = require "utils.log"
local repo = require "core.repo"
local sandbox = require "utils.sandbox"
local lpkg = require "core.pkg"
-- local config = require "core.config"
-- local lcache = require "commands.install.cache"

local cache = {}

-- remover
-- cache.repos = {
--   {
--     manteiners = { "Diogo-ss" },
--     url = "https://raw.githubusercontent.com/pkger/core-pkgs/main/pkgs/${{ name }}/${{ version }}/pkg.lua",
--   },
-- }

local function env()
  return {
    system = fn.system,
    shell_code = fn.shell_code,
    get = curl.get,
    rm = fs.rm,
    rm_dir = fs.rm_dir,
    cp = fs.cp,
    cd = fs.cd,
    cwd = fs.cwd,
    extract = fs.extract,
    INSTALLATION_ENVIRONMENT = true,
  }
end

local M = {}

local function lerror(msg, dir)
  if dir then
    fs.rm_dir(dir)
  end

  log.error(msg)
  error()
end

function M.pkgs_parse(pkgs)
  local results = {}

  for _, pkg in pairs(pkgs) do
    if pkg:find "@" then
      local name, version = pkg:match "^(.+)@(.+)$"

      if pkg == "@" or not (version or name) then
        log.error("Nome de pacote inválido: " .. pkg)
        os.exit(1)
      end

      results[name] = version
    else
      results[pkg] = "script"
    end
  end

  return results
end

function M.print_pkg_infos(pkg) end

function M.install(name, version, is_dependency)
  log.info(("Iniciando instalação do %s %s"):format(name, version))

  local infos = { name = name, version = version }

  log.info "Obtendo arquvios de instalação."
  local _pkg = lpkg.get_pkg(cache.repos, infos)

  if not _pkg then
    lerror("Não foi possível obter o aquivo de instalação para: " .. name .. " " .. version)
  end

  log.info "Gerando env da instalação."
  local _env = lpkg.load_pkg(_pkg, env())
  local dir = fs.join(PKGER_DATA, _env.name, _env.version)

  -- if _env.depends then
  --   local depends = M.pkgs_parse(_env.depends)
  --   for dname, dversion in pairs(depends) do
  --     print(("name %s version %s dname %s dversion %s"):format(name, version, dname, dversion))
  --     local ok, _ = pcall(M.install, dname, dversion, true)

  --     if not ok then
  --       error"erro na porra da depends"
  --     end

  --   end
  -- end

  if not fs.is_dir(dir) then
    local ok = fs.mkdir(dir)
    if not ok then
      lerror("error oa tentar criar diretório de instalação", dir)
    end
  end

  fs.cd(dir)
  _env.INSTALLATION_DIRECTORY = dir

  -- fs.lock_dir(dir)

  local file = _env.url:gsub("/$", ""):match ".*/(.*)$"

  log.info(("Baixando %s de %s"):format(file, _env.url))
  local ok, _ = pcall(curl.download, _env.url, file)

  if not ok then
    lerror("Não foi possível baixar o arquivo:\n" .. _env.url, dir)
  end

  if version ~= "script" and version ~= "head" then
    log.info "Inciando chacagem sha1..."
    local sha1 = fn.sha1sum(file)
    if sha1 ~= _env.hash then
      lerror("Os sha1 não são iguais. Abortando instalação do " .. name, dir)
    end
  end

  fs.extract(file)
  fs.rm(file)

  local order = {
    "pre_biuld",
    "biuld",
    "pos_biuld",
    "pre_install",
    "install",
    "pos_install",
    "clean",
  }

  --TODO: add check type
  for _, n in pairs(order) do
    local func = _env[n]

    if func then
      if type(func) ~= "function" then
        lerror(n .. " não é uma função. Cheque o script.")
      end

      local ok, _ = pcall(func)

      if not ok then
        lerror(n .. " não pode ser executada.")
      end
    end
  end

  if not fs.is_dir(PKGER_BIN) and fs.mkdir(PKGER_BIN) then
    lerror "Não foi possível obter o diretório do /bin"
  end

  local bin_name = _env.bin:match ".+/([^/]+)$" or _env.bin
  local cmd = 'ln -s "' .. dir .. "/" .. _env.bin .. '" "' .. PKGER_BIN .. "/" .. bin_name .. '"'

  local exit_code, _ = fn.system(cmd)
  if exit_code ~= 0 then
    lerror("Erro ao criar o link simbólico para o binário: " .. _env.bin)
  end

  log.info(
    ("Link simbólico criado com sucesso para o binário %s na versão %s. Use: %s"):format(name, version, bin_name)
  )

  local ok, _ = pcall(_env.test)

  if not ok then
    log.error "O teste apresentou falha na instlação. Deseja remover o binário?"
  end

  -- TODO: perguntar

  -- TODO: check lockfile
end

function M.install_pkgs(pkgs)
  log.info "Carregando repositórios..."
  cache.repos = cache.repos or repo.load_all()
  local current_dir = fs.cwd()

  if not cache.repos then
    log.error "Nenhum repo válido foi encontado."
    os.exit(1)
  end

  for name, version in pairs(pkgs) do
    local ok, err = pcall(M.install, name, version)
    if not ok then
      log.error("intalação não concluida: " .. name .. " " .. version .. ".\n")
      log.warn "checando se há próxima instalação..."
    end
    fs.cd(current_dir)
  end

  -- TODO: função que cria toddos os links
end

function M.parse(args)
  -- fn.print(require "lfs")

  local pkgs = M.pkgs_parse(args)

  if tbl.isempty(pkgs) then
    log.error "Digite um mais poctes para serem instalados. Use --help."
    os.exit(1)
  end

  M.install_pkgs(pkgs)
end

return M
