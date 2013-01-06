function varargout = DB_NewSubjPrompt(varargin)
% h = DB_NewSubjPrompt
% h = DB_NewSubjPrompt(database)
% 
% Create New Database Subject.  If database name is not supplied as input
% then a list dialog will prompt the user to select a database.
% 
% DJS (c) 2010
% 
% Last Modified by GUIDE v2.5 24-Mar-2010 11:18:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DB_NewSubjPrompt_OpeningFcn, ...
                   'gui_OutputFcn',  @DB_NewSubjPrompt_OutputFcn, ...
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


% --- Executes just before DB_NewSubjPrompt is made visible.
function DB_NewSubjPrompt_OpeningFcn(hObject, eventdata, handles, varargin)
database = [];
if length(varargin) == 1
    database = varargin{1};
end

if isempty(database)
    dbs = DB_Connect;
    [sel,ok] = listdlg( ...
        'ListString',dbs, ...
        'PromptString','Select Database to add subject:', ...
        'Name','Select Database', ...
        'SelectionMode','single', ...
        'OKString','Select');
    if ok
        database = dbs{sel};
    end
else
    ok = 1;
end

if ok
    setappdata(hObject,'database',database);
end


handles.killfig = ~ok;

% Choose default command line output for DB_NewSubjPrompt
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = DB_NewSubjPrompt_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

if handles.killfig
    close(hObject);
else
    db = getappdata(hObject,'database');
    set(hObject,'Name',db);
end


function add_subject_Callback(hObject, eventdata, handles)
n  = get(handles.name,'String');
sp = cellstr(get(handles.species,'String'));
sp = lower(sp{get(handles.species,'Value')});
st = get(handles.strain,'String');
% d  = FixDate(get(handles.dob,'String'));
d  = datestr(get(handles.dob,'String'),'yyyy-mm-dd');
w  = get(handles.weight,'String');
sx = cellstr(get(handles.sex,'String'));
sx = sx{get(handles.sex,'Value')};
sx(2:end) = [];
sn = get(handles.notes,'String'); if isempty(sn), sn = ' '; end

database = getappdata(handles.figure1,'database');

id = myms(sprintf(['SELECT id FROM %s.subjects ', ...
          'WHERE name = "%s"'],database,n));
      
if ~isempty(id)
    warndlg(sprintf('Subject ''%s'' already exists in database (id# %d)',n,id), ...
        'Subject Exists','modal');
    return
end

mym([ ...
    'INSERT INTO {S}.subjects ', ...
    '(name, species, strain, dob, weight, sex, subject_notes) ', ...
    'VALUES ', ...
    '("{S}","{S}","{S}","{S}",{S},"{S}","{S}")'], ...
    database,n,sp,st,d,w,sx,sn);

id = myms(sprintf(['SELECT id FROM %s.subjects ', ...
          'WHERE name = "%s"'],database,n));
if isempty(id)
    warndlg(sprintf('Subject ''%s'' was not added to database correctly!',n), ...
        'Error','modal');
else
%     helpdlg(sprintf('Subject ''%s'' was added to the database.',n), ...
%         'Success');
    
    fprintf('Subject ''%s'' was added to the database.\n',n)
    close(handles.figure1)
    drawnow
end



function cancel_Callback(hObject, eventdata, handles)
close(handles.figure1);

function name_Callback(hObject, eventdata, handles)


function name_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function dob_Callback(hObject, eventdata, handles)


function dob_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function species_Callback(hObject, eventdata, handles)


function species_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function sex_Callback(hObject, eventdata, handles)


function sex_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function notes_Callback(hObject, eventdata, handles)


function notes_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function weight_Callback(hObject, eventdata, handles)


function weight_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function strain_Callback(hObject, eventdata, handles)


function strain_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


