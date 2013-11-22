function RIF_mdanalysis(unit_id)
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

defaults.respwin = [0 0.1];
defaults.viewwin = [-0.025 0.1];
defaults.prewin  = [-0.025 0];
defaults.binsize = 0.001;
settings = getpref('RIF_mdanalysis','settings',defaults);

h = InitGUI(settings);
set(h.figure,'Name',sprintf('Unit ID: %d',unit_id),'units','normalized');

h.RIF.P  = DB_GetParams(unit_id,'unit');
h.RIF.st = DB_GetSpiketimes(unit_id);

guidata(h.figure,h);

UpdateFig([],[],h.figure);

function h = InitGUI(settings)
f = findobj('tag','RF_FreqVsTime');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'tag','RF_FreqVsTime');
end
figure(f);
clf(f);

h.figure = f;
h.mainax = axes('position',[0.1  0.1  0.4 0.7]);
h.ioax   = axes('position',[0.65 0.1  0.3 0.3]);
h.latax  = axes('position',[0.65 0.5  0.3 0.3]);

fbc = get(f,'color');

h.viewwin = uicontrol(f,'Style','edit','String',mat2str(settings.viewwin), ...
    'units','normalized','Position',[0.38 0.91 0.2 0.025], ...
    'Callback',{@UpdateFig,f},'Tag','viewwin','FontSize',10);
uicontrol(f,'Style','text','String','View Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.91 0.35 0.025], ...
    'BackgroundColor',fbc,'FontSize',12);

h.prewin = uicontrol(f,'Style','edit','String',mat2str(settings.prewin), ...
    'units','normalized','Position',[0.38 0.88 0.2 0.025], ...
    'Callback',{@UpdateFig,f},'Tag','respwin','FontSize',10);
uicontrol(f,'Style','text','String','Baseline Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.88 0.35 0.025], ...
    'BackgroundColor',fbc,'FontSize',12);

h.respwin = uicontrol(f,'Style','edit','String',mat2str(settings.respwin), ...
    'units','normalized','Position',[0.38 0.85 0.2 0.025], ...
    'Callback',{@UpdateFig,f},'Tag','respwin','FontSize',10);
uicontrol(f,'Style','text','String','Response Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.85 0.35 0.025], ...
    'BackgroundColor',fbc,'FontSize',12);

h.updatedb = uicontrol(f,'Style','pushbutton','String','Update DB', ...
    'units','normalized','Position',[0.65 0.85 0.25 0.08], ...
    'Callback',{@UpdateDB,f},'Tag','updatedb','Fontsize',14);


function UpdateDB(hObj,event,f) %#ok<INUSL>
h = guidata(f);
do = findobj(f,'enable','on');
set(do,'enable','off');
drawnow

data = get(f,'UserData');

A = data.A;



set(do,'enable','on');

function UpdateFig(hObj,event,f) %#ok<INUSL>
h = guidata(f);

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

A = PSTHstats(cpsth,vals{1},'prewin',bwin, 'rspwin',rwin,'alpha',0.001);

cla([h.mainax h.ioax h.latax]);

PlotRaster(h.mainax,h.RIF.st,h.RIF.P.VALS,vwin);
PlotPSTH(h.mainax,cpsth,vals,A);
PlotIO(h.ioax,A,vals{2})
PlotLatency(h.latax,A,vals{2})


data.psth  = psth;
data.cpsth = cpsth;
data.A     = A;
data.vals  = vals;
set(h.figure,'UserData',data);

settings.respwin = str2num(get(h.respwin,'String'));
settings.viewwin = str2num(get(h.viewwin,'String'));
settings.prewin  = str2num(get(h.prewin,'String'));
settings.binsize = 0.001;
setpref('RIF_mdanalysis','settings',settings);


function PlotPSTH(ax,psth,vals,A)
axes(ax);

hold(ax,'on');
mdv = max(diff(vals{2}));
mpsth = max(psth(:));
spsth = psth/mpsth*mdv;
for i = 1:size(psth,2)
    yoffset = vals{2}(i);
    
    if ~isnan(A.response.rejectnullh(i)) && A.response.rejectnullh(i)
        c = [0 0 0];
    else
        c = [0.6 0.6 0.6];
    end
    plot(vals{1},yoffset+spsth(:,i),'-','color',c,'linewidth',2);
    
    if ~isnan(A.peak.rejectnullh(i)) && A.peak.rejectnullh(i)
        peakmag = A.peak.magnitude(i);
        plot(A.peak.latency(i),yoffset+peakmag/mpsth*mdv,'*r');
    end
    
    if ~isnan(A.response.rejectnullh(i)) && A.response.rejectnullh(i)
        plot([A.onset.pk10(i) A.offset.pk10(i)],yoffset+peakmag*[0.10 0.10]/mpsth*mdv,'-r', ...
             [A.onset.pk50(i) A.offset.pk50(i)],yoffset+peakmag*[0.50 0.50]/mpsth*mdv,'-g', ...
             [A.onset.pk90(i) A.offset.pk90(i)],yoffset+peakmag*[0.90 0.90]/mpsth*mdv,'-b', ...
             'linewidth',2);
    end
    plot(vals{1}([1 end]),[yoffset yoffset],'-','color',[0.3 0.3 0.3],'linewidth',0.5);
end
ylim([vals{2}(1) vals{2}(end)+max(diff(vals{2}))]);
plot(ax,[0 0],ylim(ax),'-k');

hold(ax,'off');
box(ax,'on');

xlabel('Time (s)','FontSize',14);
ylabel('Level (dB)','FontSize',14);

ud.psth = psth;
ud.vals = vals;
set(ax,'userdata',ud);



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
set(ax,'UserData',d,'clipping','off');
xlim(win); ylim([uL(1) uL(end)+dL]);



function PlotIO(ax,A,x)
axes(ax);
ip = A.peak.rejectnullh;
ir = A.response.rejectnullh;
plot(ax,x(ip),A.peak.magnitude(ip),'-*k', ...
        x(ir),A.response.magnitude(ir),'-ok');
xlabel(ax,'Level (dB)','FontSize',10)
ylabel(ax,'Firing Rate (Hz)','FontSize',10)
mdx = mean(diff(x));
xlim(ax,[x(1)-mdx x(end)+mdx]);

function PlotLatency(ax,A,x)
axes(ax);
ip = A.peak.rejectnullh;
ir = A.response.rejectnullh;
plot(ax,x(ip),A.peak.latency(ip)*1000,'-*r', ...
        x(ir),A.onset.pk10(ir)*1000,'-or', ...
        x(ir),A.onset.pk50(ir)*1000,'-og', ...
        x(ir),A.onset.pk90(ir)*1000,'-ob', ...
        x(ir),A.offset.pk10(ir)*1000,'-+r', ...
        x(ir),A.offset.pk50(ir)*1000,'-+g', ...
        x(ir),A.offset.pk90(ir)*1000,'-+b')
xlabel(ax,'Level (dB)','FontSize',10)
ylabel(ax,'Latency (ms)','FontSize',10)
ylim(ax,[0 max(A.offset.pk10)*1000+5]);
mdx = mean(diff(x));
xlim(ax,[x(1)-mdx x(end)+mdx]);


















