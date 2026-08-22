health_status = {}
if obj.status ~= nil then
  if obj.status.conditions ~= nil then
    numReady = 0
    msg = ""
    for i, condition in pairs(obj.status.conditions) do
      msg = msg .. i .. ": " .. condition.type .. " = " .. condition.status .. "\n"
      if condition.type == "Ready" and condition.status == "True" then
        numReady = numReady + 1
      end
    end
    if numReady > 0 then
      health_status.status = "Healthy"
      health_status.message = msg
      return health_status
    end
  end
end
health_status.status = "Progressing"
health_status.message = "Reconciliation in progress"
return health_status
