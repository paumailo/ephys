function f = RIF_mdanalysis(unit_id)
% RIF_mdanalysis
% RIF_mdanalysis(unit_id)
%
% Rate-Intensity Function analysis.
%
% See also, RF_analysis
% 
% Daniel.Stolzberg@gmail.com 2013

if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

defaults.respwin    = [0 0.1];
defaults.viewwin    = [-0.025 0.1];
defaults.prewin     = [-0.025 0];
defaults.binsize    = 0.001;
defaults.showraster = 1;
defaults.showhist   = 1;
defaults.figpos     = get(gcf,'position');
settings = getpref('RIF_mdanalysis','settings',defaults);


onstr  = cellstr(num2str((10:20:90)','onset%dpk'))';
offstr = cellstr(num2str((10:20:90)','offset%dpk'))';

ondstr  = strtrim(cellstr(num2str((10:20:90)','Onset latency at %d%% of peak firing rate')))';
offdstr = strtrim(cellstr(num2str((10:20:90)','Offset latency at %d%% of peak firing rate')))';

name = [onstr, offstr, {'ci', 'p', 'peakfr', 'bestlevel','magnitude','rejectnullh','latency','maxmag','bestlevel','monotonicity','yintercept'}];
unit = [cellstr(repmat('sec',10,1))', {[], [], 'Hz', 'dB', [], [],'sec','Hz','dB','Hz/dB','Hz'}];
desc = [ondstr, offdstr, {'Confidence Interval', 'Statistical P-Value', 'Peak Firing Rate', ...
    'Best Response Level', 'Magnitude of response', 'Reject Null Hypothesis','Response latency','Maximum response magnitude','Best Response Level','Monotonicity', ...
    'Y-Intercept'}];
DB_CheckAnalysisParams(name,desc,unit);


h = InitGUI(settings);
set(h.figure,'Name',sprintf('Unit ID: %d',unit_id),'units','normalized');

h.unit_id = unit_id;
h.RIF.P  = DB_GetParams(unit_id,'unit');
h.RIF.st = DB_GetSpiketimes(unit_id);

guidata(h.figure,h);

UpdateFig([],[],false,h.figure);

f = h.figure;

function h = InitGUI(settings)
f = findobj('tag','RIF_mdanalysis');
if isempty(f)
    f = figure('Color',[0.98 0.98 0.98],'tag','RIF_mdanalysis',...
        'units','normalized','Position',settings.figpos);
end
figure(f);
clf(f);
set(f,'ToolBar','figure');
h.figure = f;

h.mainax = axes('position',[0.1  0.05  0.45 0.73],'tag','main');
h.ioax   = axes('position',[0.65 0.05  0.3 0.35],'tag','io');
h.latax  = axes('position',[0.65 0.45  0.3 0.35],'tag','latency');

fbc = get(f,'color');

h.viewwin = uicontrol(f,'Style','edit','String',mat2str(settings.viewwin), ...
    'units','normalized','Position',[0.38 0.95 0.2 0.025], ...
    'Callback',{@UpdateFig,false,f},'Tag','viewwin','FontSize',10,'BackgroundColor','w');
uicontrol(f,'Style','text','String','View Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.95 0.35 0.025],'BackgroundColor',fbc,'FontSize',12);

h.prewin = uicontrol(f,'Style','edit','String',mat2str(settings.prewin), ...
    'units','normalized','Position',[0.38 0.92 0.2 0.025], ...
    'Callback',{@UpdateFig,false,f},'Tag','respwin','FontSize',10,'BackgroundColor','w');
uicontrol(f,'Style','text','String','Baseline Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.92 0.35 0.025],'BackgroundColor',fbc,'FontSize',12);

h.respwin = uicontrol(f,'Style','edit','String',mat2str(settings.respwin), ...
    'units','normalized','Position',[0.38 0.89 0.2 0.025], ...
    'Callback',{@UpdateFig,false,f},'Tag','respwin','FontSize',10,'BackgroundColor','w');
uicontrol(f,'Style','text','String','Response Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.89 0.35 0.025],'BackgroundColor',fbc,'FontSize',12);

h.show_hist = uicontrol(f,'Style','checkbox','String','Show Histogram', ...
    'units','normalized','Position',[0.15 0.86 0.3 0.025], ...
    'Callback',{@UpdateFig,true,f},'Tag','show_hist','FontSize',10, ...
    'BackgroundColor',fbc,'value',settings.showhist);

h.show_raster = uicontrol(f,'Style','checkbox','String','Show Raster', ...
    'units','normalized','Position',[0.35 0.86 0.2 0.025], ...
    'Callback',{@UpdateFig,true,f},'Tag','show_raster','FontSize',10, ...
    'BackgroundColor',fbc,'value',settings.showraster);

h.updatedb = uicontrol(f,'Style','pushbutton','String','Update DB', ...
    'units','normalized','Position',[0.65 0.90 0.25 0.08], ...
    'Callback',{@UpdateDB,f},'Tag','updatedb','Fontsize',14);

h.response_threshold = uicontrol(f,'Style','pushbutton','String','Response Threshold', ...
    'units','normalized','Position',[0.65 0.86 0.2 0.025], ...
    'Callback',{@ResponseThreshold,f},'Tag','response_threshold','Fontsize',8);

h.resptranspoint = uicontrol(f,'Style','pushbutton','String','Response Trans Pnt', ...
    'units','normalized','Position',[0.65 0.83 0.15 0.025], ...
    'Callback',{@TransPoint,'response',f},'Tag','resptranspoint','Fontsize',8);

h.peaktranspoint = uicontrol(f,'Style','pushbutton','String','Peak Trans Pnt', ...
    'units','normalized','Position',[0.8 0.83 0.1 0.025], ...
    'Callback',{@TransPoint,'peak',f},'Tag','peaktranspoint','Fontsize',8);

h.adjonset50 = uicontrol(f,'Style','pushbutton','String','50% Onset', ...
    'units','normalized','Position',[0.15 0.83 0.1 0.025], ...
    'Callback',{@AdjustOnOff,f},'Tag','adjustonset','Fontsize',8,'UserData',{'on',50});

h.adjoffset50 = uicontrol(f,'Style','pushbutton','String','50% Offset', ...
    'units','normalized','Position',[0.26 0.83 0.1 0.025], ...
    'Callback',{@AdjustOnOff,f},'Tag','adjoffset','Fontsize',8,'UserData',{'off',50});

h.adjonset10 = uicontrol(f,'Style','pushbutton','String','10% Onset', ...
    'units','normalized','Position',[0.15 0.80 0.1 0.025], ...
    'Callback',{@AdjustOnOff,f},'Tag','adjustonset','Fontsize',8,'UserData',{'on',10});

h.adjoffset10 = uicontrol(f,'Style','pushbutton','String','10% Offset', ...
    'units','normalized','Position',[0.26 0.80 0.1 0.025], ...
    'Callback',{@AdjustOnOff,f},'Tag','adjoffset','Fontsize',8,'UserData',{'off',10});





%% User interaction
function TransPoint(hObj,event,type,f) %#ok<INUSL>
do = findobj(f,'enable','on');
set(do,'enable','off');
drawnow

UD = get(f,'UserData');
A = UD.A;



[x,~,b] = ginput(1);

ax = gca;

if b ~= 1 || ~any(strcmp(get(ax,'tag'),{'peakio','respio'}))
    set(do,'enable','on');
    return
end

levels = UD.vals{2};
xi = interp1(levels,1:length(levels),x,'nearest');
A.(type).features.transpoint = levels(xi);

if A.(type).features.transpoint == levels(end)
    p = polyfit(levels',A.(type).magnitude,1);
else
    p = polyfit(levels(xi:end)',A.(type).magnitude(xi:end),1);
end
A.(type).features.monotonicity = p(1);
A.(type).features.yintercept   = p(2);

fprintf('\t%s transition point = %d dB\n',type,A.(type).features.transpoint)
fprintf('\t%s monotonicity     = %0.3f Hz/dB\n',type,A.(type).features.monotonicity)

UD.A = A;
set(f,'UserData',UD);

UpdatePlots(f);

do = findobj(f,'enable','off');
set(do,'enable','on');

function ResponseThreshold(hObj,event,f) %#ok<INUSL>
do = findobj(f,'enable','on');
set(do,'enable','off');
drawnow

UD = get(f,'UserData');
A = UD.A;

[x,y,b] = ginput(1);

if b ~= 1
    set(do,'enable','on');
    return
end

ax = gca;
switch  get(ax,'tag')
    case 'main'
        dB = y;
        
    case {'peakio','respio'}
        dB = x;
        
    case 'latency'
        dB = y;
end

dBi = interp1(UD.vals{2},1:length(UD.vals{2}),dB,'nearest');
A.response.features.threshold = UD.vals{2}(dBi);

fprintf('\tNew threshold = %d dB\n',A.response.features.threshold);

UD.A = A;
set(f,'UserData',UD);

UpdatePlots(f);

do = findobj(f,'enable','off');
set(do,'enable','on');

function AdjustOnOff(hObj,event,f) %#ok<INUSL>
info = get(hObj,'UserData');
type = info{1};
level = info{2};

do = findobj(f,'enable','on');
set(do,'enable','off');
drawnow

UD = get(f,'UserData');
A = UD.A;

[x,y,b] = ginput(1);
ax = gca;
if b ~= 1 || ~strcmp(get(ax,'tag'),'main')
    set(do,'enable','on');
    return
end

label = sprintf('%sset%dpk',type,level);

y = interp1(UD.vals{2},1:length(UD.vals{2}),y,'nearest');
y = UD.vals{2}(y);
ind = A.levels == y;
A.response.(label)(ind) = x;

UD.A = A;
set(f,'UserData',UD);

UpdatePlots(f);

do = findobj(f,'enable','off');
set(do,'enable','on');













%%
function data = GenPSTH(h)
vwin = str2num(get(h.viewwin,'String')); %#ok<*ST2NM>
rwin = str2num(get(h.respwin,'String'));
bwin = str2num(get(h.prewin,'String'));
binsize = 0.001;

[psth,vals] = shapedata_spikes(h.RIF.st,h.RIF.P,{'Levl'}, ...
    'win',vwin,'binsize',binsize,'func',@mean);
psth = psth / binsize;

mp = max(psth(:));
v = window(@gausswin,5);
cpsth = zeros(size(psth));
for i = 1:size(psth,2)
    cpsth(:,i) = conv(psth(:,i),v,'same');
end
cpsth = cpsth / max(cpsth(:)) * mp;

A = PSTHstats(cpsth,vals{1},'levels',vals{2},'prewin',bwin,'rspwin',rwin,'alpha',0.001);

settings.respwin    = str2num(get(h.respwin,'String'));
settings.viewwin    = str2num(get(h.viewwin,'String'));
settings.prewin     = str2num(get(h.prewin,'String'));
settings.showraster = get(h.show_raster,'Value');
settings.showhist   = get(h.show_hist,'Value');
settings.binsize    = 0.001;
settings.figpos     = get(h.figure,'Position');
setpref('RIF_mdanalysis','settings',settings);

data.psth       = psth;
data.cpsth      = cpsth;
data.A          = A;
data.vals       = vals;
data.settings   = settings;
set(h.figure,'UserData',data);

function UpdateFig(hObj,event,keep,f) %#ok<INUSL>
h = guidata(f);

cla(h.mainax);
cla(h.ioax);
cla(h.latax);

UD = get(f,'UserData');

if isempty(UD) || ~keep
    UD = GenPSTH(h);
end

if ~keep && isfield(UD,'A') && isfield(UD.A,'levels')
    UD.A = GatherDBdata(h.unit_id,UD.A);
    if isempty(UD.A)
        UD = GenPSTH(h);
    end
    set(f,'UserData',UD);
end

UpdatePlots(f);

function UpdatePlots(f)
h = guidata(f);

UD = get(f,'UserData');

settings = UD.settings;

cla(h.mainax);
if get(h.show_raster,'Value')
    PlotRaster(h.mainax,h.RIF.st,h.RIF.P.VALS,settings.viewwin);
end
PlotPSTH(h.mainax,UD.cpsth,UD.vals,UD.A);
PlotIO(h.ioax,UD.A,UD.vals{2})
PlotLatency(h.latax,UD.A,UD.vals{2})












%% Database
function UpdateDB(hObj,event,f) %#ok<INUSL>
h = guidata(f);
do = findobj(f,'enable','on');
set(do,'enable','off');
drawnow


data = get(f,'UserData');

A = data.A;

R = A.response;

Rfeatures = R.features;
R = rmfield(R,'features');

R.level = strtrim(cellstr(num2str(data.vals{2},'Resp_%0.1fdB')));

if isfield(R,'stats'), R = rmfield(R,'stats'); end
R.ci = cellstr(num2str(R.ci'));
DB_UpdateUnitProps(h.unit_id,R,'level');


Rfeatures.group = 'ResponseFeature';
DB_UpdateUnitProps(h.unit_id,Rfeatures,'group');


R = A.peak;
Rfeatures = R.features;
R = rmfield(R,'features');
R.level = strtrim(cellstr(num2str(data.vals{2},'Peak_%0.1fdB')));
if isfield(R,'stats'), R = rmfield(R,'stats'); end
R.ci = cellstr(num2str(R.ci'));
DB_UpdateUnitProps(h.unit_id,R,'level');
Rfeatures.group = 'PeakFeature';
DB_UpdateUnitProps(h.unit_id,Rfeatures,'group');


set(do,'enable','on');

function B = GatherDBdata(unit_id,A)

RespLevel = strtrim(cellstr(num2str(A.levels,'Resp_%0.1fdB')));
PeakLevel = strtrim(cellstr(num2str(A.levels,'Peak_%0.1fdB')));

t = DB_GetUnitProps(unit_id,RespLevel{1});
if isempty(t), B = []; return; end

for i = 1:length(RespLevel)
    R(i) = DB_GetUnitProps(unit_id,RespLevel{i}); %#ok<AGROW>
    P(i) = DB_GetUnitProps(unit_id,PeakLevel{i}); %#ok<AGROW>
end

B.levels = A.levels;
B.peak.magnitude    = [P.magnitude];
B.peak.latency      = [P.latency];
B.peak.rejectnullh  = [P.rejectnullh];
B.peak.p            = [P.p];
B.peak.ci           = str2num(cell2mat([P.ci]'))';

B.response.magnitude    = [R.magnitude];
B.response.p            = [R.p];
B.response.rejectnullh  = [R.rejectnullh];
B.response.ci           = str2num(cell2mat([R.ci]'))';
for i = 10:20:90
    fn = sprintf('onset%dpk',i);
    B.response.(fn) = [R.(fn)];
    fn = sprintf('offset%dpk',i);
    B.response.(fn) = [R.(fn)];
end

Rf = DB_GetUnitProps(unit_id,'ResponseFeature');
B.response.features = rmfield(Rf,'group_id');

Pf = DB_GetUnitProps(unit_id,'PeakFeature');
B.peak.features = rmfield(Pf,'group_id');






%% Plots
function PlotPSTH(ax,psth,vals,A)
axes(ax);

showhist = findobj(gcf,'tag','show_hist');
showhist = get(showhist,'Value');

hold(ax,'on');
mdv = max(diff(vals{2}));
mpsth = max(psth(:));
spsth = psth/mpsth*mdv;
for i = 1:size(psth,2)
    yoffset = vals{2}(i);
    
    if ~isnan(A.response.rejectnullh(i)) && A.response.rejectnullh(i)
        c = [0 0 0];
    else
        c = [0.5 0.5 0.5];
    end
    
    if showhist
        plot(vals{1},yoffset+spsth(:,i),'-','color',c,'linewidth',2);
    end
    
    if ~isnan(A.peak.rejectnullh(i))
        peakmag = A.peak.magnitude(i);
        plot(A.peak.latency(i),yoffset+peakmag/mpsth*mdv,'*m');
    end
    
    if ~isnan(A.response.rejectnullh(i))
        plot([A.response.onset10pk(i) A.response.offset10pk(i)],yoffset+peakmag*[0.10 0.10]/mpsth*mdv,'-r', ...
             [A.response.onset50pk(i) A.response.offset50pk(i)],yoffset+peakmag*[0.50 0.50]/mpsth*mdv,'-g', ...
             'linewidth',2);
    end
    plot(vals{1}([1 end]),[yoffset yoffset],'-','color',[0.3 0.3 0.3],'linewidth',0.5);
end
xlim(vals{1}([1 end]));
ylim([vals{2}(1) vals{2}(end)+max(diff(vals{2}))]);
plot(ax,[0 0],ylim(ax),'-k');
plot(ax,xlim,A.response.features.threshold*[1 1],'-b','linewidth',2);

hold(ax,'off');
box(ax,'on');

xlabel('Time (s)','FontSize',10);
ylabel('Level (dB)','FontSize',10);

ud.psth = psth;
ud.vals = vals;
set(ax,'userdata',ud,'tag','main');

function PlotRaster(ax,st,vals,win)
axes(ax);

nreps = sum(vals.Levl == vals.Levl(1));
[L,idx] = sort(vals.Levl);
uL = unique(L);
dL = mean(diff(uL));
ons  = vals.onset(idx);
wons = ons + win(1);
wofs = ons + win(2);
rast = cell(size(ons));
for i = 1:length(ons)
    sind = st >= wons(i) & st <= wofs(i);
    rast{i} = st(sind) - ons(i);
end

hold(ax,'on');

for i = 1:length(rast)
    if isempty(rast{i}), continue; end
    md = mod(i,nreps)/nreps*dL;
    plot(rast{i},L(i) + md,'s','color',[0.3 0.3 0.3], ...
        'markersize',1,'markerfacecolor',[0.3 0.3 0.3]);
end

plot(repmat(win,length(uL),1)',[uL uL]','-k');
plot([0 0],[uL(1) uL(end)+dL],'-','color',[0.3 0.3 0.3]);

hold(ax,'off');
box(ax,'on');
d.rast = rast;
d.vals = L;
set(ax,'UserData',d,'clipping','off','tag','main');
xlim(win); ylim([uL(1) uL(end)+dL]);

function PlotIO(ax,A,x)
axes(ax);

[yyax,h1,h2] = plotyy(ax,x,A.peak.magnitude,x,A.response.magnitude);

% peak IO
set(h1,'marker','*','color','m')
set(yyax(1),'ycolor','m')

hold(yyax(1),'on')
plot(yyax(1),A.peak.features.bestlevel,A.peak.features.maxmag,'om', ...
    'markerfacecolor','m');

if isfield(A.peak.features,'transpoint')
    p = [A.peak.features.monotonicity A.peak.features.yintercept];
    y = polyval(p,[A.peak.features.transpoint x(end)]);
    plot(yyax(1),[A.peak.features.transpoint x(end)],y,'-r','linewidth',2);
    i = A.peak.features.transpoint == A.levels;
    plot(yyax(1),A.peak.features.transpoint,A.peak.magnitude(i),'xm', ...
        'linewidth',3,'markersize',12);
end
hold(yyax(1),'off')

% response IO
set(h2,'marker','o','color','k');
set(yyax(2),'ycolor','k')

hold(yyax(2),'on')
plot(yyax(2),A.response.features.bestlevel,A.response.features.maxmag,'ok', ...
    'markerfacecolor','k');

thresh = A.response.features.threshold;
plot(yyax(2),thresh*[1 1],ylim,'-b');

if isfield(A.response.features,'transpoint')
    p = [A.response.features.monotonicity A.response.features.yintercept];
    y = polyval(p,[A.response.features.transpoint x(end)]);
    plot(yyax(2),[A.response.features.transpoint x(end)],y,'-r','linewidth',2);
    i = A.response.features.transpoint == A.levels;
    plot(yyax(2),A.response.features.transpoint,A.response.magnitude(i),'xk', ...
        'linewidth',3,'markersize',12);
end

hold(yyax(2),'off')

xlabel(yyax(1),'Level (dB)','FontSize',8)
ylabel(yyax(1),'Firing Rate (Hz)','FontSize',8)
mdx = mean(diff(x));
set(yyax,'xlim',[x(1)-mdx x(end)+mdx]);
h(1) = legend(yyax(1),{'Peak'},'location','northwest');
h(2) = legend(yyax(2),{'Response'},'location','southeast');
set(h(1),'FontSize',6,'box','off');
set(h(2),'FontSize',6,'box','off');
set(yyax(1),'tag','peakio');
set(yyax(2),'tag','respio');

function PlotLatency(ax,A,x)
axes(ax);

plot(ax,A.response.onset50pk*1000,x,'-+g', ...
        A.response.offset50pk*1000,x,'-og', ...
        A.response.onset10pk*1000,x,'-+r', ...
        A.response.offset10pk*1000,x,'-or', ...
        A.peak.latency*1000,x,'-*m');
    
hold(ax,'on');

thresh = A.response.features.threshold;
plot(ax,xlim,thresh*[1 1],'-b');

hold(ax,'off');
    
ylabel(ax,'Level (dB)','FontSize',8)
xlabel(ax,'Latency (ms)','FontSize',8)
xlim(ax,[0 max(A.response.offset10pk)*1000+5]);
mdx = mean(diff(x));
ylim(ax,[x(1)-mdx x(end)+mdx]);
h = legend(ax,{'50% Onset','50% Offset','10% Onset','10% Offset','Peak'},'location','northeast');
set(h,'FontSize',6,'box','off');
set(ax,'tag','latency');















