%% Convert TDT Tank data to .dat file for batch processing

[~,~,raw] = xlsread('D:\Work\PROJECTS\Electrophysiology\Functional mapping of Corticothalamic modulation of MGB\Subjects\Wicked\Wicked_ValidBlocks.xlsx');

for i = 1:size(raw,1)
    tank   = raw{i,1};
    blocks = raw{i,2};
    if ~isnumeric(blocks)
        blocks = str2num(blocks); %#ok<ST2NM>
    end
    TDT2MClust(tank,blocks,[],'D:\DataProcessing\MClust')
end

%% Run multithreaded version of batch processing
RunClustBatch_MT('D:\DataProcessing\MClust\BatchTDT.txt','NThreads',6,'ForceRun',true)
% RunClustBatch_MT('D:\DataProcessing\MClust\BatchTDT-OneCh.txt','ForceRun',true)

%% Run MClust on each channel to be sorted
MClust;

%% Update tank sort codes based on MClust results


datfiles = dir('*.dat');
ndatfiles = length(datfiles);
fnames = {datfiles.name};
cellfun(@MClust2TDT,fnames,'UniformOutput',false)
