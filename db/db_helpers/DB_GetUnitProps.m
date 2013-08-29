function P = DB_GetUnitProps(unit_id)
% P = DB_GetUnitProps(unit_id)
% 
% Retrieve and sort unit properties
%
% DJS 2013 daniel.stolzberg@gmail.com

narginchk(1,1);

P = [];

dbP = mym(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
           'WHERE unit_id = {Si} ORDER BY group_id,param'],unit_id);

upar = unique(dbP.param);
ugrp = unique(dbP.group_id);

for i = 1:length(upar)
    iind = ismember(dbP.param,upar{i});
    for j = 1:length(ugrp)
        ind = iind & ismember(dbP.group_id,ugrp{j});
        if isnan(dbP.paramF(ind))
            P.(upar{i}){j} = dbP.paramS(ind);
        else
            P.(upar{i})(j) = dbP.paramF(ind);
        end
    end
end
if ~isempty(P), P.group_id = ugrp; end