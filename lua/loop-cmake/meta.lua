--- @meta

assert(false, "should not require meta file")

---@class loop.PageGroup
---@field expired fun():boolean
---@field add_page fun(id:string,label:string,activate?:boolean):loop.pages.Page
---@field add_term_page fun(id:string, args:loop.tools.TermProc.StartArgs, activate?:boolean):loop.tools.TermProc|nil,string|nil
---@field get_page fun(id:string):loop.pages.Page|nil
---@field activate_page fun(id:string)
---@field delete_pags fun()

---@class loop.PageManager
---@field expired fun():boolean
---@field add_page_group fun(id:string,label:string):loop.PageGroup
---@field get_page_group fun(id:string):loop.PageGroup|nil
---@field delete_page_group fun(id:string)
---@field delete_all_groups fun(expire:boolean)
---@field get_page fun(group_id:string,page_id:string):loop.pages.Page|nil

---@class loop-cmake.Task : loop.Task
---@field build_type string
---@field cwd string?
---@field env table<string,string>? # optional environment variables
---@field quickfix_matcher string|nil
