# 📦 PKGER

A simple and lightweight package manager written in Lua (currently only for Linux).

The purpose of this package manager is to allow packages to be distributed in Lua scripts in a simple way, allowing binaries to be distributed or compiled directly from source code.

# Features

- It uses url patterns to obtain packages, thus allowing the use of an api and raw files in the repositories.
- Supports search (API and GitHub by default).
- Maintain different versions of a single package.
- No sudo needed.
- Self-hosting of repositories made simple, see: TODO

## TODO

- [ ] install script
- [ ] GitLab search
- [ ] Git repo search
- [ ] Metadata search
- [ ] Doc for self-hosting
- [ ] Write specifications.

## installation

<details> <summary>Install script</summary>
  
```sh
TODO
```

</details>

<details> <summary>Binary</summary>
  
Download the latest version at: [latest](https://github.com/Diogo-ss/pkger/releases/latest)

</details>

<details> <summary>Script</summary>
You can use the package manager without compiling.

### dependencies

- [Luarocks](https://github.com/luarocks/luarocks/wiki/Download)
- [Lua 5.4](https://www.lua.org/download.html)

```sh
git clone https://github.com/Diogo-ss/pkger.git
cd pkger

luarocks make --only-deps --lua-version=5.4 --local

lua src/main.lua --help
```

</details>

## build

### dependencies

- [Luarocks](https://github.com/luarocks/luarocks/wiki/Download)
- [Lua 5.4](https://www.lua.org/download.html)

```sh
git clone https://github.com/Diogo-ss/pkger.git
cd pkger

luarocks make --only-deps --lua-version=5.4 --local
luarocks install luastatic

sh scripts/build.sh
```
