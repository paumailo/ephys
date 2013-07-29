function varargout = CalibrationUtil(varargin)
% varargout = CalibrationUtil(varargin)
%
% DJS 2013

% Edit the above text to modify the response to help CalibrationUtil

% Last Modified by GUIDE v2.5 29-Jul-2013 13:09:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CalibrationUtil_OpeningFcn, ...
                   'gui_OutputFcn',  @CalibrationUtil_OutputFcn, ...
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


% --- Executes just before CalibrationUtil is made visible.
function CalibrationUtil_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for CalibrationUtil
h.output = hObj;

% Update h structure
guidata(hObj, h);



% UIWAIT makes CalibrationUtil wait for user response (see UIRESUME)
% uiwait(h.CalibrationUtil);


% --- Outputs from this function are returned to the command line.
function varargout = CalibrationUtil_OutputFcn(hObj, ~, h)  %#ok<INUSL>
% Get default command line output from h structure
varargout{1} = h.output;
























function CheckNumeric(hObj)  %#ok<DEFNU>
v = str2num(get(hObj,'String')); %#ok<ST2NM>
if ~isscalar(v)
    warndlg('Scalar values only','Invalid entry');
    set(hObj,'String',v(1));
end



































% Setup --------------------------
function stim_type_Callback(hObj, ~, h) %#ok<DEFNU>
ST = get(hObj,'String');
v = ST{get(hObj,'Value')};

switch v
    case 'Tone'
        % prompt properties
        prompt = {'Frequencies (Hz):'};
        name   = 'Tone Calibration';
        dflt   = {'1000:100:42000'};
        
    case 'Noise'
        prompt = {'Highpass (Hz)','Lowpass (Hz)'};
        name   = 'Noise';
        dflt   = {'7127.2,10090,14254,20158,28509'; ...
                  '8979.7,12700,17959,25398,35919'};
        
    case 'Click'
        
end

opts.Resize = 'on';
opts.WindowStyle = 'modal';
opts.Interpreter = 'none';
res = inputdlg(prompt,name,1,dflt,opts);


if isempty(res)
    i = find(ismember(ST,h.cfg.stimtype));
    set(hObj,'Value',i);
    return
end


switch v
    case 'Tone'
        cfg.stimtype = 'Tone';
        cfg.freqs    = str2num(char(res)); %#ok<ST2NM>
        
        % data table properties
        colname  = {'Freq','Level (1V)','AdjV'};
        colform  = {'numeric','numeric','numeric'};
        dfltdata = num2cell([cfg.freqs(:) nan(length(cfg.freqs),2)]);
        

    case 'Noise'
        cfg.stimtype = 'Noise';
        cfg.hp = str2num(res{1}); %#ok<ST2NM>
        cfg.lp = str2num(res{2}); %#ok<ST2NM>
        
        % data table properties
        colname = {'HP','LP','Level (1V)','AdjV'};
        colform = {'numeric','numeric','numeric','numeric'};
        dfltdata = num2cell([cfg.hp(:) cfg.lp(:) nan(length(cfg.hp),2)]);
        
    case 'Click'
        
end

set(h.data_table,'ColumnName',colname,'ColumnFormat',colform,'Data',dfltdata);

h.cfg = cfg;
guidata(h.CalibrationUtil,h);

set(h.run_calibration,'Enable','on');

function cfg = GatherCFG(h)
% Gather configuration from GUI

if isfield(h,'cfg'), cfg = h.cfg; end

v = get(h.connection_type,'String');
cfg.contype = v{get(h.connection_type,'Value')};

v = get(h.stim_module,'String');
stim.mod   = v{get(h.stim_module,'Value')};
stim.modid = get(h.stim_module_id,'Value');
stim.fsid  = get(h.stim_module_fs,'Value')+1;

v = get(h.acq_module,'String');
acq.mod   = v{get(h.acq_module,'Value')};
acq.modid = get(h.acq_module_id,'Value');
acq.fsid  = 5;

% check for single module mode
cfg.single_mod = strcmp(stim.mod,acq.mod) & stim.modid == acq.modid;
if cfg.single_mod
    stim.rpfile = 'STACQ_Tone_Calibration.rcx';
    fprintf('Using single module mode\n')
else
    stim.rpfile = 'STIM_Tone_Calibration.rcx';
    acq.rpfile  = 'ACQ_Calibration.rcx';
end

stim.rpfile = which(stim.rpfile);
cfg.stim = stim;

if isfield(acq,'rpfile')
    acq.rpfile  = which(acq.rpfile);
