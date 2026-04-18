function Schema:ClockworkKernelLoaded()
    if not MFS then
        ErrorNoHalt("[MilsimFrontier] MFS config library did not load.\n")
        return
    end

    MFS.Log("Clockwork kernel loaded for schema version %s.", MFS.Version or "unknown")
end
