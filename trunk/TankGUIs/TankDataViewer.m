function varargout = TankDataViewer(varargin)
% TANKDATAVIEWER MATLAB code for TankDataViewer.fig
%      TANKDATAVIEWER, by itself, creates a new TANKDATAVIEWER or raises the existing
%      singleton*.
%
%      H = TANKDATAVIEWER returns the handle to a new TANKDATAVIEWER or the handle to
%      the existing singleton*.
%
%      TANKDATAVIEWER('CALLBACK',hObj,evnt,h,...) calls the local
%      function named CALLBACK in TANKDATAVIEWER.M with the given input arguments.
%
%      TANKDATAVIEWER('Property','Value',...) creates a new TANKDATAVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TankDataViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TankDataViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TankDataViewer

% Last Modified by GUIDE v2.5 12-Jan-2013 09:12:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TankDataViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @TankDataViewer_OutputFcn, ...
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


% --- Executes just before TankDataViewer is made visible.
function TankDataViewer_OpeningFcn(hObj, evnt, h, varargin) %#ok<INUSL>
% Choose default command line output for TankDataViewer
h.output = hObj;

% Update h structure
guidata(hObj, h);

InitializeTankList(h)



% --- Outputs from this function are returned to the command line.
function varargout = TankDataViewer_OutputFcn(hObj, evnt, h)  %#ok<INUSL>
% Get default command line output from h structure
varargout{1} = h.output;









%% 
function InitializeTankList(h)
tanks = TDT_RegTanks;
set(h.list_tanks,'Value',length(tanks),'String',tanks);

function UpdateBlocksList(h) %#ok<DEFNU>
cfg = [];
cfg.tank = get_string(h.list_tanks);
cfg.datatype = 'BlockInfo';
blockinfo = getTankData(cfg);
if isempty(blockinfo)
    blockstr = '<NO BLOCKS FOUND>';
else
    blockstr = cell(size(blockinfo));
    for i = 1:length(blockinfo)
        blockstr{i} = sprintf('%s - %s',blockinfo(i).name,blockinfo(i).protocolname);
    end
end
set(h.list_blocks,'Value',1,'String',blockstr, ...
    'UserData',blockinfo);

UpdateEventsList(h);

function UpdateEventsList(h)
% set(findobj('type','figure'),'Pointer','watch'); 
% set(get(h.figure1,'children'),'Enable','off');drawnow

blockstr = get_string(h.list_blocks);
if strcmp(blockstr,'<NO BLOCKS FOUND>')
    set(h.list_event1,'Value',1,'String','<NO EVENTS FOUND>','UserData',[]);
    set(h.list_event2,'Value',1,'String','<NO EVENTS FOUND>','UserData',[]);
%     set(findobj('type','figure'),'Pointer','arrow');
%     set(get(h.figure1,'children'),'Enable','on');
    return
end

blockidx  = get(h.list_blocks,'Value');
blockinfo = get(h.list_blocks,'UserData');

blockinfo = blockinfo(blockidx);

pspec = blockinfo.paramspec;

if isempty(pspec) || isempty(pspec{1})
    set(h.list_event1,'Value',1,'String','<NO EVENTS FOUND>','UserData',[]);
    set(h.list_event2,'Value',1,'String','<NO EVENTS FOUND>','UserData',[]);
%     set(findobj('type','figure'),'Pointer','arrow');
%     set(get(h.figure1,'children'),'Enable','on');
    return
end

pspec(ismember(pspec,{'onset','ofset'})) = [];
set(h.list_event1,'Value',1,'String',pspec,'UserData',blockinfo);
if length(pspec) > 1, v = 2; else v = 1; end
set(h.list_event2,'Value',v,'String',pspec,'UserData',blockinfo);


cfg = [];
cfg.tank     = blockinfo.tank;
cfg.blocks   = blockinfo.id;
cfg.datatype = 'Spikes';
% cfg.event    = 'eNeu'; % <-------------------

