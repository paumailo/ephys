function RF_FreqVsTime(unit_id)
%%

if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

f = findobj('tag','RF_FreqVsTime');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'tag','RF_FreqVsTime');
end
figure(f);
clf(f);
set(f,'Name',sprintf('Unit ID: %d',unit_id),'units','normalized');

h.RF.P = DB_GetParams(unit_id,'unit');
h.RF.st = DB_GetSpiketimes(unit_id);

guidata(f,h);

h = creategui(f);

UpdateFig(h.LevelList,'init',f)




function h = creategui(f)
h = guidata(f);

rfwin = [0 50]; % receptive field plot
rwin  = [0 150]; % raster plot

L = h.RF.P.lists.Levl;
level = max(L);

opts = getpref('RF_FreqVsTime',{'rfwin','rwin','level'},{rfwin,rwin,level});

rfwin = opts{1};
rwin  = opts{2};
level = opts{3};

ind = level == L;
if ~any(ind), ind = L == max(L); end
h.LevelList = uicontrol(f,'Style','popup','String',L,'Value',find(ind), ...
    'units','normalized','Position',[0.3 0.86 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','LevelList');
fbc = get(f,'Color');
uicontrol(f,'Style','text','String','Level (dB):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.86 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.rwin = uicontrol(f,'Style','edit','String',mat2str(rwin), ...
    'units','normalized','Position',[0.3 0.80 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','rwin');
uicontrol(f,'Style','text','String','Raster Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.80 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.rfwin = uicontrol(f,'Style','edit','String',mat2str(rfwin), ...
    'units','normalized','Position',[0.3 0.74 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','rfwin');
uicontrol(f,'Style','text','String','RF Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.74 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


guidata(f,h);

function UpdateFig(hObj,event,f) %#ok<INUSL>
h = guidata(f);

s = cellstr(get(h.LevelList,'String'));
level = str2num(s{get(h.LevelList,'Value')}); %#ok<ST2NM>
rwin  = str2num(get(h.rwin,'String')); %#ok<ST2NM>
rfwin = str2num(get(h.rfwin,'String')); %#ok<ST2NM>

% receptive field
[rfdata,rfvals] = shapedata_spikes(h.RF.st,h.RF.P,{'Freq','Levl'}, ...
    'win',rfwin/1000,'binsize',0.001,'func','sum');
plotrf(rfdata*1000,rfvals);
   
subplot(322)
hold on
set(gca,'clipping','off');
x = xlim(gca);
z = zlim(gca);
po = patch([x fliplr(x)],ones(1,4)*level,[z(1) z(1) z(2) z(2)]);
set(po,'zdata',[z(1) z(1) z(2) z(2)],'facecolor','w','facealpha',0.5, ...
    'edgecolor','w','edgealpha',0.5)
hold off
    
% raster
rast = genrast(h.RF.st,h.RF.P,level,rwin/1000);
plotraster(h.RF.P,rast,rwin,level);

setpref('RF_FreqVsTime',{'rfwin','rwin','level'},{rfwin,rwin,level});


function plotrf(data,vals)
%% Plot Receptive Field
subplot(3,2,2,'replace')
cla

x = vals{2};
y = vals{3};

data = squeeze(mean(data));
data = sgsmooth2d(data);
data = interp2(data,3,'cubic');

ny = length(y);
nx = length(x);
x = interp1(logspace(log10(1),log10(nx),nx),x,logspace(log10(1),log10(nx),size(data,1)),'pchip');
y = interp1(y,linspace(1,ny,size(data,2)),'linear');

hax = surf(x/1000,y,data');
shading flat
view(2)
axis tight
md = max(data(:));
if isnan(md) || md == 0, md = 1; end
set(gca,'xscale','log','fontsize',7,'xtick',[1 5 10 50],'xticklabel',[1 5 10 50], ...
    'zlim',[0 md])
set(hax,'ButtonDownFcn',{@clickrf,gcf});
xlabel('Frequency (kHz)','fontsize',7)
ylabel('Level (dB)','fontsize',7)
h = colorbar('EastOutside','fontsize',7);
c = get(gca,'clim');
set(gca,'clim',[0 c(2)]);
ylabel(h,'Firing Rate (Hz)','fontsize',7)


function clickrf(hObj,event,f) %#ok<INUSL>
h = guidata(hObj);
cp = get(gca,'CurrentPoint');
level = cp(1,2);
L = str2num(get(h.LevelList,'String')); %#ok<ST2NM>
i = interp1(L,1:length(L),level,'nearest');
if isempty(i) || isnan(i), return; end
set(h.LevelList,'Value',i);
UpdateFig(h.LevelList,'clickrf',f)

function rast = genrast(st,P,level,win)
%%
ind = P.VALS.Levl == level;
ons = P.VALS.onset(ind) + win(1);
ofs = P.VALS.onset(ind) + win(2);
rast = cell(size(ons));
for i = 1:length(ons)
    sind = st >= ons(i) & st <= ofs(i);
    rast{i} = st(sind) - ons(i);
end
f = P.VALS.Freq(ind);
[~,i] = sort(f);
rast = rast(i);

function plotraster(P,rast,win,level)
%% Plot Raster
subplot(3,2,[3 6],'replace')
cla

rast = cellfun(@(a) (a*1000),rast,'UniformOutput',false); % s -> ms
nreps = sum(P.VALS.Freq == P.lists.Freq(end) & P.VALS.Levl == level);
f = P.lists.Freq / 1000;
f = interp1(1:length(f),f,linspace(1,length(f),length(f)*nreps),'cubic');
hold on
for i = 1:length(rast)
    if isempty(rast{i}), continue; end
    plot(rast{i},f(i),'sk');
end
hold off
set(get(gca,'children'),'markersize',2,'markerfacecolor','k');
set(gca,'yscale','log','ylim',[min(P.lists.Freq) max(P.lists.Freq)]/1000, ...
    'ytick',[1 5 10 50],'yticklabel',[1 5 10 50],'xlim',win, ...
    'tickdir','out');
box on
xlabel('Time (ms)','FontSize',9);
ylabel('Frequency (kHz)','FontSize',9);
title(sprintf('%d dB',level));
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

