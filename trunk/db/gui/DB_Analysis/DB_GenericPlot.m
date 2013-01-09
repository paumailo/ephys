function varargout = DB_GenericPlot(varargin)
% DB_GenericPlot
%
% DJS 2013

% Edit the above text to modify the response to help DB_GenericPlot

% Last Modified by GUIDE v2.5 07-Jan-2013 13:39:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DB_GenericPlot_OpeningFcn, ...
    'gui_OutputFcn',  @DB_GenericPlot_OutputFcn, ...
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


% --- Executes just before DB_GenericPlot is made visible.
function DB_GenericPlot_OpeningFcn(hObj, evnt, h, varargin) %#ok<INUSL>
% Choose default command line output for DB_GenericPlot
h.output = hObj;

% Update h structure
guidata(hObj, h);

if ~isempty(varargin) && varargin{1}
    UpdatePlot(h);
end



% --- Outputs from this function are returned to the command line.
function varargout = DB_GenericPlot_OutputFcn(hObj, evnt, h)  %#ok<INUSL>
% Get default command line output from h structure
varargout{1} = h.output;











%% Options














%%
function UpdatePlot(h,ax)
% TODO: SPLIT THIS FUNCTION UP INTO SEPARATE ROUTINES

if nargin == 1 || isempty(ax), ax = h.axes_main; end

set(h.DB_GenericPlot,'Pointer','watch'); drawnow

[params,vals] = RetrieveParams;
ids = RetrieveIDs;

% get options
window  = str2num(get(h.opt_window, 'String'))/1000; %#ok<ST2NM>
binsize = str2num(get(h.opt_binsize,'String'))/1000; %#ok<ST2NM>

isSpike  = get(h.radio_spiketimes,'Value');
isSmooth = get(h.opt_smooth_2d,'Value');
isInterp = get(h.opt_interp,'Value');


% see if we can reuse data from the current plot
info = get(h.axes_main,'UserData');
if ~isempty(info) && ~isequal(ax,h.axes_main)
    
    data = info.data;
    vals = info.vals;
    ids  = info.ids;
    dimvals = info.dimvals;
    
else
    % download data
    if isSpike
        fprintf('Retrieving Spiketimes from database ...')
        drawnow
        spiketimes = DB_GetSpiketimes(ids.units);
        
        % reshape data
        [data,dimvals] = shapedata_spikes(spiketimes,params,vals(1,:), ...
            'win',window,'binsize',binsize);
        data = squeeze(data);
        fprintf(' done\n')
        
    else
        fprintf('Retrieving LFP data from database ...')
        drawnow
        [data,tvec] = DB_GetWave(ids.channels);
        
        % reshape data
        [data,dimvals] = shapedata_wave(data,tvec,params,vals(1,:), ...
            'win',window);
        fprintf(' done\n')
        
    end
end

% plot data
cla(ax,'reset');

if isvector(data)
    plot(ax,dimvals{1},data,'-','linewidth',3)
    xlabel(ax,'time (s)'); ylabel(ax,'mean spike count');
    
elseif ndims(data) == 2 %#ok<ISMAT>
    if isSmooth, data = sgsmooth2d(data); end
    if isInterp, data = interp2(data,3);  end
    imagesc(dimvals{1},dimvals{2},data','Parent',ax);
    xlabel(ax,'time (s)'); ylabel(ax,vals{1,1});
    colorbar
    
elseif ndims(data) == 3
    if isSpike
        data = squeeze(mean(data));
    else
        data = squeeze(sqrt(mean(data.^2)));
    end
    if isSmooth, data = sgsmooth2d(data); end
    if isInterp, data = interp2(data,3);  end
    imagesc(dimvals{2},dimvals{3},data','Parent',ax);
    xlabel(ax,vals{1,1}); ylabel(ax,vals{1,2});
    colorbar
end

set(ax,'ydir','normal');
tstr = sprintf('Unit ID %d',ids.units);
title(ax,tstr);

info.params = params;
info.data   = data;
info.vals   = vals;
info.ids    = ids;
info.dimvals = dimvals;
set(ax,'UserData',info);

set(h.DB_GenericPlot,'Pointer','arrow');








function ids = RetrieveIDs
% Retrive database ids from DB_Browser GUI.
%
% Returns a structure with database tables as field names and corresponding
% unique database ids.
hB = findobj('tag','DB_Browser');
if isempty(hB)
    warndlg('Database Browser GUI (DB_Browser) unavailable');
    return
end

fn = {'experiments','tanks','blocks','channels','units'};
for i = 1:length(fn)
    ids.(fn{i}) = getappdata(hB,fn{i});
end

function [params,vals] = RetrieveParams
% Retrieve parameters from DB_ParameterBreakout GUI.
%
% Return params struct with detailed info on protocol parameters
% Also return 2x2 cell matrix vals which contains parameter names in first
% row and selected parameter values in the second row.

hPB = findobj('tag','ParameterBreakout');
if isempty(hPB)
    warndlg('Parameter Breakout GUI (DB_ParameterBreakout) unavailable');
    params = []; vals = [];
    return
end
params = getappdata(hPB,'params');

% find which parameters we're dealing with
hP1 = findobj(hPB,'tag','popup_param1');
hP2 = findobj(hPB,'tag','popup_param2');
vals{1,1} = get_string(hP1);
vals{1,2} = get_string(hP2);

% get selected values from DB_ParmaterBreakout tables
hT1 = findobj(hPB,'tag','table_params1');
hT2 = findobj(hPB,'tag','table_params2');
vals{2,1} = get(hT1,'UserData');
vals{2,2} = get(hT2,'UserData');

if isempty(vals{2,2}), vals(:,2) = []; end

% update params.VALS structure
ind = true(size(params.VALS.(vals{1,1})));
for i = 1:size(vals,2)
    ind = ind & ismember(params.VALS.(vals{1,i}),vals{2,i});
end
params.VALS = structfun(@(x) (x(ind)), params.VALS, 'UniformOutput', false);



%%
function PopoutPlot(h) %#ok<DEFNU>
f = figure;
ax = axes('Parent',f);
UpdatePlot(h,ax);

info = get(ax,'UserData');

nstr = sprintf('UnitID: %d',info.ids.units);
set(f,'Name',nstr);



function Send2Workspace(h) %#ok<DEFNU>
data = get(h.axes_main,'UserData');
vn = genvarname('data');
assignin('base',vn,data);
eval(sprintf('whos %s',vn))
eval(sprintf('%s',vn))