spikes = getTankData(cfg);

setappdata(h.figure1,'spikes',spikes);

UpdateParamsList(h);
 
% set(findobj('type','figure'),'Pointer','arrow');
% set(get(h.figure1,'children'),'Enable','on');

 
function UpdateParamsList(h)
event1 = get_string(h.list_event1);
event2 = get_string(h.list_event2);

blockinfo = get(h.list_event1,'UserData');

ev1ind  = ismember(blockinfo.paramspec,event1);
ev1p    = blockinfo.epochs(:,ev1ind); 
uev1p   = unique(ev1p);
uev1p(isnan(uev1p)) = [];

ev2ind  = ismember(blockinfo.paramspec,event2);
ev2p    = blockinfo.epochs(:,ev2ind); 
uev2p   = unique(ev2p);
uev2p(isnan(uev2p)) = [];

if isempty(uev1p), uev1p = {'<NO PARAMS>'}; end
if isempty(uev2p), uev2p = {'<NO PARAMS>'}; end

set(h.list_param1,'Value',1:length(uev1p),'String',uev1p);
set(h.list_param2,'Value',1:length(uev2p),'String',uev2p);


function UpdatePlots(h) %#ok<DEFNU>
event1 = get_string(h.list_event1);
event2 = get_string(h.list_event2);
if strcmp(event1,'<NO EVENTS FOUND>'), return; end

% look for existing plot figure
f = findobj('tag','TankDataViewer_PLOTS');
if isempty(f)
    f = figure('tag','TankDataViewer_PLOTS');
end
% set(findobj('type','figure'),'Pointer','watch');
% set(get(h.figure1,'children'),'Enable','off');drawnow

spikes = getappdata(h.figure1,'spikes');
blockinfo = get(h.list_event1,'UserData');

nchan = str2num(get(h.plots_nchan,'String')); %#ok<ST2NM>
ncols = str2num(get(h.plots_dim2, 'String')); %#ok<ST2NM>
nrows = ceil(nchan / ncols);

win     = str2num(get(h.edit_window,'String')); %#ok<ST2NM>
binsize = str2num(get(h.edit_binsize,'String')); %#ok<ST2NM>
binvec  = win(1):binsize:win(2);

onind = ismember(blockinfo.paramspec,'onset');
ons = blockinfo.epochs(:,onind)' + win(1);

fprintf('Computing')
% first create PSTHs by stimulus onsets within a window
psth = zeros(length(binvec),length(ons),length(spikes));
for i = 1:length(spikes)
    if iscell(spikes(i).timestamps) && isempty(spikes(i).timestamps{1}), continue; end
    if isempty(spikes(i).timestamps), continue; end
    rons = repmat(ons,length(spikes(i).timestamps{1}),1);
    adjt = repmat(spikes(i).timestamps{1},1,size(rons,2)) - rons;
    psth(:,:,i) = histc(adjt,binvec);
    clear rons adjt
    fprintf('.')
end
fprintf('done\n')

ev1ind = ismember(blockinfo.paramspec,event1);
ev1p   = blockinfo.epochs(:,ev1ind);
uev1p  = unique(ev1p);
ind = get(h.list_param1,'Value');
uev1p  = uev1p(ind);

ev2ind = ismember(blockinfo.paramspec,event2);
ev2p   = blockinfo.epochs(:,ev2ind);
uev2p  = unique(ev2p);
ind = get(h.list_param2,'Value');
uev2p  = uev2p(ind);

fprintf('Plotting')
clf(f); figure(f);
minn = min([size(psth,3) nchan]);
for i = 1:minn
    ax = subplot(nrows,ncols,i,'Parent',f);
    PlotData(ax,h,psth(:,:,i),spikes(i).channel,binvec, ...
        event1,event2,ev1p,ev2p,uev1p,uev2p);
    fprintf('.')
