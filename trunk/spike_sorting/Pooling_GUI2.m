function varargout = Pooling_GUI2(varargin)
% Pooling_GUI2
% 
% DJS 2011

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pooling_GUI2_OpeningFcn, ...
                   'gui_OutputFcn',  @Pooling_GUI2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Pooling_GUI2 is made visible.
function Pooling_GUI2_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% Choose default command line output for Pooling_GUI2
handles.output = hObject;

handles.regKey = 'HKCU\Software\MATHWORKS\MATLAB\Pooling';

t = GetRegKey(handles.regKey,'SPIKEPLOTTYPE');
if isempty(t), t = 'off'; end
set(handles.toolbar_bands,'State',t);

handles.POOLIDS{1} = 'Noise';
handles.POOLIDS{2} = 'MU';
for i = 1:10
    handles.POOLIDS{2+i} = num2str(i,'SU%d');
end

handles.POOLS_SAVED = true;

handles.DATAFILEIDX = [];

uim = uicontextmenu;
uimenu(uim,'Label','Plot 3D','Tag','PCA_3D', ...
    'Checked','on','Callback',{@UIPCA,'3D'});
uimenu(uim,'Label','Plot Projections','Tag','PCA_2D', ...
    'Separator','on','Callback',{@UIPCA,'2D'});
uimenu(uim,'Label',' > Plot as Density','Tag','PCA_2D_DENSITY', ...
    'Callback',{@UIPCA,'Density'});
set(handles.panel_pca,'uicontextmenu',uim);


guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = Pooling_GUI2_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
varargout{1} = handles.output;

function figure1_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
if strcmp(EnsurePoolsSaved(handles),'Cancel'), return; end

t = get(handles.toolbar_bands,'State');
SetRegKey(handles.regKey,'SPIKEPLOTTYPE',t);


% Hint: delete(hObject) closes the figure
delete(hObject);














%% Load Classes
function OpenDataset(DATAFILEIDX)
h = guidata(gcbo);

set(gcf,'Pointer','watch');

if ~exist('DATAFILEIDX','var') || isempty(DATAFILEIDX)
    DATAFILEIDX = 1;
    t = ChooseClassedData;
    if ~t, return; end
    h.DATAFILES = GetDatasets(t);
end

h.DATAFILEIDX = DATAFILEIDX;
h.DATAFILE = h.DATAFILES(h.DATAFILEIDX).cfg;
h.CHANNELS = zeros(size(h.DATAFILES));
for i = 1:length(h.DATAFILES)
    h.CHANNELS(i) = h.DATAFILES(i).cfg.Spikes.channel;
end
h = LoadDataset(h.DATAFILE,h);

chstr = sprintf('%d,',h.DATAFILE.Spikes.channel); chstr(end) = [];
if length(h.DATAFILE.Spikes.channel) > 1, polystr = 'Polytrode'; else polystr = 'Channel'; end
set(h.figure1,'Name',sprintf('Pooling: %s | %s %s (%d of %d)', ...
    h.DATAFILE.tank,polystr,chstr,DATAFILEIDX,length(h.DATAFILES)));

PlotClasses(h);
PlotPCA(h);
PlotPools(h);
UpdateClassInfo(h);
a = get(h.panel_analytics,'Children');
delete(a);

% Enable toolbar
th = findobj(gcbf,'-regexp','Tag','toolbar*', ...
    '-and','-not','Type','uitoolbar', ...
    '-and','-not','Tag','toolbar_open');

set(th,'Enable','on');

h.POOLS_SAVED = true;
UpdateChannel(h);
h.POOLS_SAVED = false;

guidata(h.figure1,h);

set(h.figure1,'Pointer','arrow');

function t = ChooseClassedData
% returns tank directory
h = guidata(gcf);

d = GetRegKey(h.regKey,'acdir');

if ~exist('d','var') || isempty(d), d = []; end

t = uigetdir(d,'Choose tank');

if ~t, return; end

SetRegKey(h.regKey,'acdir',t);

function datafiles = GetDatasets(t)
% Get filenames of classed datasets
%
% fn is the full file name and path to the "Classed_Spikes_..." file from
% a call to AutoClassReport2

if t(end) ~= '\', t(end+1) = '\'; end

classed_files = dir([t '*_CLASSES.mat']);

if isempty(classed_files), error('No classed data found'); end
% classed_files = {classed_files.name};

cfgfile = dir([t '\*_SNIP.mat']);
cfgfile = {cfgfile.name};

