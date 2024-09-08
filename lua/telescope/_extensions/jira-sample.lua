local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("telescope-jira.nvim requires nvim-telescope/telescope.nvim")
end

local has_plenary, plenary = pcall(require, "plenary")
if not has_plenary then
	error("telescope-jira.nvim requires plenary")
end

local jira = require("jira-sample")

local setup = function(config, _)
	jira.telescope_config = config

	local level = "info"
	if config.debug == true then
		level = "debug"
	end

	jira.log = plenary.log.new({
		plugin = "Jira",
		level = level,
	})
end

return telescope.register_extension({
	setup = setup,
	exports = {
		jira_issue_picker = jira.jira_issue_picker,
		jira_search_picker = jira.jira_search_picker,
	},
})
