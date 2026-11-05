--yo world

local Palin = {}
Palin.__index = Palin

function Palin.Init(ObjectType:Instance, InitFn, EndFn, Expand:boolean?, PoolSize:number?)
    local self = setmetatable({}, Palin)
    local autoExpand = Expand or false

    self.Type = ObjectType
    self.InitFn = InitFn
    self.EndFn = EndFn
    self.Size = PoolSize or 5
    self.Expand = autoExpand

    self.Free = {}
    self.Job = {}

    for _i = 1, self.Size do
        local clone = ObjectType:Clone()
        table.insert(self.Free, clone)
    end

    return self
end

function Palin:Release(Amount:number?)
    local count = Amount or #self.Free

    for _i = 1, count do
    local obj = table.remove(self.Free)

    if obj == nil then
        if self.Expand then
            warn(string.format(("PALIN: Free list is empty. Dynamically allocating a new '%s' instance."), self.Type.ClassName))
            obj = self.Type:Clone()
            self.Size += 1
        else
            warn("PALIN: Free list is empty. Release operation aborted.")
            return false
        end
    end

    table.insert(self.Job, obj)
    self.InitFn(obj) 
    end

    return true
end

function Palin:Hold(Object:Instance)
    local i = table.find(self.Job, Object)
    if not i then 
        warn(string.format("PALIN: Cannot hold object '%s' (%s) because it is not currently in use.", Object.Name, Object.ClassName))
        return false
    end
    local cur_obj = table.remove(self.Job, i)
    self.EndFn(cur_obj)
    table.insert(self.Free, cur_obj)

    return true
end

function Palin:Add(Amount:number)
    if not self.Expand then
        warn("PALIN: Expanding Pools are disabled.")
        return false
    end
    for _i = 1, Amount do
        table.insert(self.Free, self.Type:Clone())
    end
    self.Size += Amount
    return true
end

function Palin:Destroy(End:boolean?)
    for _, obj in self.Free do
        obj:Destroy()
    end
    for _, obj in self.Job do
        if End then
            self.EndFn(obj)
        end
        obj:Destroy()
    end
    self.Free = {}
    self.Job = {}

    setmetatable(self, nil)
    return true
end