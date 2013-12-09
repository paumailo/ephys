function TANKS = RunAutoClass(TANKS)
% RunAutoClass
% RunAutoClass(TANKS)
% TANKS = RunAutoClass(TANKS)
%
% Preliminary structure to new spike classification scheme
%
% 1) Online detected spikes(or offline using ss_detect)
% 2) Align spikes by maximum negative peak (ss_align)
% 3) Run principal component analysis on aligned waveforms
% 4) Run AutoClass on aligned waveforms (AutoClass2)
% 5) Save data for Pooling
%
% Pooling GUI specs:
% 1) Plot waveforms of AutoClass classes
%   1.1) Optionally plot color coded raw waveforms of selected classes
%   1.2) Optionally plot color coded mean +/- std waveforms as bands
% 2) View PCA results as projections of 1 vs 2, 1 vs 3, 2 vs 3 dimensions
%   2.1) Optional 2D and 3D scatter plots of PCA scores
%   2.2) Optional plot as density map (2D only)
% 3) ISI for selected classes
% 4) Cross/autocorrelation of selected classes
% 5) Fit gaussian to negative peak amplitude from detection threshold in
% order to estimate number of undetected spikes of the selected class
%
%
% DJS 2013
%
% See also, RunAutoClassReport, Pooling_GUI2



if nargin == 0 || isempty(TANKS)
    [TANKS,OK] = TDT_TankSelect('SelectionMode','multiple');
end

if ~OK, return; end

cfg = [];
cfg.blocks  = 'all';
cfg.datatype = 'Spikes';
% cfg.datatype = 'Stream';


% Maximum number of AutoClass threads to launch at once.  Usually set to
% number of processors - 1
NThreads = 8; 

for tind = 1:length(TANKS)
    [~,TANKS{tind},~] = fileparts(TANKS{tind});
    cfg.tank = TANKS{tind};
    [data,scfg] = getTankData(cfg);
    
    Fs = scfg.fsample;
    
    if isfield(data,'waves')
        % filter for spikes
        fprintf('filtering for spikes ... ')
        h = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
            300,500,5000,10000,18,0.1,18,Fs);
        d1 = design(h,'butter');
        sig = filtfilt(d1.sosMatrix,d1.ScaleValues,double(data.waves));
        
        % compute common average reference (Ludwig et al, 2009)
        sig = sig - repmat(mean(sig,2),1,size(sig,2));
        
        fprintf('done\n')
        
        % Spikes detected offline
        fprintf('detecting spikes ... ')
        spikes = DetectSpikesQ(sig,Fs);
        fprintf('done\n')
    else
        spikes = data; clear data
    end
    
    for i = 1:length(spikes) % run AutoClass one channel at a time
        fprintf('Running Channel %d (%d of %d)\n',spikes(i).channel,i,length(spikes))
        
        cfg.Spikes = spikes(i);
        cfg.TankCFG  = scfg;
        cfg.AutoClass.resultsdir = ['W:\AutoClass_Files\AC2_RESULTS\' cfg.tank '\'];
        cfg.AutoClass.fileroot   = sprintf('%s_%03.0f',cfg.tank,spikes(i).channel);
        cfg.PCA.filename = fullfile(cfg.AutoClass.resultsdir,[cfg.AutoClass.fileroot '_PCA.mat']);
        
        if ~isdir(cfg.AutoClass.resultsdir), mkdir(cfg.AutoClass.resultsdir); end
        
        k = [];
        for j = 1:length(spikes(i).waveforms)
            if isempty(spikes(i).waveforms{j})
                k(end+1) = j;  %#ok<AGROW>
            end
        end
        spikes(i).waveforms(k)  = [];
        spikes(i).timestamps(k) = [];
        
        W = cell2mat(spikes(i).waveforms');
        T = cell2mat(spikes(i).timestamps')';
        
        if isempty(W),continue; end
        
        % set defaults for alignment function
        s = ss_default_params(Fs);
        s.waveforms = W;
        
        % Align Spikes by negative peak
        s.info = [];
        s.spiketimes = T;
        s.params.max_jitter = 0.3;
        s.info.detect.align_sample = 9;
        s.info.detect.event_channel = ones(size(W,1),1);
        s = ss_align(s);
        W = s.waveforms;    
                
        % Run PCA on aligned spikes
        fprintf('\t> Running PCA on aligned waveforms\n')
        [coeffs,scores,latent] = princomp(W); %#ok<NASGU,ASGLU>
        
        fprintf('\t> Saving PCA results\n')
        save(cfg.PCA.filename,'coeffs','scores','latent');
        
        
        cfg.AutoClass.wrappedtimestamps = s.spiketimes;
        
        clear s
        
        % Append some info to cfg structure
        cfg.spiketotal = size(W,1);
        
        
        % wait for processors to open up
        while 1
            [~,b] = dos('tasklist /fi "IMAGENAME eq Autoclass.exe"');
            numthreads = length(strfind(b,'Autoclass'));
            if numthreads < NThreads, break; end
            pause(1)
        end
        
        
        % Run AutoClass on aligned spikes
        %     cfg.AutoClass.variance_factor (default = 2)
        cfg = AutoClass2(W,cfg);
        
    end
end

fprintf('Finished classifying: %s\n\n',datestr(now));



