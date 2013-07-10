%% Convert TDT Tank data to .dat file for batch processing v1
[~,~,raw] = xlsread('D:\Work\PROJECTS\Electrophysiology\Functional mapping of Corticothalamic modulation of MGB\Subjects\Wicked\Wicked_ValidBlocks.xlsx');

for i = 1:size(raw,1)
    tank   = raw{i,1};
    blocks = raw{i,2};
    if ~isnumeric(blocks)
        blocks = str2num(blocks); %#ok<ST2NM>
    end
    TDT2MClust(tank,blocks,[],'D:\DataProcessing\MClust')
end

%% Convert TDT Tank data to .dat file for batch processing v2
tanks = TDT_TankSelect('SelectionMode','multiple');

chans = 1:32;
badchans = [9 11 13 16 30];
chans(badchans) = [];

for t = tanks
    TDT2MClust(char(t),[],chans,'D:\DataProcessing\MClust\SENSATIONAL')
end

%% Run multithreaded version of batch processing
RunClustBatch_MT('D:\DataProcessing\MClust\SENSATIONAL\BatchTDT.txt','NThreads',7,'ForceRun',true)
% RunClustBatch_MT('D:\DataProcessing\MClust\BatchTDT-OneCh.txt','ForceRun',true)

%% Run MClust on each channel to be sorted
MClust;

%% Update tank sort codes based on MClust results
datfiles = dir('*.dat');
ndatfiles = length(datfiles);
fnames = {datfiles.name};
cellfun(@MClust2TDT,fnames,'UniformOutput',false)
