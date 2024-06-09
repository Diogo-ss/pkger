# 📦 PKGER

A simple and lightweight package manager written in Lua (currently only for Linux).

The purpose of this package manager is to allow packages to be distributed in Lua scripts in a simple way, allowing binaries to be distributed or compiled directly from source code.

⚠️ Warning
PKGER is still in development and not yet secure for production use. It is highly recommended to test it in a container rather than on your main machine.

some packages: [core-pkgs](https://github.com/pkger/core-pkgs.git) (Linux)

# Features

- Uses URL patterns to obtain packages, allowing the use of an API and raw files in repositories.
- Supports package search (API and GitHub by default).
- Maintains different versions of a single package.
- No sudo needed.
- Simplified self-hosting of repositories (documentation pending).

## TODO

- [ ] install script
- [ ] GitLab search
- [ ] Git repo search
- [ ] Metadata search
- [ ] Doc for self-hosting
- [ ] Write specifications.
- [ ] Improving dependency management.
- [ ] Makedepends

## installation

<details> <summary>Install script</summary>
  
```sh
TODO
```

</details>

<details> <summary>Binary</summary>
  
Download the latest version at: [latest](https://github.com/Diogo-ss/pkger/releases/latest)

</details>

<details> <summary>Lua script</summary>
You can use the package manager without compiling.

### dependencies

- Git
- base-devel
- [Lua 5.4](https://www.lua.org/download.html)
- [Luarocks](https://github.com/luarocks/luarocks/wiki/Download)

```sh
git clone https://github.com/Diogo-ss/pkger.git
cd pkger

luarocks make --only-deps --lua-version=5.4 --local

eval "$(luarocks path --bin)"

lua src/main.lua --help
```

</details>

## build

### dependencies

- Git
- base-devel
- [Luarocks](https://github.com/luarocks/luarocks/wiki/Download)
- [Lua 5.4](https://www.lua.org/download.html)
- [luastatic](https://github.com/ers35/luastatic)

```sh
git clone https://github.com/Diogo-ss/pkger.git

cd pkger

luarocks make --only-deps --lua-version=5.4 --local

eval "$(luarocks path --bin)"

luarocks install luastatic

make

./bin/pkger --help
```

## PKG

A simple script to install Neovim in version 0.9.5 (binary)

```lua
name = "neovim"
description = "Vim-fork focused on extensibility and usability"
homepage = "https://neovim.io"
license = "Apache-2.0"
manteiners = "Diogo-ss"
version = "0.9.4"
url = "https://github.com/neovim/neovim/releases/download/v${{ version }}/nvim-linux64.tar.gz"

bin = "bin/nvim"

checkver = {
 url = "https://api.github.com/repos/neovim/neovim/releases/latest",
 jsonpath = "tag_name",
 regex = "[Vv]?(.+)",
}

function install()
 system("mv * ..")
end
```
