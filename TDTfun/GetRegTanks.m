%  MCA-Suite (c) DJS 2009

function regtanks = GetRegTanks(TTX)

for idx = 1:100
    regtanks{idx} = TTX.GetEnumTank(idx-1);
    if isempty(regtanks{idx}), break; end
end

regtanks(end) = [];

end