end
cfg.acq  = acq;

% reference info for header
cfg.ref.rms   = str2num(get(h.ref_rms,'String'))/1000; %#ok<ST2NM>
cfg.ref.level = str2num(get(h.ref_dB,'String')); %#ok<ST2NM>
cfg.ref.norm  = str2num(get(h.norm_level,'String')); %#ok<ST2NM>

function run_calibration_Callback(hObj, ~, h) %#ok<DEFNU>
if ~isdir('CalUtil_RPvds')
    errordlg('RPvds calibration files directory could not be found on MATLAB search path', ...
        'Calibration');
end

global StimRP AcqRP

switch get(hObj,'String')
    case 'Halt'
        CloseConnection(StimRP,AcqRP);
        disp('Calibration interrupted by user')
        set(hObj,'String','Run');
        
    case 'Run'
        cfg = GatherCFG(h);
        
        ST = get(h.stim_type,'String');
        ST = ST{get(h.stim_type,'Value')};
        
        switch ST
            case 'Tone'
                if cfg.single_mod
                    cfg.stim.rpfile = 'STACQ_Tone_Calibration';
                    cfg.acq.rpfile  = 'STACQ_Tone_Calibration';
                else
                    cfg.stim.rpfile = 'STIM_Tone_Calibration';
                    cfg.acq.rpfile  = 'ACQ_Calibration';
                end
                calfunc = @CalibrateTones;
                
                
            case 'Noise'
                if cfg.single_mod
                    cfg.stim.rpfile = 'STACQ_FiltNoise_Calibration';
                    cfg.acq.rpfile  = 'STACQ_FiltNoise_Calibration';
                else
                    cfg.stim.rpfile = 'STIM_FiltNoise_Calibration';
                    cfg.acq.rpfile  = 'ACQ_Calibration';
                end
                calfunc = @CalibrateNoise;
                
            case 'Click'
                disp('Click calibration not yet implemented')
                return
        end
        
        if cfg.single_mod && isequal(cfg.stim.mod,'RX6')
            cfg.stim.rpfile = [cfg.stim.rpfile '_RX6'];   
        end
        if cfg.single_mod && isequal(cfg.acq.mod,'RX6')
            cfg.acq.rpfile = [cfg.acq.rpfile '_RX6'];   
        end
        
        if cfg.single_mod && isequal(cfg.stim.mod,'RZ6')
            cfg.stim.rpfile = [cfg.stim.rpfile '_RZ6'];   
        end
        if cfg.single_mod && isequal(cfg.acq.mod,'RZ6')
            cfg.acq.rpfile = [cfg.acq.rpfile '_RZ6'];   
        end
        
        cfg.stim.rpfile = [cfg.stim.rpfile '.rcx'];
        cfg.acq.rpfile  = [cfg.acq.rpfile  '.rcx'];
        
        cfg.stim.rpfile = which(cfg.stim.rpfile);
        if isempty(cfg.stim.rpfile)
            error('The RPvds file: ''%s'' was not found along the Matlab path',cfg.stim.rpfile);
        end
        
        cfg.acq.rpfile  = which(cfg.acq.rpfile);
        if isempty(cfg.acq.rpfile)
            error('The RPvds file: ''%s'' was not found along the Matlab path',cfg.stim.rpfile);
        end
        
        try
            set(hObj,'String','Halt')
            [hdr,data] = feval(calfunc,cfg,h);
            hdr.calfunc = calfunc;
            CloseConnection(StimRP,AcqRP);
            SaveCalibration(hdr,data);
            set(hObj,'String','Run');
        catch
            CloseConnection(StimRP,AcqRP);
            error('There was an error running calibration')
            rethrow(lasterror);
            set(hObj,'String','Run')
        end
        
        
end




% Plotting/Analysis functions ---------------------------
function fbuffer = FilterBuffer(buffer,Fs)
persistent pHd pFs

if isempty(pHd) || pFs ~= Fs
    % Filter out DC component
    Fstop = 100;         % Stopband Frequency
    Fpass = 200;         % Passband Frequency
    Astop = 60;          % Stopband Attenuation (dB)
    Apass = 1;           % Passband Ripple (dB)
    match = 'passband';  % Band to match exactly
    
    % Construct an FDESIGN object and call its BUTTER method.
    hd  = fdesign.highpass(Fstop, Fpass, Astop, Apass, Fs);
    pHd = design(hd, 'butter', 'MatchExactly', match);
    pFs = Fs;
