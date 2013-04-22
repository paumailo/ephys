function h = plot_raster(obj,ax,unitid,parid,parval,win)
% h = plot_raster(obj,ax,unitid,parid,parval,win)

if isempty(ax), ax = gca; end

[raster,pars] = comp_raster(obj,unitid,parid,parval,win);

% cla(ax);
% axes(ax);

if ~isempty(raster)
    raster = raster{1};
    lr = cellfun(@length,raster,'UniformOutput',true);
    fr = find(lr);
    rm = cellfun(@repmat,num2cell(fr),num2cell(lr(fr)),num2cell(ones(size(fr))),'UniformOutput',false);
    X = cell2mat(raster);
    Y = cell2mat(rm);
    h = plot(ax,X,Y,'sk','markersize',1,'markerfacecolor','k');
    set(ax,'ylim',[1 length(raster)]);
end
set(ax,'xlim',win,'ydir','reverse'); % flip y-axis so first trial is on top
box(ax,'on');
ylabel(ax,'trial');
xlabel(ax,'time (s)');

