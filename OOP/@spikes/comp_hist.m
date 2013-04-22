function [h,pars] = comp_hist(obj,unitid,parid,parval,binvec)
% [h,pars] = comp_hist(obj,unitid,parid,parval,binvec)

win = [binvec(1) binvec(end)];
[raster,pars] = comp_raster(obj,unitid,parid,parval,win);

if isempty(raster)
    h = [];
    return
end

raster = raster{1};
h = cellfun(@histc,raster,repmat({binvec},size(raster)),'UniformOutput',false);
h = cellfun(@(x) x(:),h,'UniformOutput',false);
h = cell2mat(h');
