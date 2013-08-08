function varargout = RIF_analysis(varargin)
% RIF_ANALYSIS MATLAB code for RIF_analysis.fig
%      RIF_ANALYSIS, by itself, creates a new RIF_ANALYSIS or raises the existing
%      singleton*.
%
%      H = RIF_ANALYSIS returns the handle to a new RIF_ANALYSIS or the handle to
%      the existing singleton*.
%
%      RIF_ANALYSIS('CALLBACK',hObj,eventData,h,...) calls the local
%      function named CALLBACK in RIF_ANALYSIS.M with the given input arguments.
%
%      RIF_ANALYSIS('Property','Value',...) creates a new RIF_ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RIF_analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RIF_analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RIF_analysis

% Last Modified by GUIDE v2.5 08-Aug-2013 10:25:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RIF_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @RIF_analysis_OutputFcn, ...
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


% --- Executes just before RIF_analysis is made visible.
function RIF_analysis_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;
guidata(hObj, h);

h.unit_id = varargin{1};

InitializeOptions(h);

RefreshPlots(h);





% --- Outputs from this function are returned to the command line.
function varargout = RIF_analysis_OutputFcn(~, ~, h) 
% Get default command line output from h structure
varargout{1} = h.output;







function UpdateIO(unit_id,h)
h.DATA.IOfh = IO_analysis(unit_id);
guidata(h.figure1,h);


function UpdatePSTH(unit_id,h)
opts = get(h.table_options,'data');
varnames = get(h.table_options,'UserData');

for i = 1:length(varnames)
    val = str2num(opts{i,2}); %#ok<ST2NM>
    if isempty(val)
        val = opts{i,2};
    end
    cfg.(varnames{i}) = val;
end
cfg.plotresult = false;

if isfield(h,'PSTH') && isfield(h.PSTH,'fh')
    cfg.fh = h.PSTH.fh;
end

[h.PSTH.fh,h.PSTH.sh,h.PSTH.R] = DB_PlotPSTH(unit_id,cfg);

guidata(h.figure1,h);


function RefreshPlots(h)
UpdateIO(h.unit_id,h)
UpdatePSTH(h.unit_id,h)

function InitializeOptions(h)

defaultopts = {'View Window',   '-0.05 0.1';    ...
               'bin size',      '0.001';          ...
               'Resp Window',   '0 0.05';       ...
               'Base Window',   '-0.05 0';      ...
               'Hist func',     'mean';         ...
               'convolve',      'true';           ...
               'kernel size',   '5';              ...
               'upsample',      '1';              ...
               'alpha',         '0.025';          ...
               'type',          'larger'};

varnames = {'win','binsize','rwin','bwin','shapefunc','convolve','kernel', ...
    'upsample','alpha','type'};
           
           
opts = getpref('RIF_analysis','OPTIONS',defaultopts);

if numel(opts) ~= numel(defaultopts); opts = defaultopts; end

set(h.table_options,'data',opts,'UserData',varnames);





function AdjustFeature(type,h)

switch type
    case 'onset'
        
        
    case 'offset'
        
        
    case 'peak'
        
        
end
    
    
    











