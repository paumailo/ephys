%% Batch Pools 2 Tanks

% Update directory to tank name and run the script using Ctrl+Enter
ACdir = 'C:\AutoClass_Files\AC2_RESULTS\130625_EB4';

poolfiles = dir(fullfile(ACdir,'*POOLS.mat'));

POOLS = cellfun(@fullfile,repmat({ACdir},1,length(poolfiles)),{poolfiles.name},'UniformOutput',false);

cellfun(@AutoClass2TDT,POOLS);


