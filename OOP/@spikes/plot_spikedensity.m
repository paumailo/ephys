function h = plot_spikedensity(obj,cfg,SD)
% h = plot_spikedensity(obj,cfg)
% h = plot_spikedensity(obj,cfg,SD)
%
%
% ----- required -----
% unitid ... unit id as a unit id in obj.units or a string from obj.unitstr
% parid  ... parameter id(s) as an index from obj.params or an event name or
%               names
% parval ... parameter value(s) corresponding to obj.params.uvals
%               - there should be a parval correspondind to each parid
% win    ... window to view data as [onset offset], eg: [-0.025 0.2] (in seconds)
%
% ----- optional -----
% ax        ... handle of axis to plot on
% linecolor ... see linespec
% bandcolor ... color of confidence interval or error bands behind mean
%
% DJS 2013


% Check input------------------
optflds = {'ax','facealpha','facecolor','linewidth','linecolor', ...
    'binvec','krnldur','krnlfcn'};
optdeft = {gca,0.6,[0.6 0.6 0.6],2,'k', ...
    0:0.001:0.2,0.005,@gausswin};
opttype = {@ishandle,@isscalar,@ismatrix,@isscalar,@ismatrix, ...
    @isvector,@isscalar,@(x)isa(x,'function_handle')};
if nargin < 3
    reqflds = {'unitid','parid','parval','win'};
    reqvald = {@ismatrix,@ismatrix,@ismatrix,@(x) isnumeric(x) & length(x)==2};
    SD = comp_spikedensity(obj,cfg);
else
    reqflds = [];
    reqvald = [];
end
pcfg = cfgcheck(cfg,reqflds,reqvald,optflds,optdeft,opttype);


%------------------------------

ax = pcfg.ax;

tvec = linspace(SD.cfg.win(1),SD.cfg.win(2),length(SD.mean))';
x = [tvec; flipud(tvec)];
% y = [SD.mean + SD.sem; flipud(SD.mean - SD.sem)];
y = [SD.norm.muci(1,:)'; flipud(SD.norm.muci(2,:)')];
fill(x,y,pcfg.facecolor,'FaceAlpha',pcfg.facealpha, ...
         'LineStyle','none','Parent',ax);
hold(ax,'on');
plot(ax,tvec,SD.mean,'linewidth',pcfg.linewidth,'color',pcfg.linecolor);
hold(ax,'off');

axis(ax,'tight');
grid(ax,'on');
box(ax,'on');

xlabel(ax,'time (s)');
ylabel(ax,'amplitude');