end
if get(h.opt_scaletogether,'Value')
    axs = get(f,'children');
    cs  = cell2mat(get(axs,'clim'));
    cs(cs(:,1) == -1,:) = []; % default clim
    cs  = [min(cs(:)) max(cs(:))];
    set(axs,'clim',cs);
end
fprintf('done\n')

% set(findobj('type','figure'),'Pointer','arrow');
% set(get(h.figure1,'children'),'Enable','on');





function CheckStrVal(hObj,nvals) %#ok<DEFNU>
w = str2num(get(hObj,'String')); %#ok<ST2NM>
if numel(w) ~= nvals
    warndlg(sprintf('This field requires %d values.',nvals), ...
        'Data Window','modal');
end




function ax = PlotData(ax,h,datain,channelid,binvec,event1,event2,ev1p,ev2p,uev1p,uev2p)

if ~nargin
    datas = get(gca,'UserData');
    event1 = datas.xlabel;
    event2 = datas.ylabel;
    uev1p  = datas.xticks;
    uev2p  = datas.yticks;
    Xlogscale = datas.Xlogscale;
    data   = datas.data;
    channelid = datas.channel;
    f = figure;
    axes('Parent',f);
    ax = get(f,'children');
else
    if length(uev1p) == 1
        % Plot histogram with y-axis as an event and x-axis as time
        data = zeros(length(uev2p),length(binvec));
        for j = 1:length(uev2p)
            if isnan(uev1p)
                ind = ev2p == uev2p(j);
            else
                ind = ev2p == uev2p(j) & ev1p == uev1p;
            end
            data(j,:) = mean(datain(:,ind),2);
        end
        event1 = 'time';
        uev1p  = binvec;
    elseif length(uev2p) == 1 || strcmp(uev2p,'<NO PARAMS>')
        % Plot histogram with x-axis as an event and y-axis as time
        data = zeros(length(binvec),length(uev1p));
        for j = 1:length(uev1p)
            if isnan(uev2p)
                ind = ev1p == uev1p(j);
            else
                ind = ev1p == uev1p(j) & ev2p == uev2p;
            end
            data(:,j) = mean(datain(:,ind),2);
        end
        event2 = 'time';
        uev2p  = binvec;
    else
        % Plot receptive field according to summed response to selected parameters
        sumr = squeeze(sum(datain)); % summed response
        data = zeros(length(uev2p),length(uev1p));
        for j = 1:length(uev1p)
            for k = 1:length(uev2p)
                ind = ev1p == uev1p(j) & ev2p == uev2p(k);
                if ~any(ind), continue; end
                data(k,j) = mean(sumr(ind));
            end
        end
        if get(h.opt_sgfilter,'Value')
            data = sgsmooth2d(data);
        end
        
    end
    if get(h.opt_interpolate,'Value')
        data = interp2(data,3);
        uev1p = interp1(1:length(uev1p),uev1p,linspace(1,length(uev1p),size(data,2)));
        uev2p = interp1(1:length(uev2p),uev2p,linspace(1,length(uev2p),size(data,1)));
    end
    Xlogscale = get(h.opt_Xlogscale,'Value');
end
imh = surf(uev1p,uev2p,data,'Parent',ax);
% [~,imh] = contourf(ax,uev1p,uev2p,data);
view(ax,2)
axis(ax,'tight');
shading(ax,'flat');
if Xlogscale, set(ax,'xscale','log'); else set(ax,'xscale','linear'); end

datas.xlabel  = event1;
datas.ylabel  = event2;
datas.xticks  = uev1p;
datas.yticks  = uev2p;
datas.data    = data;
datas.channel = channelid;
datas.Xlogscale = Xlogscale;

set(ax,'UserData',datas);
% set(ax,'ydir','normal','UserData',datas);
title(ax,datas.channel);
xlabel(ax,datas.xlabel); 
ylabel(ax,datas.ylabel);

if nargin > 1, set(imh,'ButtonDownFcn','TankDataViewer(''PlotData'')'); end

set(gcf,'renderer','zbuffer');