end
fbuffer = filter(pHd,buffer);

function res = SignalAnalysis(buffer,ref,V)
res.rms   = sqrt(mean(buffer.^2)); % signal RMS
res.level = 20 * log10(res.rms/ref.rms) + ref.level; % calibrated level
res.adjV  = V * 10 ^ ((ref.norm - res.level) / 20); % adjusted voltage

function PlotSignal(buffer,Fs,h,freq)
L = length(buffer);

% Plot Time Domain
tax = h.time_domain;
tvec = linspace(0,L/Fs,L)*1000;
plot(tax,tvec,buffer,'-');
mav = max(abs(buffer))*1.1;
set(tax,'ylim',[-mav mav],'xlim',[0 20/max(freq)]*1000); grid(tax,'on');
xlabel(tax,'time (ms'); ylabel(tax,'V'); title(tax,'Signal');

% Plot Frequency Domain
fax = h.freq_domain;
y = hann(L) .* buffer(:); % apply window function (blackmanharris may be better)
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);
for i = 1:length(freq)
    plot(fax,[freq(i) freq(i)],[10^-5 0.01],'-c',freq(i),10^-5,'vc');
    hold(fax,'on');
end
plot(fax,f,2*abs(Y(1:NFFT/2+1)).^2);
hold(fax,'off');
set(fax,'ylim',[0 0.01],'xlim',[0 max(f)],'yscale','linear'); grid(fax,'on');
xlabel(fax,'Frequency (Hz)'); ylabel(fax,''); title(fax,'Power Spectrum')

% % Plot Spectrogram
% axes(fax);
% spectrogram(buffer,1024,512,8192,Fs,'yaxis');
% colormap(hot)
% set(fax,'yscale','linear','ytick',freq)
% y = ylim(fax);
% set(fax,'ylim',[y(1) 0.6*y(2)]);

















% Calibration functions --------------------------
function buffer = GetBuffer(AcqRP,Fs,bdur)
% pause(0.02);

if ~exist('bdur','var') || isempty(bdur)
    bdur = 0.1;
end

buffersize = floor(bdur*Fs);
AcqRP.SetTagVal('bufferSize',buffersize);
AcqRP.ZeroTag('buffer');

AcqRP.SoftTrg(1);

% wait for buffer to be filled
pause(bdur+0.1);

% retrieve buffer
buffer = AcqRP.ReadTagV('buffer',0,buffersize);

buffer = FilterBuffer(buffer,Fs);

% get rid of transient which may occur within first 5 ms of signal
if bdur > 0.05
    t = round(Fs*0.01);
    buffer = buffer(t+1:end);
end

if isempty(buffer) || ~any(buffer)
    CloseConnection(StimRP,AcqRP);
    error('CalibrationUtil:ACQUISITION ERROR:Empty Buffer');
end

function ref_piston_phone_Callback(hObj, ~, h) %#ok<DEFNU>
% Use acquisition module to obtain reference from a calibrated source such
% as a piston phone.
% set(hObj,'Enable','off'); drawnow
cfg = GatherCFG(h);
if isequal(cfg.acq.mod,'RX6')
    cfg.acq.rpfile = which('ACQ_Calibration_RX6.rcx');
elseif isequal(cfg.acq.mod,'RZ6')
    cfg.acq.rpfile = which('ACQ_Calibration_RZ6.rcx');
else
    cfg.acq.rpfile = which('ACQ_Calibration.rcx');
end
cfg.acq.fsid = cfg.stim.fsid;
cfg.stim = [];

[~,AcqRP,Fs] = OpenConnection(cfg);

fax = h.freq_domain;
cax = h.calibration_curve;

cfg.Fs = Fs;

% piston phone frequency = 250 Hz
freq = getpref('CalibrationUtil','CALFREQ',250);
buffer = GetBuffer(AcqRP,Fs,1);


% chop off filter distortion
buffer(1:floor(length(buffer)/2)) = [];

% ANALYZE, PLOT, UPDATE CORRESPONDING FIELD
res = SignalAnalysis(buffer,cfg.ref,1);
if res.rms > 9.99
    set(hObj,'Enable','on');
    error('CalibrationUtil:REFERENCE:Voltage out of range');
end
set(h.ref_rms,'String',num2str(res.rms*1000,'%0.1f'));

cla(cax);
cla(fax);

PlotSignal(buffer,Fs,h,freq);

CloseConnection([],AcqRP);
set(hObj,'Enable','on');


function [hdr,data] = CalibrateNoise(cfg,h)
global StimRP AcqRP

