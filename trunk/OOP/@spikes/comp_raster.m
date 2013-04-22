function [raster,pars] = comp_raster(obj,unitid,parid,parval,win)
% [raster,pars] = comp_raster(unitid,parid,parval,win)
%
% Computes rasters for each stimulus presentation based on
% whatever number of parameters (PARID) is specified. WIN is
% the onset and offset window around the stimulus onset (eg,
% [-0.01 0.2]).

if nargin < 5 || length(win) ~= 2
    error('comp_raster:The win input must be specified as a 2 value matrix')
end

if ischar(parid), parid = cellstr(parid); end
if iscellstr(parid)
    parstr = {obj.params.event};
    parid  = find(ismember(parstr,parid));
end

ts = unit_timestamps(obj,unitid);

ind = true(size(obj.params(parid(1)).vals,1),1);
for i = 1:length(parid)
    ind = ismember(obj.params(parid(i)).vals(:,1),parval(i)) & ind;
end
vals = [obj.params(parid).vals];
vals = vals(ind,1:4:end);
nvals = size(vals,1);

ons = obj.params(parid(1)).vals(ind,2);
ofs = ons + win(2);
irast = cell(length(ons),1);
for i = 1:length(ons)
    irast{i} = ts(ts >= ons(i) + win(1) & ts < ofs(i))-ons(i);
end

p = obj.permutepars(parid);
raster = cell(size(p,1),1);
k = 1;
for i = 1:size(p,1)
    ind = all(vals == repmat(p(i,:),nvals,1),2);
    raster{k} = irast(ind);
    k = k + 1;
end

validpars = ~cellfun(@isempty,raster,'uniformoutput',true);
raster = raster(validpars);
pars = p(validpars,:);
