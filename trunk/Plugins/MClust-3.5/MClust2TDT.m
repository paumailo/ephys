function MClust2TDT(datfilename)

% datfiles = dir('*.dat');
% ndatfiles = length(datfiles);
% fnames = {datfiles.name};
% fnames = cellfun(@(x) x(1:end-4),fnames,'UniformOutput',false);

load(datfilename,'-mat'); % data
rootfn = datfilename(1:end-4);

% parse info from file name: Tank_[blocks]-channel
aidx = find(rootfn=='[',1);
bidx = find(rootfn==']',1);
bstr = rootfn(aidx+1:bidx-1);
bstr = textscan(bstr,'%d','delimiter','-');

tank = rootfn(1:aidx-2);
blocks = bstr{1};
channel = str2num(rootfn(bidx+2:end)); %#ok<ST2NM>



% find units sorted with MClust
unitfiles = dir([rootfn '*.t']);
for i = 1:length(unitfiles)
    idx = find(unitfiles=='-',1,'last');
    unit = str2num(unit(length(rootfn)+2:idx-1)); %#ok<ST2NM>
    load(rootfn,'-mat'); % TS
    ind = ismember(data.unwrapped_times,TS);
    spiketimes = data.spiketimes(ind);
    corrblocks = data.unwrapped_blocks(ind);
    
    % update Tank with new MClust sort codes
end


