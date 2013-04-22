function ts = unit_timestamps(obj,unitid)
% ts = unit_timestamps(obj,unitid)
%
% Returns timestamps of one or multiple units of the current
% block.  If one unit is passed in then an Nx1 vector of the
% unit's time stamps (relative to recording onset) is returned.
%  If an array of units are passed in, then a cell array of Nx1
%  vector of unit timestamps are returned.  If unitid == 0,
%  then all units of the current block will be returned in a
%  cell array.


if length(unitid) == 1 && unitid == 0
    unitid = unique(obj.units);
end

if length(unitid) == 1
    ind = subset(obj,unitid);
    ts = obj.timestamps(ind);
elseif length(unitid) > 1
    ts = cell(length(unitid),1);
    for i = 1:length(unitid)
        ind = subset(obj,unitid(i));
        ts{i,1} = obj.timestamps(ind);
    end
end
