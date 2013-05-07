function H = comp_hist(obj,cfg)

% Check input------------------
reqflds = {'unitid','parid','parval','win'};
reqvald = {@ismatrix,@ismatrix,@ismatrix,@(x) isnumeric(x) & length(x)==2};
optflds = {'binvec'};
optdeft = {0:0.001:0.2};
opttype = {@isvector};
pcfg = cfgcheck(cfg,reqflds,reqvald,optflds,optdeft,opttype);
%------------------------------

pcfg.win = pcfg.binvec([1 end]);
data = comp_raster(obj,pcfg);

if isempty(data.raster)
    H = [];
    return
end

raster = data.raster{1};
tH = cellfun(@histc,raster,repmat({pcfg.binvec},size(raster)),'UniformOutput',false);
H = cellfun(@(x) x(:),tH,'UniformOutput',false);
H = cell2mat(H');

H.cfg = pcfg;