% find available channels
for i = 1:length(cfgfile)
    load(fullfile(t,cfgfile{i}),'cfg');
    datafiles(i).cfg = cfg; %#ok<AGROW>
    cf = [t cfg.AutoClass.fileroot '_CLASSES.mat'];
    if ~exist(cf,'file')
        fprintf('** WARNING: Class file was not found: ''%s''\n',cf)
    end
    datafiles(i).cfg.AutoClass.classed = cf; %#ok<AGROW>
end

function h = LoadDataset(datafile,h)
% Where datafile is one index from the structure returned from a call to
% GetDatasets
cstr = sprintf('%d,',datafile.Spikes.channel); cstr(end) = [];
s = sprintf('Loading: Tank ''%s'' Channel %s',datafile.tank,cstr);
fprintf('%s ...',s);
set(h.figure1,'Name',s);

set(h.figure1,'pointer','watch'); drawnow

% load waveform data
load(datafile.AutoClass.snipsfn);
h.WAVEFORMS = W;

% load PCA results
h.PCA = [];
if isfield(datafile,'PCA') && exist(datafile.PCA.filename,'file')
    h.PCA = load(datafile.PCA.filename);
end

% load AutoClass results
load(datafile.AutoClass.classed);
h.CFG = cfg;
% h.BLOCKLIST = cfg.SpikeBlockID;
h.BLOCKLIST = cfg.blocks;
h.CLASSLIST = classList; %#ok<NODEF>
h.UCLASSES  = unique(classList(2,:));

set(h.panel_classes,'Title', ...
    sprintf('Classes: %d classes based on %d spikes', ...
    length(h.UCLASSES),size(h.CLASSLIST,2)));

tw = cfg.Spikes.timestamps;
ts = zeros(sum(cfg.Spikes.blockspikes),1);
ts(1:cfg.Spikes.blockspikes(1)) = tw{1};
k = cfg.Spikes.blockspikes(1)+1;
for i = 2:length(tw)
    ts(k:k+length(tw{i})-1) = tw{i}+ts(k-1);
    k = sum(cfg.Spikes.blockspikes(1:i))+1;
