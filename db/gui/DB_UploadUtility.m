function varargout = DB_UploadUtility(varargin)

% Last Modified by GUIDE v2.5 13-Jan-2013 14:37:56

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

set(hObj,'Pointer','watch'); drawnow
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

set(h.expt_subject_list,'Value',1,'String',' ');

PopulateDBs(h);
PopulateExperiments(h);

function db_list_Callback(hObj, ~, h) %#ok<DEFNU>
% Database list, update Experiment Info
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
if ~myisopen, dbs = DB_Connect; else dbs = dblist; end

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
        'SET name   = "{S}", ', ...
        'subject_id = {Si}, ', ...
        'researcher = (SELECT GROUP_CONCAT(r.initials SEPARATOR '', '') ', ...
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
% Dataset was selected, update block list
s = get_string(hObj);
if isempty(s), return; end

set(h.figure1,'pointer','watch'); 
set(h.ds_add_to_queue,'Enable','off'); drawnow

pn = get(h.ds_path,'String');
if pn(end) ~= '\', pn(end+1) = '\'; end

tank = get_string(h.ds_list);
[tank,sup] = strtok(tank,' [');
haspools = ~isempty(sup);

% get block info
cfg = [];
cfg.tank = fullfile(pn,tank);
BlockInfo = getTankData(cfg);

bstr = cell(size(BlockInfo));
for i = 1:length(BlockInfo)
    BlockInfo(i).haspools = haspools;
    B = BlockInfo(i);
    bstr{i} = sprintf('%s - %s [%s]', ...
        B.name,B.protocolname,datestr(B.duration,'MM:SS'));
end
bidx = find(str2num(datestr({BlockInfo.duration},'MM')) > 0); %#ok<ST2NM> % select blocks longer than 1 minute
if ~any(bidx), bidx = 1:length(BlockInfo); end

% Check for available data types
if isempty(BlockInfo(bidx(1)).Snip)
    set(h.dtype_spikes,'Value',0,'Enable','off');
else
    set(h.dtype_spikes,'Value',1,'Enable','on');
end
if isempty(BlockInfo(bidx(1)).Wave)
    set(h.dtype_lfp,'Value',0,'Enable','off');
else
    set(h.dtype_spikes,'Value',1,'Enable','on');
end

set(h.ds_blocks,'String',bstr,'Value',bidx,'UserData',BlockInfo); % update listbox


ds_blocks_Callback(h.ds_blocks, [], h);
set(h.figure1,'pointer','arrow');








function ds_add_to_queue_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
Queue = getappdata(h.figure1,'UPLOAD_QUEUE');

% Gather all info for uploading
Q.BlockInfo  = getappdata(h.figure1,'QBlockInfo');

if isempty(Q.BlockInfo), return; end

Q.experiment = get_string(h.expt_list);
Q.hasSpikes  = get(h.dtype_spikes,'Value');
Q.hasWaves   = get(h.dtype_lfp,'Value');
Q.condition  = get(h.ds_condition,'String');
Q.tanknotes  = get(h.ds_notes,'String'); 
Q.electrode  = get_string(h.ds_electrode);
Q.elecdepth  = str2num(get(h.ds_depth,'String')); %#ok<ST2NM>
Q.electarget = get(h.ds_target,'String');

if isempty(Q.condition),  Q.condition = ' '; end
if isempty(Q.tanknotes),  Q.tanknotes = ' '; end
if isempty(Q.electarget), Q.electarget = ' '; end

tank = get_string(h.ds_list);

[Q.tank,ac] = strtok(tank,' [');
Q.hasACpools = ~isempty(ac);

if isempty(Queue)
    Queue = Q;
else
    Queue(end+1) = Q;
end

setappdata(h.figure1,'UPLOAD_QUEUE',Queue);

% Update Queue
qstr = get(h.upload_queue,'String');
qstr{end+1} = ['TANK: ' Q.tank ' | BLOCKS: ' num2str([Q.BlockInfo.id])];
set(h.upload_queue,'String',qstr);



