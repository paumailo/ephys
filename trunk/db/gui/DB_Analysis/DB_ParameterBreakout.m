function varargout = DB_ParameterBreakout(varargin)
% h = DB_ParameterBreakout(block_id)
%
% Receives a scalar value with the unique database id of a block.
%
% A connection to a database should already be established prior to calling
% this GUI.
%
% DJS 2013

% Edit the above text to modify the response to help ParameterBreakout

% Last Modified by GUIDE v2.5 07-Jan-2013 08:15:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ParameterBreakout_OpeningFcn, ...
                   'gui_OutputFcn',  @ParameterBreakout_OutputFcn, ...
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


% --- Executes just before ParameterBreakout is made visible.
function ParameterBreakout_OpeningFcn(hObj, evnt, h, varargin) %#ok<INUSL>
h.output = hObj;

if ~nargin, error('DB_ParameterBreakout: block_id must be specified'); end

block_id = varargin{1};

if ~isscalar(block_id), error('DB_ParameterBreakout: block_id must be a scalar value'); end

params = DB_GetParams(block_id);

setappdata(h.ParameterBreakout,'params',params);
setappdata(hObj,'block_id',block_id);

guidata(hObj, h);

UpdateParams(h);

UpdateTables(h);

% --- Outputs from this function are returned to the command line.
function varargout = ParameterBreakout_OutputFcn(hObj, evnt, h)  %#ok<INUSL>
varargout{1} = h.output;






%% 
function UpdateTables(h)
params = getappdata(h.ParameterBreakout,'params');

pstr1 = cellstr(get(h.popup_param1,'String'));
pval1 = get(h.popup_param1,'Value');
pstr2 = cellstr(get(h.popup_param2,'String'));
pval2 = get(h.popup_param2,'Value');

if strcmp(pstr1,'<empty>')
    set(h.table_params1,'Data',{[]});
else
    vals = params.lists.(pstr1{pval1});
    set(h.table_params1,'Data',num2cell(vals));
end

if strcmp(pstr2,'<empty>')
    set(h.table_params2,'Data',{[]});
else
    vals = params.lists.(pstr2{pval2});
    set(h.table_params2,'Data',num2cell(vals));
end



function UpdateParams(h)
params = getappdata(h.ParameterBreakout,'params');

ps = params.param_type;

ps(ismember(ps,{'onset','ofset'})) = [];

if isempty(ps)
    set(h.popup_param1,'Value',1,'String','<empty>','Enable','off');
else
    set(h.popup_param1,'Value',1,'String',ps,'Enable','on');
end

if length(ps) > 1
    set(h.popup_param2,'Value',2,'String',ps,'Enable','on');
else
    set(h.popup_param2,'Value',1,'String','<empty>','Enable','off');
end



function TableCellSelect(hObj,evnt,~) %#ok<DEFNU>
% Store values of selected cells in current table UserData
ind = evnt.Indices(:,1);
d = get(hObj,'Data');
set(hObj,'UserData',cell2mat(d(ind)))


