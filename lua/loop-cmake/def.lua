--- @meta

---@class loop.Task
---@field name string # non-empty task
---@field type "composite"|string # task type
---@field depends_on string[]? # optional list of dependent task names
---@field depends_order "sequence"|"parallel"|nil # default is sequence

---@class loop.taskTemplate
---@field name string
---@field task loop.Task

---@class loop.TaskControl
---@field is_running fun():boolean
---@field terminate fun()

---@alias loop.TaskExitHandler fun(success:boolean,reason:string|nil)

---@class loop.TaskProvider
---@field get_config_schema fun():table|nil
---@field get_config_template fun():table|nil
---@field get_config_order (fun(path:string):string[])|nil
---@field get_task_schema fun():table
---@field get_task_templates fun(config:table|nil):loop.taskTemplate[]
---@field start_one_task fun(task:loop.Task,page_manager:loop.PageManager, on_exit:loop.TaskExitHandler):(loop.TaskControl|nil,string|nil)

---@class loop.tools.TermProc
---@field is_running fun(self: loop.tools.TermProc):boolean
---@field terminate fun(self: loop.tools.TermProc)

---@class loop.pages.Page

---@class loop.tools.TermProc.StartArgs
---@field name string
---@field command string|string[]
---@field env table<string,string>|nil
---@field cwd string|nil
---@field output_handler fun(stream: "stdout"|"stderr", data: string[])|nil
---@field on_exit_handler fun(code : number)|nil

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
