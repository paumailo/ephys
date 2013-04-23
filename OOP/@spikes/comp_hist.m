function [H,pars,tH] = comp_hist(obj,unitid,parid,parval,binvec)
% [H,pars,tH] = comp_hist(obj,unitid,parid,parval)
% [H,pars,tH] = comp_hist(obj,unitid,parid,parval,binvec)

if nargin < 5, binvec = 0:0.001:0.2; end

win = [binvec(1) binvec(end)];
[raster,pars] = comp_raster(obj,unitid,parid,parval,win);

if isempty(raster)
    H = [];
    return
end

raster = raster{1};
tH = cellfun(@histc,raster,repmat({binvec},size(raster)),'UniformOutput',false);
H = cellfun(@(x) x(:),tH,'UniformOutput',false);
H = cell2mat(H');
