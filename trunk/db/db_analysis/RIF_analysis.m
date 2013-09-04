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

n = {'level','onsetlat','offsetlat','peaklat','risingslope','fallingslope', ...
    'peakfr','area','ksp','ksstat','prestimmeanfr','poststimmeanfr'};
d = {'Stimulus level','Onset latency','Offset latency','Peak latency','Rising slope', ...
'Falling slope','Peak firing rate','Calculated area','Kolmogorov-Smirnov p value', ...
'Kolmogorov-Smirnov statistic','Prestimulus mean firing rate','Poststimulus mean firing rate'};
DB_CheckAnalysisParams(n,d);


if length(varargin) == 1
    h.unit_id = varargin{1};
else
    ids = getpref('DB_BROWSER_SELECTION');
    h.unit_id = ids.units;
end

InitializeOptions(h);

h = RefreshPlots(h);

guidata(hObj, h);


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
    if isempty(val), val = opts{i,2}; end
    cfg.(varnames{i}) = val;
end
cfg.plotresult = false;

function h = UpdatePSTH(unit_id,h)
cfg = GetCFG(h);

if isfield(h,'PSTH') && isfield(h.PSTH,'fh')
    cfg.fh = h.PSTH.fh;
end

[h.PSTH.fh,h.PSTH.sh,h.PSTH.R,h.PSTH.data] = DB_PlotPSTH(unit_id,cfg);



function h = RefreshPlots(h)
h = UpdatePSTH(h.unit_id,h);

r = h.PSTH.R;
if isempty(r)
    EstimateFeatures(h);
    h = UpdatePSTH(h.unit_id,h);
end

t = mym('SELECT id FROM v_unit_props WHERE unit_id = {Si} AND group_id REGEXP "dBRIF$"',h.unit_id);
if isempty(t.id), UpdateDB(h.unit_id,h); end

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
[x,~,b] = ginput(1);
if b ~= 1, return; end

ax = get(h.PSTH.fh,'CurrentAxes');
ind = h.PSTH.sh == ax;
R = DB_GetUnitProps(h.unit_id,'dBRIF$');
R.level = cellfun(@sscanf,R.group_id,repmat({'%f'},size(R.group_id)));
R.level = R.level(:)';
level = R.level(ind);

switch type
    case 'Adjust Onset'
        T.onsetlat = x;
         
    case 'Adjust Offset'
        T.offsetlat = x;
        
    case 'Adjust Peak'
        data = h.PSTH.data{1}(:,ind);
        vals = h.PSTH.data{2};
        peakval = interp1(vals{1},data,x,'nearest');
        T.peaklat = x;
        T.peakfr = peakval;
end
T.level = num2str(level,'%0.2fdBRIF');
DB_UpdateUnitProps(h.unit_id,T,'level',true);

RefreshPlots(h);

    
function EstimateFeatures(h)
set(h.figure1,'pointer','watch'); drawnow
data = h.PSTH.data{1};
vals = h.PSTH.data{2};

cfg = GetCFG(h);
kernel = gausswin(cfg.kernel);
% kernel = blackman(cfg.kernel);
for i = 1:size(data,2)
    if cfg.convolve
        mv = max(data(:,i));
        data(:,i) = conv(data(:,i),kernel,'same');
        data(:,i) = data(:,i) / max(data(:,i)) * mv;
    end
    data(isnan(data(:,i)),i) = 0;
    t = ComputePSTHfeatures(vals{1},data(:,i),cfg); 
    R.unit_id(i)        = h.unit_id;
    R.level(i)          = vals{2}(i);
    R.onsetlat(i)       = t.onset.latency;
    R.risingslope(i)    = t.onset.slope;
    R.offsetlat(i)      = t.offset.latency;
    R.fallingslope(i)   = t.offset.slope;
    R.peakfr(i)         = t.peak.fr;
    R.peaklat(i)        = t.peak.latency;
    R.area(i)           = t.histarea;
    R.ksp(i)            = t.stats.p;
    R.ksstat(i)         = t.stats.ksstat;
    R.prestimmeanfr(i)  = t.baseline.meanfr;
    R.poststimmeanfr(i) = t.response.meanfr;
end
h.PSTH.R = R;
guidata(h.figure1,h);
UpdateDB(h.unit_id,h);
RefreshPlots(h);
opts = get(h.table_options,'Data');
setpref('RIF_analysis','OPTIONS',opts);
set(h.figure1,'pointer','arrow'); drawnow


function UpdateDB(unit_id,h)
R = h.PSTH.R;
if isfield(R,'unit_id'), R = rmfield(R,'unit_id'); end
if isfield(R,'level')
    R.level = cellstr(num2str(R.level(:),'%0.2fdBRIF'));
else
    R.level = R.group_id;
    R = rmfield(R,'group_id');
end
DB_UpdateUnitProps(unit_id,R,'level',true);

% also delete IO data
dltstr = ['DELETE FROM up USING unit_properties AS up ', ...
          'INNER JOIN db_util.analysis_params AS ap ', ...
          'ON ap.id = up.param_id ', ...
          'WHERE up.unit_id = %d ', ...
          'AND up.group_id = "%s" '];
mym(sprintf(dltstr,unit_id,'RIFIO'));




function figure1_CloseRequestFcn(hObj, ~, ~) %#ok<DEFNU>
delete(hObj);










