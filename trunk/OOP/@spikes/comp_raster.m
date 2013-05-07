function data = comp_raster(obj,cfg)
% data = comp_raster(unitid,cfg)
%
% Computes rasters for each stimulus presentation based on
% whatever number of parameters (PARID) is specified. WIN is
% the onset and offset window around the stimulus onset (eg,
% [-0.01 0.2]).

% Check input------------------
reqflds = {'unitid','parid','parval','win'};
reqvald = {@ismatrix,@ismatrix,@ismatrix,@(x) isnumeric(x) & length(x)==2};
pcfg = cfgcheck(cfg,reqflds,reqvald);
%-----------------------------

if ischar(pcfg.parid), pcfg.parid = cellstr(pcfg.parid); end
if iscellstr(pcfg.parid)
    pcfg.parstr = {obj.params.event};
    pcfg.parid  = find(ismember(pcfg.parstr,pcfg.parid));
end

ts = unit_timestamps(obj,pcfg.unitid);

ind = true(size(obj.params(pcfg.parid(1)).vals,1),1);
for i = 1:length(pcfg.parid)
    ind = ismember(obj.params(pcfg.parid(i)).vals(:,1),pcfg.parval(i)) & ind;
end
vals = [obj.params(pcfg.parid).vals];
vals = vals(ind,1:4:end);
nvals = size(vals,1);

ons = obj.params(pcfg.parid(1)).vals(ind,2);
ofs = ons + pcfg.win(2);
irast = cell(length(ons),1);
for i = 1:length(ons)
    irast{i} = ts(ts >= ons(i) + pcfg.win(1) & ts < ofs(i))-ons(i);
end

p = obj.permutepars(pcfg.parid);
raster = cell(size(p,1),1);
for i = 1:size(p,1)
    ind = all(vals == repmat(p(i,:),nvals,1),2);
    raster{i} = irast(ind);
end

validpars = ~cellfun(@isempty,raster,'uniformoutput',true);
raster = raster(validpars);
pcfg.params = p(validpars,:);

data.raster = raster;
data.cfg = pcfg;


