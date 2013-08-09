function varargout = RIF_analysis(varargin)
% RIF_analysis(unit_id);
%
% DJS 2013

% Edit the above text to modify the response to help RIF_analysis

% Last Modified by GUIDE v2.5 08-Aug-2013 16:02:50

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

if length(varargin) == 1
    h.unit_id = varargin{1};
else
    ids = getpref('DB_BROWSER_SELECTION');
    h.unit_id = ids.units;
end

CreateAnalysisRIFtable;

InitializeOptions(h);

RefreshPlots(h);



% --- Outputs from this function are returned to the command line.
function varargout = RIF_analysis_OutputFcn(~, ~, h) 
% Get default command line output from h structure
varargout{1} = h.output;





function h = UpdateIO(unit_id,h)
origpos = [];
if isfield(h,'DATA') && isfield(h.DATA,'IOfh')
    origpos = get(h.DATA.IOfh,'position');
end
h.DATA.IOfh = IO_analysis(unit_id);
if ~isempty(origpos)
    set(h.DATA.IOfh,'position',origpos);
end


function cfg = GetCFG(h)
opts     = get(h.table_options,'data');
varnames = get(h.table_options,'UserData');
for i = 1:length(varnames)
    val = str2num(opts{i,2}); %#ok<ST2NM>
    if isempty(val)
        val = opts{i,2};
    end
    cfg.(varnames{i}) = val;
end
cfg.plotresult = false;

function h = UpdatePSTH(unit_id,h)
cfg = GetCFG(h);

if isfield(h,'PSTH') && isfield(h.PSTH,'fh')
    cfg.fh = h.PSTH.fh;
end

[h.PSTH.fh,h.PSTH.sh,h.PSTH.R,h.PSTH.data] = DB_PlotPSTH(unit_id,cfg);



function RefreshPlots(h)
h = UpdatePSTH(h.unit_id,h);

r = mym('SELECT unit_id FROM analysis_RIF WHERE unit_id = {Si}',h.unit_id);
if isempty(r.unit_id)
    EstimateFeatures(h);
    h = UpdatePSTH(h.unit_id,h);
end

h = UpdateIO(h.unit_id,h);
guidata(h.figure1,h);

function InitializeOptions(h)
defaultopts = {'View Window',   '-0.05 0.1';    ...
               'bin size',      '0.001';          ...
               'Resp Window',   '0 0.05';       ...
               'Base Window',   '-0.05 0';      ...
               'Hist func',     'mean';         ...
               'convolve',      'true';           ...
               'kernel size',   '5';              ...
               'resample',      '1';              ...
               'alpha',         '0.025';          ...
               'type',          'larger'};

varnames = {'win','binsize','rwin','bwin','shapefunc','convolve','kernel', ...
    'resamp','ksalpha','kstype'};
           
           
opts = getpref('RIF_analysis','OPTIONS',defaultopts);

if numel(opts) ~= numel(defaultopts); opts = defaultopts; end

set(h.table_options,'data',opts,'UserData',varnames);





function AdjustFeature(hObj,h) %#ok<DEFNU>
type = get(hObj,'string');

figure(h.PSTH.fh);
[x,~] = ginput(1);

ax = get(h.PSTH.fh,'CurrentAxes');

ind = h.PSTH.sh == ax;

level = h.PSTH.R.level(ind);

switch type
    case 'Adjust Onset'
        mym(['UPDATE analysis_rif ', ...
             'SET onset_latency = {S} ', ...
             'WHERE unit_id = {Si} ', ...
             'AND level = {S}'], ...
             num2str(x,'%f'),h.unit_id,num2str(level,'%f'));
        
    case 'Adjust Offset'
        mym(['UPDATE analysis_rif ', ...
             'SET offset_latency = {S} ', ...
             'WHERE unit_id = {Si} ', ...
             'AND level = {S}'], ...
             num2str(x,'%f'),h.unit_id,num2str(level,'%f'));
        
    case 'Adjust Peak'
        data = h.PSTH.data{1}(:,ind);
        vals = h.PSTH.data{2};
        peakval = interp1(vals{1},data,x,'nearest');
        mym(['UPDATE analysis_rif ', ...
             'SET peak_fr = {S}, ', ...
             'peak_latency = {S} ', ...
             'WHERE unit_id = {Si} ', ...
             'AND level = {S}'], ...
             num2str(peakval,'%f'),num2str(x,'%f'), ...
             h.unit_id,num2str(level,'%f'));
        
