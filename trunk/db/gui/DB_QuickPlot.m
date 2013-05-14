function varargout = DB_QuickPlot(varargin)
% DB_QUICKPLOT MATLAB code for DB_QuickPlot.fig
%      DB_QUICKPLOT, by itself, creates a new DB_QUICKPLOT or raises the existing
%      singleton*.
%
%      H = DB_QUICKPLOT returns the handle to a new DB_QUICKPLOT or the handle to
%      the existing singleton*.
%
%      DB_QUICKPLOT('CALLBACK',hObject,eventData,h,...) calls the local
%      function named CALLBACK in DB_QUICKPLOT.M with the given input arguments.
%
%      DB_QUICKPLOT('Property','Value',...) creates a new DB_QUICKPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DB_QuickPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DB_QuickPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DB_QuickPlot

% Last Modified by GUIDE v2.5 14-May-2013 14:42:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DB_QuickPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @DB_QuickPlot_OutputFcn, ...
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


% --- Executes just before DB_QuickPlot is made visible.
function DB_QuickPlot_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

guidata(hObj, h);

RefreshParameters([],h);

if ~ispref('DB_QuickPlot')
    setpref('DB_QuickPlot',{'val_ncols','val_nrows','val_win'},{'4','4','0 0.1'});
end
pref = getpref('DB_QuickPlot');
fn = fieldnames(pref);
for i = 1:length(fn)
    set(h.(fn{i}),'String',pref.(fn{i}));
end


% --- Outputs from this function are returned to the command line.
function varargout = DB_QuickPlot_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;














%%
function RefreshParameters(hObj,h) %#ok<INUSL>

pref = getpref('DB_BROWSER_SELECTION');

if isempty(pref)
    errordlg('DB_Browser malfunctioned')
    return
end

P = DB_GetParams(pref.blocks);

params = fieldnames(P.lists);
params(strcmp(params,'onset')) = [];

str = get_string(h.list_params);
val = find(ismember(params,str));
if isempty(val), val = 1; end

set(h.list_params,'String',params,'Value',val)






%% Helper functions
function CheckVals(hObj,nvals) %#ok<DEFNU>

str = get(hObj,'String');
val = str2num(str); %#ok<ST2NM>

dflt = getpref('DB_QuickPlot_DEFAULTS',get(hObj,'tag'));

if isnan(val)
    errordlg(sprintf('''%s'' is an invalid entry\n\nExpecting %d numeric values.', ...
        str,nvals),'Invalid entry','modal');
    set(hObj,'String',dflt);
    str = dflt;
end

setpref('DB_QuickPlot',get(hObj,'tag'),str);



%%
function PlotData(h) %#ok<DEFNU>
persistent FIGH

pref = getpref('DB_BROWSER_SELECTION');

if isempty(pref)
    errordlg('DB_Browser malfunctioned')
    return
end

P = DB_GetParams(pref.blocks);
param = get_string(h.list_params);

win   = str2num(get(h.val_win,'String')); %#ok<ST2NM>
nrows = str2num(get(h.val_nrows,'String')); %#ok<ST2NM>
ncols = str2num(get(h.val_ncols,'String')); %#ok<ST2NM>

% get spike times of selected unit
S = myms(sprintf('SELECT spike_time FROM spike_data WHERE unit_id = %d',pref.units));

% Organize by stimulus onsets
ons = P.VALS.onset;

TS = cell(size(ons));
for i = 1:length(ons)
    ind = S >= ons(i) + win(1) & S < ons(i) + win(2);
    TS{i} = S(ind) - ons(i);
end

% Reorganize by stimulus type
try
    st = P.lists.(param);
catch ME
    switch ME.identifier
        case 'MATLAB:nonExistentField'
            helpdlg('Click OK to refresh and then click Plot again');
            RefreshParameters([],h)
            return
    end
end

RF = cell(size(st));
for i = 1:length(st)
    ind = P.VALS.(param) == st(i);
    RF{i} = TS(ind);
end

% Plot rasters by stimulus type
if get(h.chk_newfig,'Value')
    FIGH = figure;
else
    if isempty(FIGH), FIGH = figure; end
    figure(FIGH)
    clf
end

n = myms(sprintf([ ...
    'SELECT CONCAT(e.name,": ",t.tank_condition,"-",p.alias,"[",c.target,c.channel,"-",cl.class,"]") ', ...
    'FROM tanks t INNER JOIN experiments e ON t.exp_id = e.id ', ...
    'INNER JOIN blocks b ON b.tank_id = t.id ', ...
    'INNER JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'INNER JOIN channels c ON c.block_id = b.id ', ...
    'INNER JOIN units u ON u.channel_id = c.id ', ...
    'INNER JOIN class_lists.pool_class cl ON cl.id = u.pool ', ...
    'WHERE u.id = %d'],pref.units));

set(FIGH,'name',char(n) );

for i = 1:length(st)
    subplot(nrows,ncols,i)
%     hold on
    lr = cellfun(@length,RF{i},'UniformOutput',true);
    fr = find(lr);
    rm = cellfun(@repmat,num2cell(fr),num2cell(lr(fr)),num2cell(ones(size(fr))),'UniformOutput',false);
    X = cell2mat(RF{i});
    Y = cell2mat(rm);

%     plot(X,Y,'sr','markersize',2,'markerfacecolor','none','markeredgecolor','b');
    plot(X,Y,'sk','markersize',2,'markerfacecolor',[0.6 0.6 0.6],'markeredgecolor','none');
    
    hold on
    plot([0 0],ylim,'-k');
    hold off
    
    
%     title(st(i));
end

ax = findobj(gcf,'type','axes');
set(ax,'xtick',[],'ytick',[],'xlim',win,'ylim',[0 length(lr)+1]);





































