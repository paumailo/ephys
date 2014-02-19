function varargout = CTXMapper(varargin)
% CTXMAPPER MATLAB code for CTXMapper.fig
%      CTXMAPPER, by itself, creates a new CTXMAPPER or raises the existing
%      singleton*.
%
%      H = CTXMAPPER returns the handle to a new CTXMAPPER or the handle to
%      the existing singleton*.
%
%      CTXMAPPER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CTXMAPPER.M with the given input arguments.
%
%      CTXMAPPER('Property','Value',...) creates a new CTXMAPPER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CTXMapper_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CTXMapper_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CTXMapper

% Last Modified by GUIDE v2.5 12-Mar-2012 00:56:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CTXMapper_OpeningFcn, ...
                   'gui_OutputFcn',  @CTXMapper_OutputFcn, ...
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


% --- Executes just before CTXMapper is made visible.
function CTXMapper_OpeningFcn(hObject, ~, handles, varargin)
handles.C = [];

% Choose default command line output for CTXMapper
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CTXMapper wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CTXMapper_OutputFcn(~, ~, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;




% TOOLBAR CALLBACKS--------------------------------------------------------
function newCTXmap_ClickedCallback(hObj, ~, h) %#ok<INUSL,DEFNU>
C = CTXMap;
fpath = getpref('CTXMapper','Imagefpath',cd);
C.loadCTXImage(fpath);
C.CTXImageAxes = h.corteximage;
h.C = C;
guidata(h.figure1,h);
setpref('CTXMapper','Imagefpath',C.CTXFilePath);

C.dispCTXImage;

function openCTXmap_ClickedCallback(hObj, ~, h) %#ok<INUSL,DEFNU>
fpath = getpref('CTXMapper','CTXfpath',[]);
[f,p] = uigetfile({'*.CTXM','CTXMap File (*.CTXM)'},'Open CTXMap',fpath);
if ~f, return; end
fpath = fullfile(p,f);
load(fpath,'-mat');
C.CTXImageAxes = h.corteximage;
h.C = C;
guidata(h.figure1,h);
setpref('CTXMapper','CTXfpath',fpath);

C.dispCTXImage;
C.plotTessell;
% C.plotPoints;

function saveCTXmap_ClickedCallback(hObj, ~, h) %#ok<INUSL,DEFNU>
C = h.C;
if isempty(C), return; end
fpath = getpref('CTXMapper','CTXfpath',[]);
[f,p] = uiputfile({'*.CTXM','CTXMap File (*.CTXM)'},'Save CTXMap',fpath);
fpath = fullfile(p,f);
save(fpath,'C','-mat');
disp('File Saved')
setpref('CTXMapper','CTXfpath',fpath);