% Runc calibration for noise type stimuli
ref = cfg.ref;
[StimRP,AcqRP,Fs] = OpenConnection(cfg);

cfg.Fs = Fs;
cax = h.calibration_curve;

hp = cfg.hp;
lp = cfg.lp;

hdr.timestamp = datestr(now);
hdr.cfg = cfg;

hdr.V = getpref('CalibrationUtil','SIGNALAMP',1);

data = nan(length(hp),4);
data(:,1) = hp;
data(:,2) = lp;

xr = [min(hp)*2^-0.5 max(hp)*2^0.5];

for i = 1:length(hp)
        StimRP.SetTagVal('HPFc',hp(i));
        StimRP.SetTagVal('LPFc',lp(i));
        StimRP.SoftTrg(2);
        
        res.adjV = hdr.V; % starting voltage
        StimRP.SetTagVal('Amp',res.adjV);
        
        pause(0.2);
        buffer = GetBuffer(AcqRP,Fs,1);
        
        % ANALYZE, PLOT, UPDATE TABLE
        res = SignalAnalysis(buffer,cfg.ref,res.adjV);
        
        PlotSignal(buffer,Fs,h,data(i,[1 2]));
        tax = h.time_domain;
        plot(tax,linspace(0,0.1,length(buffer))*1000,buffer);

        % Plot Calibration Function
        plot(cax,xlim,[ref.norm ref.norm],'-k','linewidth',2);
        hold(cax,'on');
        plot(cax,data(:,1),data(:,2),'-ob','markerfacecolor','b');
        set(cax,'xlim',xr,'ylim',[0 130]); grid(cax,'on');
        hold(cax,'off');
        data(i,3) = res.level; % sound level
        data(i,4) = res.adjV;% adjusted voltage
        
        % Update table
        set(h.data_table,'Data',num2cell(data)); drawnow
end
CloseConnection(StimRP,AcqRP);


function [hdr,data] = CalibrateTones(cfg,h)
global StimRP AcqRP

% Run calibration for tone type stimuli.
ref = cfg.ref;

% ________________
% cd 'CalUtil_RPvds'

[StimRP,AcqRP,Fs] = OpenConnection(cfg);
% ________________
% cd ..

try %#ok<TRYNC>
    cfg.Fs = Fs;
    
    cax = h.calibration_curve;
    
    f = cfg.freqs;
    xr = [min(f)*2^-0.5 max(f)*2^0.5];
    
    % upper/lower bounds +/- 0.5% of desired norm
    tolerance = 0.005;
%     LB = ref.norm * (1-tolerance);
%     UB = ref.norm * (1+tolerance);
    
    hdr.tolerance = tolerance;
    hdr.timestamp = datestr(now);
    hdr.cfg = cfg;
    hdr.V = getpref('CalibrationUtil','SIGNALAMP',1); % starting voltage
    
    data = nan(length(f),3);
    data(:,1) = f;
    
    for i = 1:length(f)
        % update tone frequency
        StimRP.SetTagVal('Freq',f(i));
        res.adjV = hdr.V; % starting voltage
        %     n = 0; converge = false;
        
        %     while ~converge
        StimRP.SetTagVal('Amp',res.adjV);
        
        buffer = GetBuffer(AcqRP,Fs);
        
        % ANALYZE, PLOT, UPDATE TABLE
        res = SignalAnalysis(buffer,cfg.ref,res.adjV);
        
        PlotSignal(buffer,Fs,h,f(i));
        
        % Plot Calibration Function
        plot(cax,xlim,[ref.norm ref.norm],'-k','linewidth',2);
        hold(cax,'on');
        plot(cax,data(:,1),data(:,2),'-ob','markerfacecolor','b');
        set(cax,'xlim',xr,'ylim',[0 130]); grid(cax,'on');
        hold(cax,'off');
        
        % test if adjusted voltage produces intended sound level
        %         converge = res.level >= LB & res.level <= UB;
        %         n = n + 1;
        %         if n == 25
        %             CloseConnection(StimRP,AcqRP);
        %             error('CalibrationUtil:STIMULUS WARNING:Unable to converge\n')
        %         end
        %
        % test adjusted voltage is within range
        %         if res.adjV > 9.99
        %             CloseConnection(StimRP,AcqRP);
        %             error('CalibrationUtil:STIMULUS ERROR:Adjusted voltage too high\n')
        %         end
        
        %         % Update with adjusted value
        %         StimRP.SetTagVal('Amp',res.adjV);
        %
        %         if converge, continue; end
        
        data(i,2) = res.level; % sound level
        data(i,3) = res.adjV; % adjusted voltage
        
        % Update table
        set(h.data_table,'Data',num2cell(data)); drawnow
        %     end
        
    end
