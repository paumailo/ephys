function varargout = DB_UploadUtility(varargin)

% Last Modified by GUIDE v2.5 06-Jan-2013 10:58:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DB_UploadUtility_OpeningFcn, ...
                   'gui_OutputFcn',  @DB_UploadUtility_OutputFcn, ...
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


% --- Executes just before DB_UploadUtility is made visible.
function DB_UploadUtility_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for DB_UploadUtility
h.output = hObj;


set(hObj,'Pointer','watch');
PopulateDBs(h);
PopulateExperiments(h);
set(h.db_description,'String',db_descr);

preg = getpref('UploadUtility','datasetpath',[]);
if ~isempty(preg)
    set(h.ds_path,'String',preg);
    ds_locate_path_Callback(h.ds_locate_path,preg,h);
end

set(hObj,'Pointer','arrow');

% Update h structure
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = DB_UploadUtility_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;







%% Database
function db_newdb_Callback(hObj, ~, h) %#ok<INUSL>
newdb = inputdlg('Enter name of new Experiment.  Use ''_'' in place of spaces.','New Experiment');

if isempty(newdb),  return; end

if isdbase(newdb)
    disp(['The database ''' newdb ''' already exists on this server'])
    return
end

DB_CreateDatabase(char(newdb));

if isdbase(newdb)
    msgbox(sprintf('Database has been added: %s',char(newdb)), ...
        'New Database','modal');
    db_add_descr;
end

dbs = get(h.db_list,'String');
if isempty(dbs)
    dbs = newdb;
else
    dbs{end+1} = char(newdb);
end

set(h.db_list,'String',dbs,'Value',length(dbs));

mym('use',char(newdb));

set(h.expt_expt_subject_list,'Value',1,'String',' ');

PopulateDBs(h);
PopulateExperiments(h);

function db_list_Callback(hObj, ~, h) %#ok<DEFNU>
db = get(hObj,'String');
if isempty(db), db_newdb_Callback(h.db_newdb,[],h); end

db = cellstr(get(h.db_list,'String'));
db = db{get(h.db_list,'Value')};

mym('use',db);

setpref('UploadUtility','database',db);

set(h.db_description,'String',db_descr);

PopulateExperiments(h);


function modify_descr_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
db_add_descr;
set(h.db_description,'String',db_descr);

function db_add_descr
s = [];
try %#ok<TRYNC>
    s = myms(['SELECT CAST(infostr as CHAR) FROM dbinfo ', ...
        'WHERE infotype = "description"']);
end

if isempty(s), s = {' '}; end

s = inputdlg('Enter database description:','Database Description',10,s);
if ~isempty(s)
    mym(['REPLACE INTO dbinfo ', ...
        '(infotype,infostr) VALUES ', ...
        '("description","{S}")'], ...
        char(s));
end

function s = db_descr
s = [];
try %#ok<TRYNC>
    s = myms(['SELECT CAST(infostr as CHAR) FROM dbinfo ', ...
        'WHERE infotype = "description"']);
end

if isempty(s)
    s = ['** No description has been entered for this database.  ', ...
         'Click "Modify Description" button below to add one. **'];
else
    s = sprintf('DESCRIPTION:\n\n%s',char(s));
end

function PopulateDBs(h)
set(h.db_list, 'Enable','off');
set(h.db_newdb,'Enable','off');

% Connect to server and retrieve databases
dbs = DB_Connect;

set(h.db_list,'Value',1,'String',dbs);
rdb = getpref('UploadUtility','database',[]);
if ~isempty(rdb) && ismember(rdb,dbs)
    val = find(ismember(dbs,rdb));
else
    val = 1;
end
set(h.db_list,'Value',val);

mym('use', dbs{val});

% get electrode types
e = myms(['SELECT CONCAT(manufacturer,'' - '',product_id) AS electrodes ', ...
    'FROM db_util.electrode_types']);
set(h.ds_electrode,'String',e,'Value',1);

set(h.ds_electrode,'Value',1);

set(h.db_list, 'Enable','on');
set(h.db_newdb,'Enable','on');























%% Experiment/Subject
function expt_subject_list_Callback(hObj, ~, h) %#ok<DEFNU>
e = cellstr(get(h.expt_list,'String'));
e = e{get(h.expt_list,'Value')};
s = cellstr(get(hObj,'String'));
s = s{get(hObj,'Value')};

r = questdlg(sprintf(['This will change the subject for experiment ''%s'' to ''%s''.  ', ...
    'Are you sure you would like to continue?'],e,s),'Change Subject', ...
    'Change Subject','Cancel','Cancel');

if strcmp('Cancel',r)
    PopulateExperimentInfo(h);
    return
end

mym(['UPDATE experiments SET subject_id = ', ...
     '(SELECT id FROM subjects WHERE name = "{S}") ', ...
     'WHERE name = "{S}"'],s,e);

function expt_list_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
PopulateExperimentInfo(h);

function expt_researchers_Callback(hObj, ~, h) %#ok<DEFNU>
e = cellstr(get(h.expt_list,'String'));
e = e{get(h.expt_list,'Value')};

s = cellstr(get(hObj,'String'));
s = s(get(hObj,'Value'));

% update experiments table with researcher ids
s = cellstr(deblank(strtok(s,'-')));
cats = 'SELECT id FROM db_util.researchers WHERE initials IN (';
for i = 1:length(s)
    cats = sprintf('%s"%s",',cats,s{i});
end
cats(end) = [];  cats(end+1) = ')';
id = myms(cats);
id = num2str(id(:)','%d,'); id(end) = [];
mym(['UPDATE experiments SET researcher = "{S}" ', ...
     'WHERE name = "{S}"'],id,e);

function expt_new_expt_Callback(hObj, ~, h) 
db = get(h.db_list,'String');
if isempty(db)
    disp('You must first add or select a database before adding an experiment')
    return
end

ename = get(h.expt_list,'String');
if hObj == h.expt_new_expt
    ename = deblank(inputdlg('Enter experiment name:','New Experiment'));
    if isempty(ename), return; end 
else
    ename = ename{get(h.expt_list,'Value')};
end

exptexists = myms(sprintf('SELECT id FROM experiments WHERE name="%s"',char(ename)));
if isempty(exptexists), exptexists = 0; end

ename = char(ename);
subject_id      = get(h.expt_subject_list,'Value');
researcher      = get(h.expt_researchers,'Value');
researcher      = num2str(researcher,'%d,');
researcher(end) = [];

if exptexists
    mym(['UPDATE experiments ', ...
        'SET subject_id = {Si}, ', ...
        'researcher     = "{S}" ', ...
        'WHERE name = "{S}"'], ...
        subject_id,researcher,ename );

    fprintf('\nExperiment updated\n')
else
    mym(['INSERT INTO experiments ', ...
        'SET name       = "{S}", ', ...
        'subject_id     = {Si}, ', ...
        'researcher     = (SELECT GROUP_CONCAT(r.initials SEPARATOR '', '') ', ...
        'FROM db_util.researchers r WHERE r.id IN ({S}))'], ...
        ename,subject_id,researcher);
    fprintf('\nExperiment added\n')
end

PopulateExperiments(h);

function expt_new_subject_Callback(hObj, ~, h) %#ok<INUSL>
db = cellstr(get(h.db_list,'String'));
db = db{get(h.db_list,'Value')};
uiwait(DB_NewSubjPrompt(db));
subj = myms('SELECT name FROM subjects');
if isempty(subj), return; end
set(h.expt_subject_list,'String',subj);
set(h.expt_subject_list,'Value',length(subj));

function PopulateExperiments(h)
set(h.modify_descr,'Enable','on');

expts = myms('SELECT name FROM experiments');

if isempty(expts)
    expt_new_expt_Callback(h.expt_new_expt,[],h);
    PopulateExperiments(h);
end

set(h.expt_list,'Value',1);

if isempty(expts)
    set(h.expt_list,'String',' ');
    return
end

set(h.expt_list,'String',expts);

PopulateExperimentInfo(h)

function PopulateExperimentInfo(h)
expt_name = cellstr(get(h.expt_list,'String'));
expt_name = expt_name{get(h.expt_list,'Value')};

[id,subject_id,researcher] = myms(sprintf( ...
    ['SELECT id,subject_id,researcher ', ...
     'FROM experiments WHERE name="%s"'],expt_name));

if isempty(id),
    expt_new_subject_Callback(h.expt_new_subject, [], h)
    return
end

subjects = myms('SELECT name FROM subjects');
if ~isempty(subject_id)
    set(h.expt_subject_list,'String',subjects);
    set(h.expt_subject_list,'Value',subject_id);
end

% get researchers
rout = myms(['SELECT CONCAT(initials, '' - '', name) AS name ', ...
     'FROM db_util.researchers']);
set(h.expt_researchers,'String',rout);
rid = str2num(char(researcher)); %#ok<ST2NM>
if ~isempty(rid)
    set(h.expt_researchers, 'Value', rid);
end













%% Dataset
function ds_list_Callback(hObj, ~, h) %#ok<DEFNU>
s = get(hObj,'String');
if isempty(s) % if no valid directories have been found, prompt for new path
    ds_path_Callback(h.ds_path, [], h);
    return
end

set(h.figure1,'pointer','watch'); drawnow
set(h.ds_add_to_queue,'Enable','off');

s  = cellstr(s);
pn = get(h.ds_path,'String');
pn  = [pn s{get(hObj,'Value')}];
if pn(end) ~= '\', pn(end+1) = '\'; end

% Look for existing file structures (Spikes, MU [stream], LFP)
dtype.info   = dir([pn '*Info.mat']);
dtype.spikes = dir([pn '*SPIKES.mat']);
dtype.mu     = dir([pn '*MU.mat']);
dtype.lfp    = dir([pn '*LFP.mat']);
dtype.trials = dir([pn '*TRIALS.mat']);

% Update available datatypes
set(findobj(h,'-regexp','tag','dtype'),'Enable','off');
if ~isempty(dtype.spikes), set(h.dtype_spikes,'Enable','on'); end
if ~isempty(dtype.mu),     set(h.dtype_mu,    'Enable','on'); end
if ~isempty(dtype.lfp),    set(h.dtype_lfp,   'Enable','on'); end
% ** TO DO: TRIALS may be useful in the future for trial-based data 
%           Leave disabled and checked for now and simply use parameters
%           recorded in tank.
% if ~isempty(dtype.trials), set(h.dtype_trials,'Enable','on'); end

% Update info box
% ** TO DO: Supply more detailed info for selected dataset
infostr = '';
dtype.ptrode = cell2mat(strfind({dtype.spikes.name},'PTRODE')');
if isempty(dtype.ptrode), dtype.ptrode = false; end
if dtype.ptrode
    dtype.ptrode = dtype.ptrode + length('PTRODE');
    infostr = sprintf('%s%d Polytrode(s)\n',infostr,length(dtype.ptrode));
end
set(h.ds_info,'String',infostr);

% Update blocks list
load([pn dtype.info.name]); % load block info
bstr = cell(size(binfo));
for i = 1:length(binfo)
    bstr{i} = sprintf('%d - %s [%s]', ...
        binfo(i).id,binfo(i).protocolname,datestr(binfo(i).duration,'MM:SS'));
end
bidx = find(str2num(datestr({binfo.duration},'MM')) > 0); %#ok<ST2NM> % select blocks longer than 1 minute

set(h.ds_blocks,'String',bstr,'Value',bidx); % update listbox

set(hObj,'UserData',dtype);
ds_blocks_Callback(h.ds_blocks, [], h);
set(h.figure1,'pointer','arrow');

function ds_add_to_queue_Callback(hObj, ~, h) %#ok<DEFNU>
% Selected dataset info
dtype = get(h.ds_blocks,'UserData');

% User selected data types
flags.spikes = get(h.dtype_spikes,'Value') & ~isempty(dtype.spikes);
flags.mu     = get(h.dtype_mu    ,'Value') & ~isempty(dtype.mu);
flags.lfp    = get(h.dtype_lfp   ,'Value') & ~isempty(dtype.lfp);
flags.trials = get(h.dtype_trials,'Value') & ~isempty(dtype.trials);

% Dataset path
s  = cellstr(get(h.ds_list,'String'));
pn = get(h.ds_path,'String');
pn = [pn s{get(hObj,'Value')}];

% Selected blocks
bidx = get(h.ds_blocks,'Value');

% Restrict to selected blocks
if flags.spikes, dtype.spikes = dtype.spikes(bidx); end
if flags.mu,     dtype.mu     = dtype.mu(bidx);     end
if flags.lfp,    dtype.lfp    = dtype.lfp(bidx);    end
% if flags.trials, dtype.trials = dtype.trials(bidx); end
% .
% .
% .

function ds_path_Callback(hObj, ~, h) %#ok<INUSL>
% Manually locate parent directory
ds_locate_path_Callback(h.ds_locate_path, [], h)

function ds_locate_path_Callback(hObj, pn, h) %#ok<INUSL>
% optionally pass in a path string for pn

if isempty(pn)
    % Manually locate parent directory
    pn = uigetdir([],'Locate Dataset Parent Directory');
    if ~pn, return; end
end

setpref('UploadUtility','datasetpath',pn);

if pn(end) ~= '\', pn(end+1) = '\'; end
set(h.ds_path,'String',pn);

% Search subdirectories for compatable file structures
sd = dir(pn);
sd(1:2) = []; % first two are always '.' and '..'
isd = [sd.isdir]; sd(~isd) = []; % ignore immediate local files
sd = {sd.name}; % subdirectory names
ind = false(size(sd));
for i = 1:length(sd) % loop through subdirectories to find valid 'Info.mat' files
    ind(i) = isempty(dir([pn sd{i} '\' sd{i} '_Info.mat']));
end
sd(ind) = [];
set(h.ds_list,'Value',length(sd),'String',sd);

function ds_blocks_Callback(hObj, ~, h)
s = get(hObj,'Value');
if isempty(s)
    set(h.ds_add_to_queue,'Enable','off');
else
    set(h.ds_add_to_queue,'Enable','on');
end







%% Upload
function upload_data_Callback(hObj, ~, h)


function upload_remove_Callback(hObj, ~, h)


function dtype_trials_Callback(hObject, eventdata, handles)
