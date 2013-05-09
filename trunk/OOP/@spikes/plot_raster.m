function varargout = plot_raster(obj,cfg)
% plot_raster(obj,cfg)
% h = plot_raster(obj,cfg)
% [h,data] = plot_raster(obj,cfg)

% Check input------------------
reqflds = {'unitid','parid','parval'};
reqvald = {@(x) isscalar(x)|ischar(x),@(x) isscalar(x)|ischar(x),@ismatrix};
optflds = {'axes','win','marker','markeredgecolor','markerfacecolor','markersize'};
optdeft = {gca,[0 0.1],'s','k','k',2};
opttype = {@ishandle,@(x) isnumeric(x)&length(x)==2,@ischar,@(x) ischar(x)|length(x)==3,@(x) ischar(x)|length(x)==3,@isscalar};
pcfg = cfgcheck(cfg,reqflds,reqvald,optflds,optdeft,opttype);
%-----------------------------

data = comp_raster(obj,pcfg);

if ~isempty(data)
    for j = 1:size(data.raster,2) % channels
        cr = data.raster{:,j};
        lr = cellfun(@length,cr,'UniformOutput',true);
        fr = find(lr);
        rm = cellfun(@repmat,num2cell(fr),num2cell(lr(fr)),num2cell(ones(size(fr))),'UniformOutput',false);
        X = cell2mat(cr);
        Y = cell2mat(rm);
        h = plot(pcfg.axes,X,Y,'linestyle','none', ...
            'markersize',pcfg.markersize, 'markeredgecolor',pcfg.markeredgecolor, ...
            'markerfacecolor',pcfg.markerfacecolor,'marker',pcfg.marker);
        set(pcfg.axes,'ylim',[1 length(cr)]);
        hold(pcfg.axes,'on');
    end
    hold(pcfg.axes,'off');
end
set(pcfg.axes,'xlim',pcfg.win,'ydir','reverse'); % flip y-axis so first trial is on top
box(pcfg.axes,'on');
ylabel(pcfg.axes,'trial');
xlabel(pcfg.axes,'time (s)');

varargout{1} = h;
varargout{2} = data;