end
CloseConnection(StimRP,AcqRP);





















% TDT Functions -------------------------------
function [StimRP,AcqRP,Fs] = OpenConnection(cfg)
stim = cfg.stim;
acq  = cfg.acq;
StimRP = [];

AcqRP = TDT_SetupRP(acq.mod,acq.modid,cfg.contype,[]);
AcqRP.LoadCOFsf(acq.rpfile,acq.fsid);
AcqRP.Run;

if ~cfg.single_mod && ~isempty(stim)
    StimRP = TDT_SetupRP(stim.mod,stim.modid,cfg.contype,[]);
    StimRP.LoadCOFsf(stim.rpfile,stim.fsid);
    StimRP.Run;
else
    StimRP = AcqRP;
end



Fs = AcqRP.GetSFreq;

    
% pause(0.25);

function CloseConnection(StimRP,AcqRP)
if ~isempty(StimRP) && isa(StimRP,'COM.RPco_x')
    StimRP.ClearCOF;
    StimRP.Halt;
    delete(StimRP);
end

if ~isempty(AcqRP) && isa(AcqRP,'COM.RPco_x')
    AcqRP.ClearCOF;
    AcqRP.Halt;
    delete(AcqRP);
end

fh = findobj('type','figure','-and','name','RPfig');
if ~isempty(fh), close(fh); end







% Save/Load Functions --------------------------
function SaveCalibration(hdr,data)  
% calibration directory
dd = 'C:\Electrophys\Calibrations';
if ~isdir(dd), mkdir(dd); end
[fn,pn,fidx] = uiputfile({ ...
    '*.cal','Calibration File (*.cal)'; ...
    '*.txt','OLD FORMAT - Text File (*.txt)'; ...
    '*.csv','Comma Separated Value (*.csv)'}, ...
    'Save Calibration',dd);

if ~fidx
    fprintf('Calibration was NOT saved.\n');
    return
end

switch fidx
    case 1 % Calibration file
        save(fullfile(pn,fn),'-mat','hdr','data');
        
    case 2 % OLD FORMAT - Text file
        if isequal(hdr.calfunc,@CalibrateTones)
            tmat(1,1) = -1; tmat(1,2) = hdr.V;
            tmat(2:size(data,1)+1,:) = data(:,[1 2]);
            dlmwrite(fullfile(pn,fn),tmat,'delimiter',',','newline','pc');
            
        elseif isequal(hdr.calfunc,@CalibrateNoise)
            tmat(1,1:2) = -1; tmat(1,3) = hdr.V;
            tmat(2:size(data,1)+1,:) = data(:,[1 2 3]);
            dlmwrite(fullfile(pn,fn),tmat,'delimiter',',','newline','pc');
        end
        
    case 3 % CSV file
        dlmwrite(fullfile(pn,fn),data,'delimiter',',','newline','pc');
end

fprintf('File Saved: %s\n',fullfile(pn,fn));


function settings_sig_amp_Callback(hObj,~, h) %#ok<INUSD,DEFNU>

prompt = {'Enter amplitude value between 0.1 and 10:'};
name = 'Signal Amplitude';
numlines = 1;
val = getpref('CalibrationUtil','SIGNALAMP',1);

val = inputdlg(prompt,name,numlines,{num2str(val)});

val = str2num(cell2mat(val)); %#ok<ST2NM>

if isscalar(val) && val <= 10 && val >= 0.1
    setpref('CalibrationUtil','SIGNALAMP',val);
    fprintf('Signal amplitude is now: %d\n',val)
elseif isempty(val)
    return
else
    errordlg('Invalid entry','Signal Amplitude','modal');
end


function reffreq_Callback(hObj,~, h) %#ok<INUSD,DEFNU>
prompt = {'Enter frequency of calibration source:'};
name = 'Reference Frequency';
numlines = 1;
val = getpref('CalibrationUtil','CALFREQ',250);

val = inputdlg(prompt,name,numlines,{num2str(val)});

val = str2num(cell2mat(val)); %#ok<ST2NM>

if isscalar(val)
    setpref('CalibrationUtil','CALFREQ',val);
    fprintf('Calibration Frequency is now: %d\n',val)
elseif isempty(val)
    return
else
    errordlg('Invalid entry','Reference Frequency','modal');
end









