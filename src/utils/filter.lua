local tbl = require("utils.tbl")

local M = {}

local function valid(value, types, optional)
	if optional and value == nil then
		return
	end

	local valid_type = false
	for _, _type in ipairs(types) do
		if type(value) == _type then
			valid_type = true
			break
		end
	end

	assert(valid_type, "" .. "Expected one of: " .. table.concat(types, ", "))
end

function M.repo(env)
	-- valid(env.env, { "table" }, true)
	valid(env.template, { "table" })
	valid(env.template.lock, { "string" })
	valid(env.template.pkg, { "string" })
	valid(env.manteiners, { "table", "string" })

	if type(env.manteiners) == "table" then
		env.manteiners = table.concat(env.manteiners, ", ")
	end

	return {
		manteiners = env.manteiners,
		env = env.env,
		template = env.template,
	}
end

function M.pkg(env)
	valid(env.version, { "string" })
	valid(env.description, { "string" }, true)
	valid(env.env, { "table" }, true)
	valid(env.homepage, { "string" }, true)
	valid(env.license, { "string", "table" })
	valid(env.manteiners, { "string", "table" }, true)
	valid(env.url, { "string" })

	if string.match(env.url, "%.git$") then
		valid(env.branch, { "string" }, true)
		if env.hash then
			error("It is not allowed to define a hash in a Git repository URL.")
		end
	else
		if not env.hash then
			error("The hash of the file is not defined.")
		else
			valid(env.hash, { "string" })
		end
		if env.branch then
			error("It is not allowed to define a branch in a file URL.")
		end
	end

	valid(env.conflicts, { "table" }, true)
	valid(env.depends, { "table" }, true)
	valid(env.make_depends, { "table" }, true)
	valid(env.checkver, { "table" })
	valid(env.checkver.url, { "string" })
	valid(env.checkver.jsonpath, { "string" }, true)
	valid(env.checkver.regex, { "string" })

	-- TODO: add functions

	if type(env.manteiners) == "table" then
		env.manteiners = table.concat(env.manteiners, ", ")
	end

	return {
		manteiners = env.manteiners,
		version = env.version,
		description = env.description,
		homepage = env.homepage,
		license = env.license,
		url = env.url,
		hash = env.hash,
		branch = env.url,
		conflicts = env.conflicts,
		depends = env.depends,
		make_depends = env.make_depends,
		checkver = env.checkver,
	}
end

function M.lock(env)
	valid(env.bot, { "table" }, true)

	if env.bot then
		valid(env.bot.update, { "table" }, true)
		if env.bot.update then
			valid(env.bot.update.ignore, { "boolean" }, true)
		end
	end

	for key, value in pairs(env) do
		if key ~= "bot" then
			valid(value.vulnerable, { "boolean" }, true)
			valid(value.commit, { "string" }, true)
			valid(value.stable, { "boolean" }, true)
			valid(value.avaliabe, { "boolean" }, true)
			valid(value.note, { "table", "string" }, true)

			if type(value.note) == "table" then
				env[key].note = table.concat(value.note, "\n")
			end

			if value.commit then
				if value.url then
					error("It is not allowed to have a pinned commit and the url of pkg.lua")
				end
			else
				valid(value.url, { "string" }, true)
			end
		end
	end

	return env
end

function M.config(env)
	valid(env.repos, { "table" }, true)

	if env.repos then
		for _, repo in pairs(env.repos) do
			valid(repo, { "string" })
		end
	end

	return {
		repos = env.repos,
	}
end

return M
