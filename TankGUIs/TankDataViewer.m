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
function TankDataViewer_OpeningFcn(hObj, evnt, h, varargin)
% Choose default command line output for TankDataViewer
h.output = hObj;

% Update h structure
guidata(hObj, h);

InitializeTankList(h)



% --- Outputs from this function are returned to the command line.
function varargout = TankDataViewer_OutputFcn(hObj, evnt, h) 
% Get default command line output from h structure
varargout{1} = h.output;









%% 
function InitializeTankList(h)
tanks = TDT_RegTanks;
set(h.list_tanks,'Value',length(tanks),'String',tanks);
UpdateBlocksList(h)

function UpdateBlocksList(h)
cfg = [];
cfg.tank = get_string(h.list_tanks);
% cfg.blocks = 'all';
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
blockstr = get_string(h.list_blocks);
if strcmp(blockstr,'<NO BLOCKS FOUND>')
    set(h.list_events,'Value',1,'String','<NO EVENTS FOUND>');
    return
end

blockidx = get(h.list_blocks,'Value');
blockinfo = get(h.list_blocks,'UserData');

blockinfo = blockinfo(blockidx);

pspec = blockinfo.paramspec;
pspec(ismember(pspec,{'onset','ofset'})) = [];
set(h.list_events,'Value',[1 2],'String',pspec,'UserData',pspec);


function UpdatePlots(h)
blockinfo = get(h.list_events,'UserData');
events    = get_string(h.list_events);

cfg = [];
cfg.tank     = blockinfo.tank;
cfg.blocks   = blockinfo.id;
cfg.datatype = 'Spikes';

spikes = getTankData(cfg);

nchan = str2num(get(h.plots_nchan,'String')); %#ok<ST2NM>
ncols = str2num(get(h.plots_dim2, 'String')); %#ok<ST2NM>

if length(events) == 1
    
    
    
    
elseif length(events) == 2
    
    
    
end


function Plot2Dims(