end
    
RefreshPlots(h);

    
function EstimateFeatures(h)
set(h.figure1,'pointer','watch'); drawnow
data = h.PSTH.data{1};
vals = h.PSTH.data{2};

cfg = GetCFG(h);
gw = gausswin(cfg.kernel);
for i = 1:size(data,2)
    if cfg.convolve
        mv = max(data(:,i));
        data(:,i) = conv(data(:,i),gw,'same');
        data(:,i) = data(:,i) / max(data(:,i)) * mv;
    end
    t = ComputePSTHfeatures(vals{1},data(:,i),cfg); 
    R.unit_id(i)         = h.unit_id;
    R.level(i)           = vals{2}(i);
    R.onset_latency(i)   = t.onset.latency;
    R.rising_slope(i)    = t.onset.slope;
    R.offset_latency(i)  = t.offset.latency;
    R.falling_slope(i)   = t.offset.slope;
    R.peak_fr(i)         = t.peak.fr;
    R.peak_latency(i)    = t.peak.latency;
    R.histarea(i)        = t.histarea;
    R.ks_p(i)            = t.stats.p;
    R.ks_stat(i)         = t.stats.ksstat;
    R.prestim_meanfr(i)  = t.baseline.meanfr;
    R.poststim_meanfr(i) = t.response.meanfr;
end
h.PSTH.R = R;
guidata(h.figure1,h);
UpdateDB(h);
RefreshPlots(h)
set(h.figure1,'pointer','arrow'); drawnow


function UpdateDB(h)

R = h.PSTH.R;

for i = 1:length(R.unit_id)
%     if ~isfield(R,'onset'), continue; end
%     if isempty(R.onset_latency),  R.onset.latency = -1;  end
%     if isempty(R.offset.latency), R.offset.latency = -1; end
%     if isempty(R.peak.latency),   R.peak.latency = -1;   end
%     if isempty(R.peak.value),     R.peak.value = -1;     end
%     if isnan(R.response.meanfr),  R.response.meanfr = -1; end
%     if isnan(R.onset.slope),      R.onset.slope = 0;     end
%     if isnan(R.offset.slope),     R.offset.slope = 0;    end
%     if isinf(R.onset.slope),      continue;              end
    rstr = sprintf(['REPLACE analysis_rif ', ...
        '(unit_id,level,onset_latency,offset_latency,peak_latency,', ...
        'rising_slope,falling_slope,peak_fr,area,', ...
        'ks_p,ks_stat,prestim_meanfr,poststim_meanfr) VALUES ', ...
        '(%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f)'], ...
        R.unit_id(i),R.level(i),R.onset_latency(i),R.offset_latency(i), ...
        R.peak_latency(i),R.rising_slope(i),R.falling_slope(i),R.peak_fr(i), ...
        R.histarea(i),R.ks_p(i),R.ks_stat(i),R.prestim_meanfr(i),R.poststim_meanfr(i));
    mym(rstr)
end


function figure1_CloseRequestFcn(~, ~, h) %#ok<DEFNU>
opts = get(h.table_options,'Data');
setpref('RIF_analysis','OPTIONS',opts);

delete(hObject);




function CreateAnalysisRIFtable
cstr = ['CREATE TABLE IF NOT EXISTS analysis_rif ( ', ...
  'unit_id INT UNSIGNED NOT NULL ,', ...
  'level FLOAT NOT NULL ,', ...
  'onset_latency FLOAT NULL ,', ...
  'offset_latency FLOAT NULL ,', ...
  'peak_latency FLOAT NULL ,', ...
  'rising_slope FLOAT NULL ,', ...
  'falling_slope FLOAT NULL ,', ...
  'peak_fr FLOAT NULL ,', ...
  'area FLOAT NULL ,', ...
  'ks_p FLOAT NULL ,', ...
  'ks_stat FLOAT NULL ,', ...
  'prestim_meanfr FLOAT NULL ,', ...
  'poststim_meanfr FLOAT NULL ,', ...
  'timestamp DATETIME NULL DEFAULT CURRENT_TIMESTAMP ,', ...
  'PRIMARY KEY (unit_id, level))'];

mym(cstr);
