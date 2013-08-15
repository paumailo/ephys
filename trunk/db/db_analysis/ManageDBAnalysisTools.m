function varargout = ManageDBAnalysisTools(varargin)
% MANAGEDBANALYSISTOOLS MATLAB code for ManageDBAnalysisTools.fig
%      MANAGEDBANALYSISTOOLS, by itself, creates a new MANAGEDBANALYSISTOOLS or raises the existing
%      singleton*.
%
%      H = MANAGEDBANALYSISTOOLS returns the handle to a new MANAGEDBANALYSISTOOLS or the handle to
%      the existing singleton*.
%
%      MANAGEDBANALYSISTOOLS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANAGEDBANALYSISTOOLS.M with the given input arguments.
%
%      MANAGEDBANALYSISTOOLS('Property','Value',...) creates a new MANAGEDBANALYSISTOOLS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ManageDBAnalysisTools_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ManageDBAnalysisTools_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ManageDBAnalysisTools

% Last Modified by GUIDE v2.5 14-Aug-2013 20:46:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ManageDBAnalysisTools_OpeningFcn, ...
                   'gui_OutputFcn',  @ManageDBAnalysisTools_OutputFcn, ...
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


% --- Executes just before ManageDBAnalysisTools is made visible.
function ManageDBAnalysisTools_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ManageDBAnalysisTools_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;













function tools_Callback(hObject, eventdata, handles)


function protocols_Callback(hObject, eventdata, handles)


function add_tool_Callback(hObject, eventdata, handles)


function add_protocol_Callback(hObject, eventdata, handles)
