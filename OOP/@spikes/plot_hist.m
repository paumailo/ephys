function h = plot_hist(obj,cfg,H)
% h = plot_hist(obj,cfg)
% h = plot_hist(obj,cfg,H)

% Check input------------------
optflds = {'ax','facealpha','facecolor','linewidth','linecolor', ...
    'binvec','krnldur','krnlfcn'};
optdeft = {gca,0.6,[0.6 0.6 0.6],2,'k', ...
    0:0.001:0.2,0.005,@gausswin};
opttype = {@ishandle,@isscalar,@ismatrix,@isscalar,@ismatrix, ...
    @isvector,@isscalar,@(x)isa(x,'function_handle')};

if nargin < 3
%     reqflds = {'unitid','parid','parval','win'};
%     reqvald = {@ismatrix,@ismatrix,@ismatrix,@(x) isnumeric(x) & length(x)==2};
    H = comp_hist(obj,cfg);
end
pcfg = cfgcheck(cfg,[],[],optflds,optdeft,opttype);
%------------------------------


ax = pcfg.ax;
h = bar(ax,pcfg.binvec,mean(H,2),'k');
axis(ax,'tight');
grid(ax,'on');
box(ax,'on');





