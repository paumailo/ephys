function varargout = ParameterBreakout(varargin)
%PARAMETERBREAKOUT M-file for ParameterBreakout.fig
%      PARAMETERBREAKOUT, by itself, creates a new PARAMETERBREAKOUT or raises the existing
%      singleton*.
%
%      H = PARAMETERBREAKOUT returns the handle to a new PARAMETERBREAKOUT or the handle to
%      the existing singleton*.
%
%      PARAMETERBREAKOUT('Property','Value',...) creates a new PARAMETERBREAKOUT using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to ParameterBreakout_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PARAMETERBREAKOUT('CALLBACK') and PARAMETERBREAKOUT('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PARAMETERBREAKOUT.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ParameterBreakout

% Last Modified by GUIDE v2.5 07-Jan-2013 08:23:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ParameterBreakout_OpeningFcn, ...
                   'gui_OutputFcn',  @ParameterBreakout_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


function ParameterBreakout_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ParameterBreakout
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ParameterBreakout wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function varargout = ParameterBreakout_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;