function ds_path_Callback(hObj, ~, h) %#ok<DEFNU,INUSL>
% Manually locate parent directory
ds_locate_path_Callback(h.ds_locate_path, [], h)

function ds_locate_path_Callback(hObj, pn, h) %#ok<INUSL>
% optionally pass in a path string for pn

if isempty(pn)
    % Manually locate parent directory
    pn = uigetdir([],'Locate Tank Parent Directory');
    if ~pn, return; end
end

setpref('UploadUtility','datasetpath',pn);

if pn(end) ~= '\', pn(end+1) = '\'; end
set(h.ds_path,'String',pn);

Tanks = CheckForTanks(pn);

% Find valid pooled datasets
ACpath = 'C:\AutoClass_Files\AC2_RESULTS\';
ACsubdirs = dir(ACpath);
ACsubdirs = ACsubdirs([ACsubdirs.isdir]);
ACsubdirs(ismember({ACsubdirs.name},{'.','..'})) = [];
pooledChs = cell(size(ACsubdirs)); hasPools = false(size(ACsubdirs));
for i = 1:length(ACsubdirs)
    pooledChs{i} = dir(fullfile(ACpath,ACsubdirs(i).name,'*POOLS.mat'));
    hasPools(i)  = ~isempty(pooledChs{i});
end
ACtanks = {ACsubdirs.name};
idx = find(ismember(Tanks,ACtanks));
for i = idx
    Tanks{i} = sprintf('%s [%d POOLS]',Tanks{i},length(pooledChs{i}));
end
set(h.ds_list,'Value',length(Tanks),'String',Tanks);

function ds_blocks_Callback(hObj, ~, h)
v = get(hObj,'Value');
if isempty(v) % no blocks are selected
    set(h.ds_add_to_queue,'Enable','off');
else
    set(h.ds_add_to_queue,'Enable','on');
end

BlockInfo = get(hObj,'UserData');

BlockInfo = BlockInfo(v);

setappdata(h.figure1,'QBlockInfo',BlockInfo);









%% Upload
function upload_data_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
Queue = getappdata(h.figure1,'UPLOAD_QUEUE');
if isempty(Queue), return; end

curdb = get_string(h.db_list);

if ~myisopen, DB_Connect; end
if ~strcmp(dbcurr,curdb), dbopen(curdb); end

% allobjs = get(h.figure1,'Children');
% set(allobjs,'Enable','off');

