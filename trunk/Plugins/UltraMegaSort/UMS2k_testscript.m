%%
tank = 'Wicked_1';
blocks = TDT2mat(tank,[],'silent',true);
clear data
for i = 1:length(blocks)
    data(i) = TDT2mat(tank,blocks{i},'silent',true,'type',3);
end

Fs = data(1).snips.eNeu.fs;

%%
channel = 24;

clear spikes
spikes = ss_default_params(Fs);
spikes.spiketimes = [];
spikes.trials     = [];
spikes.waveforms  = [];
spikes.unwrapped_times = [];
for i = 1:length(data)
    cind = data(i).snips.eNeu.chan == channel;
    n  = sum(cind);
    ts = data(i).snips.eNeu.ts(cind);
    wf = data(i).snips.eNeu.data(cind,:);
    
    spikes.spiketimes(1,end+1:end+n)  = ts;
    spikes.trials(1,end+1:end+n)      = i;
    spikes.waveforms(end+1:end+n,:,1) = wf; 
    
    spikes.info.detect.dur(i) = ts(end);
    if i > 1
        ts = ts + spikes.unwrapped_times(end) + 1; % add 1 second between trials
    end
    spikes.unwrapped_times(1,end+1:end+n) = ts;
    
end
spikes.info.detect.align_sample  = 9;
spikes.info.detect.event_channel = ones(size(spikes.spiketimes));
spikes.info.detect.stds          = mean(std(spikes.waveforms,0,2));
% this cov of noise floor is not exactly what's used in ss_detect; however,
% since spikes were dected online we don't have access to noise floor.
% Just use the first sample of a random subset (if > 10000) of spike
% waveforms instead.
widx = randi(size(spikes.waveforms,1),[10000 1]);
spikes.info.detect.cov    = cov(spikes.waveforms(widx,1));
spikes.info.detect.thresh = -spikes.info.detect.stds; % this ain't accurate

spikes.params.window_size = size(spikes.waveforms,2) / Fs;
spikes.params.max_jitter  = 0.1;
spikes.params.agg_cutoff  = 0.01; % default 0.05;




%%
% spikes = ss_detect(wfs,spikes);
spikes = ss_align(spikes);
spikes = ss_kmeans(spikes);
spikes = ss_energy(spikes);
spikes = ss_aggregate(spikes);
splitmerge_tool(spikes)

