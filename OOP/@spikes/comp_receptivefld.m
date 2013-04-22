function [rfld,pars] = comp_receptivefld(obj,ax,unitid,parid,win)
% [rfld,pars] = comp_receptivefld(obj,ax,unitid,parid,win)
%
% Compute 2D receptive field of spikes object

if length(parid) ~= 2
    error('comp_receptivefld:Must include 2 parameter ids')
end

if isempty(ax), ax = gca; end

[raster,rpars] = comp_raster(obj,unitid,parid,win);

c = cellfun(@cell2mat,raster,'UniformOutput',false);
c = cellfun(@length,c,'UniformOutput',true);

upars1 = unique(rpars(:,1));
upars2 = unique(rpars(:,2));

rfld = reshape(c,length(upars1),length(upars2));
pars = {upars1, upars2};

