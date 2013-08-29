function P = DB_GetUnitProps(unit_id)
% P = DB_GetUnitProps(unit_id)
% 
% Retrieve and sort unit properties
%
% DJS 2013 daniel.stolzberg@gmail.com

P = [];

dbP = mym('SELECT * FROM v_unit_props WHERE unit_id = {Si}',unit_id);

upid = unique(dbP.param_id);
upar = unique(dbP.param);
ugrp = unique(dbP.group_id);

for i = 1:length(upid)
    for j = 1:length(ugrp)
        ind = dbP.param_id == upid(i) & ismember(dbP.group_id,ugrp{j});
        if isnan(dbP.paramF(ind))
            P.(upar{i}){j} = dbP.paramS(ind);
        else
            P.(upar{i})(j) = dbP.paramF(ind);
        end
    end
end