for i = 1:length(Queue)
    Q = Queue(i);
    
    B = Q.BlockInfo;
    
    exptid = myms(sprintf('SELECT id FROM experiments WHERE name = "%s"',Q.experiment));
    
    % Delete any existing data for this tank
    oldtid = myms(sprintf('SELECT id FROM tanks WHERE name = "%s"',Q.tank));
    if ~isempty(oldtid)
        oldbid = myms(sprintf('SELECT id FROM blocks WHERE tank_id = %d',oldtid));
        for b = 1:length(oldbid)
            oldcid = myms(sprintf('SELECT id FROM channels WHERE block_id = %d',oldbid(b)));
            mym('DELETE IGNORE FROM channels WHERE block_id = {Si}',oldbid(b));
            mym('DELETE FROM protocols WHERE block_id = {Si}',oldbid(b));
            if ~isempty(oldcid)
                s = sprintf('%d,',oldcid); s(end) = [];
                mym('DELETE IGNORE FROM wave_data WHERE channel_id IN ({S})',s);
                olduid = myms(sprintf('SELECT id FROM units WHERE channel_id IN (%s)',s));
                if ~isempty(olduid)
                    s = sprintf('%d,',olduid); s(end) = [];
                    mym('DELETE IGNORE FROM spike_data WHERE unit_id IN ({S})',s);
                end
            end

        end
        mym('DELETE IGNORE FROM tanks WHERE id = {Si}',oldtid);
        mym('DELETE IGNORE FROM blocks WHERE tank_id = {Si}',oldtid);
    end
    
    
    
    
    
    
    % update tanks
    spikefs = 0; wavefs = 0;
    if Q.hasSpikes, spikefs = B(1).Snip.fsample; end
    if Q.hasWaves,  wavefs  = B(1).Wave.fsample; end
    
    mym(['INSERT tanks (exp_id,tank_condition,tank_date,name,spike_fs,wave_fs,tank_notes) ', ...
        'VALUES ({Si},"{S}","{S}","{S}",{S},{S},"{S}")'], ...
        exptid,Q.condition,datestr(B(1).date,'yyyy-mm-dd'),Q.tank, ...
        num2str(spikefs,'%0.5f'),num2str(wavefs,'%0.5f'),Q.tanknotes);
    tid = myms(sprintf('SELECT id FROM tanks WHERE name = "%s"',Q.tank));
    
    % update electrode
    mym(['INSERT electrodes (tank_id,type,depth,target) VALUES ', ...
        '({Si},(SELECT id FROM db_util.electrode_types WHERE STRCMP(product_id,"{S}")),' ...
        '{S},"{S}")'],tid,Q.electrode,Q.elecdepth,Q.electarget);
    
    for j = 1:length(B)
        % update blocks
        pid = myms(sprintf('SELECT pid FROM db_util.protocol_types WHERE alias = "%s"',...
            B(j).protocolname));
        mym(['REPLACE blocks (tank_id,block,protocol,block_date,block_time) VALUES ', ...
            '({Si},{Si},{Si},"{S}","{S}")'], ...
            tid,B(j).id,pid,datestr(B(j).date,'yyyy-mm-dd'),B(j).begintime);
        
        % update protocols
        blockid = myms(sprintf('SELECT id FROM blocks WHERE tank_id = %d AND block = %d',tid,B(j).id));
        
        % remove any existing protocol for this block id
        fprintf('\tUploading protocol data for block %d (%d of %d) ...',B(j).id,j,length(B))

        
        
        
        
        
        % get parameter codes from db_util.param_types; insert new codes if does not exist
        parcode = nan(size(B(j).paramspec));
        for k = 1:length(B(j).paramspec)
            checkpar = myms(sprintf('SELECT id FROM db_util.param_types WHERE param = "%s"',B(j).paramspec{k}));
            if isempty(checkpar)
                mym('INSERT db_util.param_types (param) VALUE ("{S}")',B(j).paramspec{k});
                parcode(k) = myms(sprintf('SELECT id FROM db_util.param_types WHERE param = "%s"',B(j).paramspec{k}));
            else
                parcode(k) = checkpar;
            end
        end
        % create matrix for protocol
        param_id      = repmat(1:size(B(j).epochs,1),size(B(j).epochs,2),1);
        param_type    = repmat(parcode(:),1,size(B(j).epochs,1));
        param_value   = B(j).epochs';
        nepochs       = numel(B(j).epochs);
        protdata(:,1) = repmat(blockid,nepochs,1);
        protdata(:,2) = param_id(:);
        protdata(:,3) = param_type(:);
        protdata(:,4) = param_value(:);
        
        % upload each row of the protocol (LOAD FILE may be faster)
        
        for k = 1:size(protdata,1)
            mym(['INSERT protocols (block_id,param_id,param_type,param_value) VALUES ', ...
                '({Si},{Si},{Si},{S})'], ...
                protdata(k,1),protdata(k,2),protdata(k,3),num2str(protdata(k,4),'%0.5f'));
        end
        clear protdata
        fprintf(' done\n')
        
        % update channels
        if ~isempty(B(j).Wave)
            channels = B(j).Wave.channels;
        else
            channels = B(j).Snip.channels;
        end
        fprintf('Adding %d channels ... ',length(channels))
        for k = channels
            mym(['INSERT channels (block_id,channel,target) VALUES ', ...
                '({Si},{Si},"{S}")'],blockid,k,Q.electarget);
        end
        fprintf('done\n')
        
        % update units
        if Q.hasSpikes
            cfg = [];
            cfg.tank = B(j).tank;
            cfg.blocks = B(j).id;
            cfg.datatype = 'Spikes';
            Spikes = getTankData(cfg);
            
            %         ACpath = 'C:\AutoClass_Files\AC2_RESULTS\';
            for k = 1:length(channels)
                fprintf('\tUploading spikes on channel %d (%d of %d) ... ',channels(k),k,length(channels))
                channel_id = myms(sprintf(['SELECT id FROM channels ', ...
                    'WHERE channel = %d AND block_id = %d'],channels(k),blockid));
                
                % Check if pools were made with AutoClass Pooling_GUI2
                %             ACfn = sprintf('%s_Ch_%d_POOLS.mat',Q.tank,channels(j));
                %             ACfn = fullfile(ACpath,Q.tank,ACfn);
                %             if exist(ACfn,'file')
                % NEED TO UPDATE POOLING_GUI FILE STRUCTURE TO  INCLUDE
                % BLOCK ID VECTOR **************************************
                % AutoClass Pools found - Use these
                %                 AC        = load(ACfn);
                %                 ACsnipfn  = sprintf('%s_%03d_SNIP.mat',Q.tank,channels(j));
                %                 ACsnipfn  = fullfile(ACpath,Q.tank,ACsnipfn);
                %                 ACsnip    = load(ACsnipfn);
                %                 ACblocks  = ACsnip.cfg.TankCFG.blocks;
                % %                 spchanind = [Spikes.channel]==channels(j);
                %                 blockind  = ismember(ACblocks,[B.id]);
                %                 blockspikes = ACsnip.cfg.Spikes.blockspikes(blockind);
                %                 POOLS = [];
                %                 for k = 1:length(blockspikes)
                %                     p = length(POOLS);
                %                     POOLS(p+1:p) = AC.POOLS(
                %                 POOLS = AC.POOLS;
                %             else
                % AutoClass Pools NOT found - Use tank sort code
                chind = [Spikes.channel] == channels(k);
                POOLS = cell2mat(Spikes(chind).sortcode(:));
                %             end
                
                
                uPOOLS = unique(POOLS);
                pw = cell2mat(Spikes(k).waveforms(~isempty(Spikes(k).waveforms))');
                st = cell2mat(Spikes(k).timestamps(:));
                for up = uPOOLS
                    uind = up == POOLS;
                    pwaveform = mean(pw(uind,:),1);
                    pstddev   = std(pw(uind,:),1);
                    
                    mym(['INSERT units (channel_id,pool,unit_count,pool_waveform,pool_stddev) VALUES ', ...
                        '({Si},{Si},{Si},"{S}","{S}")'], ...
                        channel_id,up,sum(uind),num2str(pwaveform),num2str(pstddev));
                    
                    uid = myms(sprintf(['SELECT id FROM units ', ...
                        'WHERE channel_id = %d AND pool = %d'], ...
                        channel_id,up));
                    
                    
                    % update spike_data
                    uidx = find(uind);
                    for kk = 1:length(uidx)
                        mym('INSERT spike_data (unit_id,spike_time) VALUES ({Si},{S})', ...
                            uid,st(uidx(kk)));
                    end
                end
                fprintf('done\n')
            end
                        
        end
    end
    
    
    if ~isempty(B(j).Wave)
        % updata wave_data
        DB_UploadWaveData(Q.tank,B(j));
        
    end
end
fprintf('\nCompleted upload at %s\n\n',datestr(now,'dd-mmm-yyyy HH:MM:SS'))
% set(allobjs,'Enable','on');

function upload_remove_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
Queue = getappdata(h.figure1,'UPLOAD_QUEUE');
if isempty(Queue), return; end

v = get(h.upload_queue,'Value');
Queue(v) = [];
setappdata(h.figure1,'UPLOAD_QUEUE',Queue);

qstr = get(h.upload_queue,'String');
qstr(v) = [];
if isempty(qstr), v = 1; elseif v > length(qstr),v = length(qstr); end
set(h.upload_queue,'Value',v,'String',qstr);
















