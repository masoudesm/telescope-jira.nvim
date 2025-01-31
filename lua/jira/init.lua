local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local config = require("telescope.config")
local plenary_job = require("plenary.job")
local plenary_log = require("plenary.log")

local log = plenary_log:new({
    plugin = "Jira",
    level = "info",
})

local function run_command(cmd, args)
    local job_opts = {
        command = cmd,
        args = args,
    }
    local job = plenary_job:new(job_opts):sync()
    return job
end

local function format_issues(issues)
    return vim.iter(issues)
        :map(function(issue)
            local issue_key, issue_title =
                issue:match("([^:]+)%s*:%s*([%S%s]+)")
            return { key = issue_key, title = issue_title }
        end)
        :totable()
end

-- Fetch current user Jira issues using `go-jira`
local function get_issues()
    local result = run_command("jira", {
        "ls",
        "-q",
        "assignee = currentUser()",
    })
    return format_issues(result)
end

-- Fetch detailed information for a specific Jira issue
local function get_issue_details(issue_key)
    local result = run_command("jira", {
        "view",
        issue_key,
    })
    return result
end

-- Fetch Jira issues for a specific project using `go-jira`
local function get_issues_by_project(project)
    local result = run_command("jira", {
        "ls",
        "-q",
        "project =" .. project,
    })
    return format_issues(result)
end

local M = {}

function M.jira_issue_picker(opts)
    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = "Jira Issues",
            finder = finders.new_dynamic({
                fn = function()
                    return get_issues()
                end,

                entry_maker = function(issue)
                    return {
                        value = issue,
                        display = issue.key .. " " .. issue.title,
                        ordinal = issue.key,
                    }
                end,
            }),
            sorter = config.values.generic_sorter({}),
            previewer = previewers.new_buffer_previewer({
                title = "Issue Details",
                define_preview = function(self, entry)
                    local issue_details = get_issue_details(entry.value.key)
                    vim.api.nvim_buf_set_lines(
                        self.state.bufnr,
                        0,
                        0,
                        false,
                        issue_details
                    )
                    utils.highlighter(self.state.bufnr, "markdown")
                end,
            }),
            attach_mappings = function(prompt_bufnr, map)
                return true
            end,
        })
        :find()
end

-- Picker to search Jira issues in a specific project
function M.jira_search_picker(opts)
    opts = opts or {}
    local project = vim.fn.input("Project: ") or ""

    pickers
        .new({}, {
            prompt_title = "Search Jira Issues in Project: " .. project,
            finder = finders.new_dynamic({
                fn = function()
                    return get_issues_by_project(project)
                end,
                entry_maker = function(issue)
                    return {
                        value = issue,
                        display = issue.key .. " " .. issue.title,
                        ordinal = issue.key,
                    }
                end,
            }),
            sorter = config.values.generic_sorter({}),
            previewer = previewers.new_buffer_previewer({
                title = "Issue Details",
                define_preview = function(self, entry)
                    local issue_details = get_issue_details(entry.value.key)
                    vim.api.nvim_buf_set_lines(
                        self.state.bufnr,
                        0,
                        0,
                        false,
                        issue_details
                    )
                    utils.highlighter(self.state.bufnr, "markdown")
                end,
            }),
            attach_mappings = function(prompt_bufnr, map)
                return true
            end,
        })
        :find()
end

return M
