function ind = subset(obj,ids)
% Returns logical indexes in an array pointing to a subset of
% data.
%
% Can enter one or multiple unit ids (in an array) or unit
% strings (in a cell array) which will search on unitstr field.
%
% Alternatively, the channel number and sortcode can be passed
% in as two parameters.  eg, ind = subset(3,2); would return
% logical indexing of unit 2 on channel 3.

if ischar(ids), ids = cellstr(ids); end

if length(ids) == 1 && iscellstr(ids)
    ids = find(ismember(obj.unitstr,ids));
end

if length(ids) == 1
    ind = obj.units == ids(1);
elseif length(ids) == 2
    ind = obj.channels == ids(2) & obj.sortcode == ids(2);
end