end
h.TS_WRAPPED   = cell2mat(tw');
h.TS_UNWRAPPED = ts;


chstr = sprintf('%d_',datafile.Spikes.channel); chstr(end) = [];
if length(datafile.Spikes.channel) > 1
    polystr = sprintf('PTRODE%d',h.DATAFILEIDX);
else
    polystr = sprintf('Ch_%s',chstr);
end
datafile.pools = sprintf('%s\\%s_%s_POOLS.mat', ...
    h.CFG.AutoClass.resultsdir,datafile.tank,polystr);


% load Pools (if already exist)
if exist(datafile.pools,'file')
    load(datafile.pools);
    h.POOLS = POOLS;
    h.CLASSLIST = CLASSLIST; %#ok<NODEF>
    h.UCLASSES = unique(CLASSLIST(2,:));
    h.POOLS_SAVED = true;
else
    h.POOLS = zeros(1,size(h.CLASSLIST,2));
    h.POOLS_SAVED = false;
end

set(h.figure1,'pointer','arrow');
fprintf('done\n')











%% Save Pools
function SavePools(h)
% Save pooled data with classed data
POOLS     = h.POOLS; %#ok<NASGU>
CLASSLIST = h.CLASSLIST; %#ok<NASGU>

chstr = sprintf('%d_',h.DATAFILE.Spikes.channel); chstr(end) = [];
if length(h.DATAFILE.Spikes.channel) > 1
    polystr = sprintf('PTRODE%d',h.DATAFILEIDX);
else
    polystr = sprintf('Ch_%s',chstr);
end
poolstr = sprintf('%s\\%s_%s_POOLS.mat', ...
    h.CFG.AutoClass.resultsdir,h.DATAFILE.tank,polystr);

save(poolstr,'POOLS','CLASSLIST');

if exist(poolstr,'file')
    fprintf('Saved: %s | %s %s\n',h.DATAFILE.tank,polystr,chstr)
else
    fprintf('\n*** UNABLE TO SAVE POOLS! ***\n')
end

h.POOLS_SAVED = true;
guidata(gcbo,h);

function b = EnsurePoolsSaved(h)
if h.POOLS_SAVED
    b = 'Continue';
else
    b = questdlg(['Pools have been modified.  ', ...
        'Would you like to save the current pools?'], ...
        'Save Pools','Save','Continue','Cancel','Save');
    switch b
        case 'Cancel'
            return
        case 'Save'
            SavePools(h);
    end
end












%% Plotting functions
function PlotClasses(h)
W  = h.WAVEFORMS;
C  = h.CLASSLIST;
uc = h.UCLASSES;
colors = hsv(length(h.UCLASSES));

t = get(h.toolbar_bands,'State');
if strcmp(t,'on')
    opt = 'bands';
else
    opt = 'lines';
end

nrows = floor(sqrt(length(uc)));
ncols = ceil(length(uc) / nrows);
if nrows < 2, nrows = 2; end

% scale together by maximum absolute voltage
maxV  = max(max(abs(W)));

delete(get(h.panel_classes,'Children'));

ax = zeros(size(uc));
for i = 1:length(uc)
    ax(i) = subplot(nrows,ncols,i,'Parent',h.panel_classes, ...
        'Tag',num2str(uc(i),'axclass%02.0f'));
    
    ind = C(2,:) == uc(i);
        
    if sum(ind) <= 1
        op = 'lines';
    else
        op = opt;
    end
    
    switch op
        case 'lines'
            % if lots of lines, then just display a random sampling
            if sum(ind) > 500, ind = find(ind); ind = ind(randperm(500)); end
            plot(ax(i),1:size(W,2),W(ind,:)','Color',colors(i,:))
       
        case 'bands'
            q = quantile(W(ind,:),[0.025 0.975])';
            y = [q(:,1); flipud(q(:,2))];
            x = [1:size(W,2) size(W,2):-1:1];
            fill(x',y,colors(i,:),'Parent',ax(i));
    end
    xlim(ax(i),[1 size(W,2)]);  ylim(ax(i),[-maxV maxV]);
    
    uim = uicontextmenu('UserData',uc(i));
    uimenu(uim,'Label','Select Class','Tag','Select_Class','UserData',uc(i), ...
        'Checked','off','Callback',{@SelectClass});
    uimenu(uim,'Label','Edit Class','Tag','Edit_Class','UserData',uc(i), ...
        'Callback',{@EditClass,uc(i)});
    for j = 1:length(h.POOLIDS)
        if j == 1, s = 'on'; else s = 'off'; end
        uimenu(uim,'Label',h.POOLIDS{j},'Tag',['ut_' lower(h.POOLIDS{j})], ...
            'UserData',j-1,'Checked','on','Separator',s, ...
            'Callback',{@UpdateUnitType,ax(i),uc(i)});
    end
    
    set(ax(i),'UIContextMenu',uim);
    set(ax(i),'ButtonDownFcn',@SelectClass);
    set(ax(i),'UserData',uc(i),'XGrid','on','XMinorGrid','off', ...
        'YGrid','on','YMinorGrid','off','YTickLabel',[],'XTickLabel',[], ...
        'Box','on');
end

x = (nrows-1)*ncols+1;
if x > length(ax); x =(nrows-2)*ncols+1; end
yt = get(ax(x),'YTick');
set(ax(x),'YTickLabel',num2str((yt)'*1000,'%0.2f'));

SetRegKey(h.regKey,'PLOTSPIKESSTYLE',opt);

function EditClass(hObj,evnt,cid) %#ok<INUSL>
h = guidata(hObj);
W  = h.WAVEFORMS;
C  = h.CLASSLIST;
uc = h.UCLASSES;
colors = hsv(length(h.UCLASSES));

ind = C(2,:) == cid;
orind = find(ind);
sW = W(ind,:);

uid = uc == cid;

f = figure('Name',sprintf('Class ID: %d | %d spikes',cid,sum(ind)));

ax = axes('Parent',f,'XGrid','on','YGrid','on','XTickLabel',[]);

hl = line(repmat((1:size(sW,2))',1,size(sW,1)),sW', ...
    'Parent',ax,'Color',colors(uid,:));

maxV = max(max(abs(sW)));
ylim(ax,[-maxV maxV]); xlim(ax,[1 size(sW,2)]);
ylabel(ax,'Amp (V)');

hold(ax,'on');
[xa,ya] = ginput(1); xa = round(xa); plot(ax,xa,ya,'xk');
[xb,yb] = ginput(1); xb = round(xb); plot(ax,xb,yb,'xk');
x = min([xa xb]); xb = max([xa xb]); xa = x;
y = min([ya yb]); yb = max([ya yb]); ya = y;

xl = [xa xa xb xb xa]; yl = [ya yb yb ya ya];
plot(ax,xl,yl,'--k');
hold(ax,'off');

ind = any(sW(:,xa:xb) >= ya & sW(:,xa:xb) <= yb,2);

set(hl(ind),'LineWidth',3);
set(hl(~ind),'Color','k','LineStyle',':');

r = questdlg(sprintf('%d spikes have been selected.  Would you like to create a new class with these spikes?', ...
    sum(ind)),'Split Class','Yes','No','No');

if strcmp(r,'No'), close(f); return; end

set(h.figure1,'Pointer','watch'); set(f,'Pointer','watch'); drawnow

C(:,orind(ind)) = max(uc) + 1;

h.CLASSLIST = C;
h.UCLASSES  = unique(C(2,:));

guidata(hObj,h);

close(f);

PlotClasses(h);
UpdateClassInfo(h);
PlotPCA(h);
set(h.figure1,'Pointer','arrow');

function PlotPools(h)
W  = h.WAVEFORMS;
P  = h.POOLS;
up = unique(P);
colors = lines(7);

t = get(h.toolbar_bands,'State');
if strcmp(t,'on')
    opt = 'bands';
else
    opt = 'lines';
end

delete(get(h.panel_pools,'Children'));

if isempty(P), return; end

ind = ismember(P,up);
maxV = max(max(abs(W(ind,:))));

if length(up) < 3, ncol = 3; else ncol = length(up); end

for i = 1:length(up)
    ax = subplot(1,ncol,i,'Parent',h.panel_pools);
    
    ind = up(i) == P;
    nc = sum(ind);
    switch opt
        case 'lines'
            % if lots of lines, then just display a random sampling
            if nc > 1000, ind = find(ind); ind = ind(randperm(1000)); end
            plot(ax,1:size(W,2),W(ind,:)','Color',colors(i,:))    
            
        case 'bands'
            q = quantile(W(ind,:),[0.025 0.975])';
            y = [q(:,1); flipud(q(:,2))];
            x = [1:size(W,2) size(W,2):-1:1];
            fill(x',y,colors(i,:),'Parent',ax);
    end

    xlim(ax,[1 size(W,2)]);
    ylim(ax,[-maxV maxV]);
    
    if i == 1
        yt = get(ax,'YTick');
        set(ax,'YTickLabel',num2str((yt)'*1000,'%0.2f'));
    else
        set(ax,'YTickLabel',[]);
    end

    set(ax,'XTickLabel',[],'XGrid','on','YGrid','on');
        
    x = xlim(ax); y = ylim(ax);
    text(x(1),y(2),num2str(nc,'%d'), ...
        'Parent',ax,'FontSize',10, ...
        'VerticalAlignment','Bottom', ...
        'HorizontalAlignment','Left');
    
    text(x(2),y(2),h.POOLIDS{up(i)+1}, ...
        'Parent',ax,'FontSize',10,'Color',[1 1 1],'FontWeight','bold', ...
        'BackgroundColor',colors(i,:), ...
        'VerticalAlignment','Bottom', ...
        'HorizontalAlignment','Right');
     
    uim = uicontextmenu;
    uimenu(uim,'Tag','Select_Pool','Label','Select Pool', ...
        'UserData',up(i),'Callback',{@SelectPool});
    set(ax,'UIContextMenu',uim,'UserData',up(i));

    set(ax,'ButtonDownFcn',{@SelectPool});
    
end

function PlotPCA(h)
PCA    = h.PCA;
C      = h.CLASSLIST;
uc     = h.UCLASSES;
colors = hsv(length(h.UCLASSES));

if isempty(PCA), return; end

set(h.panel_pca,'Title','Rendering...'); drawnow

hlclass = get(findall(h.panel_classes,'XColor','r'),'UserData');
if iscell(hlclass), hlclass = cell2mat(hlclass); end
    
ui = get(h.panel_pca,'UIContextMenu');
is2d = strcmp(get(findobj(ui,'Tag','PCA_2D'),'Checked'),'on');
is2d_density = strcmp(get(findobj(ui,'Tag','PCA_2D_DENSITY'),'Checked'),'on');

ax = get(h.panel_pca,'Children');
if ~is2d && ~isempty(ax), [az,el] = view(ax); else az = 3; el = []; end
delete(ax);

PCAx = PCA.scores(:,1); PCAy = PCA.scores(:,2); PCAz = PCA.scores(:,3);

if is2d
    set(findobj(h.figure1,'Tag','toolbar_r3d'),'Enable','off');
else
    set(findobj(h.figure1,'Tag','toolbar_r3d'),'Enable','on');
end

if is2d && is2d_density
    for i = 1:3
        subax(i) = subplot(2,2,i,'Parent',h.panel_pca); %#ok<AGROW>
        hold(subax(i),'on');
        axis square
    end
    
    % compute 2D histogram PC1 vs PC2
    xbins = linspace(min(PCAx),max(PCAx),50);
    ybins = linspace(min(PCAy),max(PCAy),50);
    
    hd = zeros(length(xbins),length(ybins));
    for i = 1:length(xbins)-1
        for j = 1:length(ybins)-1
            hd(i,j) = sum(PCAx >= xbins(i) & PCAx < xbins(i+1) ...
                & PCAy >= ybins(j) & PCAy < ybins(j+1));
            
        end
    end
    imagesc(interp2(hd,2)','Parent',subax(1));
    xlabel(subax(1),'PC1'); ylabel(subax(1),'PC2');
    axis square

    % compute 2D histogram PC1 vs PC3
    xbins = linspace(min(PCAx),max(PCAx),50);
    ybins = linspace(min(PCAz),max(PCAz),50);
    
    hd = zeros(length(xbins),length(ybins));
    for i = 1:length(xbins)-1
        for j = 1:length(ybins)-1
            hd(i,j) = sum(PCAx >= xbins(i) & PCAx < xbins(i+1) ...
                & PCAz >= ybins(j) & PCAz < ybins(j+1));
            
        end
    end
    imagesc(interp2(hd,2)','Parent',subax(2));
    xlabel(subax(2),'PC1'); ylabel(subax(2),'PC3');
    axis square

    % compute 2D histogram PC2 vs PC3
    xbins = linspace(min(PCAy),max(PCAy),50);
    ybins = linspace(min(PCAz),max(PCAz),50);
    
    hd = zeros(length(xbins),length(ybins));
    for i = 1:length(xbins)-1
        for j = 1:length(ybins)-1
            hd(i,j) = sum(PCAy >= xbins(i) & PCAy < xbins(i+1) ...
                & PCAz >= ybins(j) & PCAz < ybins(j+1));
            
        end
    end
    
    imagesc(interp2(hd,2)','Parent',subax(3));
    xlabel(subax(3),'PC2'); ylabel(subax(3),'PC3');
    axis square
    
    set(subax,'XTick',[],'YTick',[],'ydir','normal');
    
elseif is2d
    
    for i = 1:3
        subax(i) = subplot(2,2,i,'Parent',h.panel_pca); %#ok<AGROW>
        hold(subax(i),'on');
        axis square
    end
    
    for i = 1:length(uc)
        if isempty(hlclass)
            c = colors(i,:);
        elseif any(uc(i) == hlclass)
            c = colors(i,:);
        else
            c = [0.8 0.8 0.8];
        end
        
        ind = C(2,:) == uc(i);
        
        plot(PCAx(ind),PCAy(ind), ...
            's','MarkerEdgeColor',c, ...
            'MarkerFaceColor',c,'MarkerSize',2,'Parent',subax(1))
        
        plot(PCAx(ind),PCAz(ind), ...
            's','MarkerEdgeColor',c, ...
            'MarkerFaceColor',c,'MarkerSize',2,'Parent',subax(2))
        
        plot(PCAy(ind),PCAz(ind), ...
            's','MarkerEdgeColor',c, ...
            'MarkerFaceColor',c,'MarkerSize',2,'Parent',subax(3))
    end
    
    q = quantile([PCAx PCAy PCAz],[.001 .999]);
    for i = 1:3, hold(subax(i),'off'); end
    if ~all(q)
        q(:,~all(q)) = [-0.1e-4 0.1e-4]; % catch for 0 scales
    end
    xlim(subax(1),q(:,1)); ylim(subax(1),q(:,2));
    xlim(subax(2),q(:,1)); ylim(subax(2),q(:,3));
    xlim(subax(3),q(:,2)); ylim(subax(3),q(:,3));
    set(subax,'XTick',[],'YTick',[],'Box','on');
    xlabel(subax(1),'PC1'); xlabel(subax(2),'PC1'); xlabel(subax(3),'PC2');
    ylabel(subax(1),'PC2'); ylabel(subax(2),'PC3'); ylabel(subax(3),'PC3');
else
    ax = axes('Parent',h.panel_pca,'DrawMode','fast');
    hold(ax,'on');
    for i = 1:length(uc)
        if isempty(hlclass)
            c = colors(i,:);
        elseif any(uc(i) == hlclass)
            c = colors(i,:);
        else
            c = [0.8 0.8 0.8];
        end
        ind = C(2,:) == uc(i);
        
        hold(ax,'on');
        plot3(PCAx(ind),PCAy(ind),PCAz(ind), ...
            's','MarkerEdgeColor',c, ...
            'MarkerFaceColor',c,'MarkerSize',2,'Parent',ax);
    end
    hold(ax,'off');
    %         m = mean(PCA.scores(:,1:3));
    q = quantile([PCAx PCAy PCAz],[.001 .999]);
    xlim(ax,q(:,1)); ylim(ax,q(:,2)); zlim(ax,q(:,3));
    view(ax,[az,el]);
    set(ax,'XTick',[],'YTick',[],'ZTick',[]);
    box(ax,'on');
    xlabel(ax,'PC1'); ylabel(ax,'PC2'); zlabel(ax,'PC3');
    
end

lat = h.PCA.latent;
expvar = sum(lat(1:3))/sum(lat) * 100;
iexpvar = lat(1:3)/sum(lat) * 100;
set(h.panel_pca,'Title',sprintf('PCA (%0.1f%% of variance explained [%0.0f%% | %0.0f%% | %0.0f%%])', ...
    expvar,iexpvar));

function PlotAnalytics(h,results)
% following a call to to ComputeAnalytics
delete(get(h.panel_analytics,'Children'));

C = h.CLASSLIST;
W  = h.WAVEFORMS;
uc = h.UCLASSES;
colors = hsv(length(h.UCLASSES));

t = get(h.toolbar_bands,'State');
if strcmp(t,'on')
    opt = 'bands';
else
    opt = 'lines';
end

ISI          = results.ISI;
AUTOCORR     = results.AUTOCORR;
TIMESEQUENCE = results.TIMESEQUENCE;

for i = 1:4
    subplot(1,4,i,'Parent',h.panel_analytics);
end

if isempty(TIMESEQUENCE.firingrate) || isempty(ISI.counts)
    return
end

ax = subplot(1,4,1);
bar(ax,ISI.bins*1000,ISI.counts,'BarWidth',1,'EdgeColor','none');
% ylabel(ax,'counts'); xlabel(ax,'ISI (ms)');
xlim(ax,[0 max(ISI.bins)*1000]);
set(ax,'XTick',[]);
text(max(xlim(ax)),max(ylim(ax)), ...
    sprintf('peak count = %d\npeak bin = %0.1f ms\nmedian = %0.1f\nmode = %0.1f', ...
    ISI.peak,ISI.peakbin*1000,ISI.median,ISI.mode), ...
    'Parent',ax,'FontSize',7, ...
    'BackgroundColor',[1 1 1], ...
    'VerticalAlignment','Top', ...
    'HorizontalAlignment','Right');


ax = subplot(1,4,2);
bar(ax,AUTOCORR.lags,AUTOCORR.corr,'BarWidth',1,'EdgeColor','none');
% title(ax,'correlation');
xlim(ax,[min(AUTOCORR.lags) max(AUTOCORR.lags)]);
ylim(ax,[0 max(ylim(ax))]);
set(ax,'XTick',[]);

axc = get(h.panel_classes,'Children');
um  = cell2mat(get(axc,'UIContextMenu'));
umc = findall(um,'Tag','Select_Class','Checked','on');
suc = get(umc,'UserData');
if iscell(suc), suc = cell2mat(suc); end

ax = subplot(1,4,3);
cla(ax)
hold(ax,'on')
for i = 1:length(suc)
    ind = C(2,:) == suc(i);
    [mW,hW] = hist(min(W(ind,:),[],2),100);
    barh(ax,hW,mW,'Barwidth',1,'Edgecolor','none','FaceColor',colors(uc==suc(i),:));
end
axis tight
box on
hold(ax,'off')
set(ax,'ylim',[min(ylim) 0],'XTick',[]);

ax = subplot(1,4,4);
% bar(ax,TIMESEQUENCE.bins,TIMESEQUENCE.firingrate,'BarWidth',1,'EdgeColor','none');
% xlim(ax,[0 TIMESEQUENCE.bins(end)]);
% set(ax,'XTick',[]);
% ylabel(ax,'Firing Rate (Hz)');
% maxV = max(max(abs(W)));
cla(ax);
hold(ax,'on');
for i = 1:length(suc)
    ind = C(2,:) == suc(i);
        
    if sum(ind) <= 1
        op = 'lines';
    else
        op = opt;
    end
    

    switch op
        case 'lines'
            % if lots of spikes, then just display a random sampling
            if sum(ind) > 1000, ind = find(ind); ind = ind(randperm(1000)); end
            plot(ax,1:size(W,2),W(ind,:)','Color',colors(uc==suc(i),:))
        case 'bands'
            q = quantile(W(ind,:),[0.025 0.975])';
            y = [q(:,1); flipud(q(:,2))];
            x = [1:size(W,2) size(W,2):-1:1];
            hl = fill(x',y,colors(uc==suc(i),:),'Parent',ax,'LineStyle','none');
            set(hl,'ButtonDownFcn',{@ChangePlotOrder,hl,ax});
    end
end
hold(ax,'off');
box(ax,'on');
xlim(ax,[1 size(W,2)]);
% ylim(ax,[-maxV maxV]);

function ChangePlotOrder(hObj,evnt,hl,ax) %#ok<INUSL>
c = get(ax,'Children');
ind = hl == c;

if hl == c(1)
    t = c(~ind);
    t(end+1) = hObj;
else
    t = hObj;
    t(end+1:length(c)) = c(~ind);
end

set(ax,'Children',t);






























%% Analysis Functions
function results = ComputeAnalytics(timestamps)
% timestamps is either an N x 1 matrix for individual dataset or N x 1 cell
% array of N x 1 matrices for multiple datasets

if ~iscell(timestamps), timestamps = {timestamps}; end

timestamps = reshape(timestamps,numel(timestamps),1);
ts = cell2mat(timestamps');

% compute ISI
bins = 0:0.001:0.099;
d = diff(sort(ts));
counts = histc(d,bins);
results.ISI.counts = counts;
results.ISI.bins   = bins;
[p,pb] = max(counts);
results.ISI.peak   = p;
results.ISI.peakbin = bins(pb);
results.ISI.mode   = mode(counts);
results.ISI.median = median(counts);

% compute autocorrelation
binsize = 0.005;
bins = 0:binsize:max(ts)-binsize;
bts = histc(ts,bins);
[c,lags] = xcorr(bts,100);
lags = lags * binsize;
x = lags == 0;
results.AUTOCORR.lags = lags(~x);
results.AUTOCORR.corr = c(~x);

% binned timestamps
binsize = 60;
bins = 0:binsize:max(ts)-binsize;
c = histc(ts,bins);
results.TIMESEQUENCE.firingrate = c / binsize;
results.TIMESEQUENCE.bins = bins;
















%% Update GUI

function UIPCA(hObj,evnt,opt) %#ok<INUSD>
h = guidata(hObj);

p = get(hObj,'Parent');

h2D.h = findobj(p,'Tag','PCA_2D');
h2D.density = findobj(p,'Tag','PCA_2D_DENSITY');
h3D.h = findobj(p,'Tag','PCA_3D');

n = get(hObj,'Tag');

switch n
    case 'PCA_2D'
        set(h2D.density,'Enable','on');
        set(h2D.h,'Checked','on');
        set(h3D.h,'Checked','off');
        
    case 'PCA_2D_DENSITY'
        if strcmp(get(h2D.density,'Checked'),'on')
            set(h2D.density,'Checked','off');
        else
            set(h2D.density,'Checked','on');
        end
        
    case 'PCA_3D'
        set(h2D.density,'Enable','off');
        set(h2D.h,'Checked','off');
        set(h3D.h,'Checked','on');
end   

set(h.figure1,'Pointer','watch'); drawnow
PlotPCA(h);
set(h.figure1,'Pointer','arrow');

function SelectClass(hObj,evnt) %#ok<INUSD>
h = guidata(hObj);

if strcmp(get(h.figure1,'SelectionType'),'alt') ...
        && ~any(strcmp(get(gcbo,'Type'),{'uimenu','uipushtool'}))
    return
end

if strcmp(get(hObj,'Type'),'axes')
    umc = get(hObj,'UIContextMenu');
    hObj = findobj(umc,'Tag','Select_Class');
end

ax = get(h.panel_classes,'Children');
um = cell2mat(get(ax,'UIContextMenu'));
umc = findall(um,'Tag','Select_Class');

ht = get(hObj,'Tag');
if strcmp(ht,'toolbar_all_classes')
	set(umc,'Checked','on');
elseif strcmp(ht,'toolbar_no_classes')
    set(umc,'Checked','off');
elseif ~strcmp(ht,'figure1')
    % toggle current selection
    c = get(hObj,'Checked');
    if strcmp(c,'off')
        set(hObj,'Checked','on')
    else
        set(hObj,'Checked','off')
    end
end


% Update which classes are highlighted
selclass = [];
for i = 1:length(umc)
    if strcmp(get(umc(i),'Checked'),'on') 
        set(ax(i),'XColor','r','YColor','r');
        selclass(end+1) = get(ax(i),'UserData'); %#ok<AGROW>
    else
        set(ax(i),'XColor','k','YColor','k');
    end
end

% replot based on selections
PlotPCA(h);

timestamps = cell(size(selclass));
for i = 1:length(selclass)
    ind = h.CLASSLIST(2,:) == selclass(i);
    timestamps{i} = h.TS_UNWRAPPED(ind)';
end
results = ComputeAnalytics(timestamps);
PlotAnalytics(h,results);

function SelectPool(hObj,event) %#ok<INUSD>
h = guidata(hObj);
C = h.CLASSLIST;
P = h.POOLS;

if strcmp(get(h.figure1,'SelectionType'),'alt') ...
        && ~any(strcmp(get(gcbo,'Type'),{'uimenu','uipushtool'}))
    return;
end

cax = get(h.panel_classes,'Children');
cum = cell2mat(get(cax,'UIContextMenu'));
cumc = findall(cum,'Tag','Select_Class');

pud = get(hObj,'UserData');
cud = get(cum,'UserData');
if iscell(cud), cud = cell2mat(cud); end

pcind = P == pud;
uc = unique(C(2,pcind));

set(cumc,'Checked','off');
set(cumc(ismember(cud,uc)),'Checked','on');

SelectClass(h.figure1);

function UpdateUnitType(hObj,evnt,ax,classid) %#ok<INUSD>
h = guidata(hObj);
C = h.CLASSLIST;

% alter all selected classes
ax = get(h.panel_classes,'Children');
um = cell2mat(get(ax,'UIContextMenu'));
f = findall(um,'Tag','Select_Class','-and','Checked','on'); % friends
if isempty(f), f  = hObj; end
pf = get(f,'Parent');
if iscell(pf), pf = cell2mat(pf); end


% NT = get(hObj,'Tag');
set(findall(pf,'-regexp','Tag','ut*'),'Checked','off');
set(hObj,'Checked','on');

CT = get(pf,'UserData');    % class type
if iscell(CT), CT = cell2mat(CT); end
UT = get(hObj,'UserData'); % unit type

h.POOLS(ismember(C(2,:),CT)) = UT;

h.POOLS_SAVED = false;

guidata(hObj,h);

PlotPools(h);
UpdateClassInfo(h);

function UpdateClassInfo(h)
P = h.POOLS;
C = h.CLASSLIST;
Pc = lines(length(h.POOLIDS));

uP = unique(P);

classax = get(h.panel_classes,'Children');
for i = 1:length(classax)
    ax = classax(i);
    delete(findobj(get(ax,'Children'),'Type','text'));
    ud = get(ax,'UserData');
    ind = ud == C(2,:);
    nc = sum(ind);
    
    x = xlim(ax); y = ylim(ax);
    text(x(1),y(2),sprintf('Class %d [%d]',ud,nc), ...
        'Parent',ax,'FontSize',8, ...
        'VerticalAlignment','Bottom', ...
        'HorizontalAlignment','Left');
    
    tP = P(find(ind,1));
    text(x(2),y(1),h.POOLIDS{tP+1}, ...
        'Parent',ax,'FontSize',9,'Color',[1 1 1],'FontWeight','bold', ...
        'BackgroundColor',Pc(uP==tP,:), ...
        'VerticalAlignment','Bottom', ...
        'HorizontalAlignment','Right');
    
    uim = get(get(ax,'UIContextMenu'),'Children');
    set(uim,'Checked','off');
    uim = findobj(uim,'Label',h.POOLIDS{tP+1});
    set(uim,'Checked','on');
    
end

function UpdateChannel(h,chandir)
% input is channel direction as 'UP' or 'DOWN' or [] to initialize

if ~exist('chandir','var') || isempty(chandir), chandir = ''; end

if strcmp(EnsurePoolsSaved(h),'Cancel'), return; end

switch chandir
    case 'UP'
        if h.DATAFILEIDX < length(h.DATAFILES), h.DATAFILEIDX = h.DATAFILEIDX + 1; end
    case 'DOWN'
        if h.DATAFILEIDX > 1, h.DATAFILEIDX = h.DATAFILEIDX - 1; end
    case 'SELECT'
        [sel,ok] = listdlg('PromptString','Select a Channel:', ...
            'SelectionMode','single', 'Name','Channels', ...
            'ListString',cellstr(num2str(h.CHANNELS(:))), ...
            'InitialValue',h.DATAFILEIDX);
        if ~ok
            return
        else
            h.DATAFILEIDX = sel;
        end
end

set(findobj(h.figure1,'-regexp','Tag','toolbar_channel*'),'Enable','on');
if h.DATAFILEIDX == length(h.DATAFILES)
    set(findobj(h.figure1,'Tag','toolbar_channel_up'),'Enable','off');
end
if h.DATAFILEIDX == 1
    set(findobj(h.figure1,'Tag','toolbar_channel_down'),'Enable','off');
end

if ~isempty(chandir)
    OpenDataset(h.DATAFILEIDX);
end

function UpdatePlotStyle(h) %#ok<DEFNU>
if ~isfield(h,'WAVEFORMS') || isempty(h.WAVEFORMS), return; end
set(h.figure1,'Pointer','watch'); drawnow
PlotClasses(h);
PlotPools(h);
set(h.figure1,'Pointer','arrow');
