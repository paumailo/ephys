function MClust2TDT(datfilename)

% datfiles = dir('*.dat');
% ndatfiles = length(datfiles);
% fnames = {datfiles.name};
% fnames = cellfun(@(x) x(1:end-4),fnames,'UniformOutput',false);

if isequal(datfilename(end-3:end),'.dat'), datfilename(end-3:end) = []; end

% parse info from file name: Tank_[blocks]-channel
aidx = find(datfilename=='[',1);
tank = datfilename(1:aidx-2);
bidx = find(datfilename==']',1);
bstr = datfilename(aidx+1:bidx-1);
bstr = textscan(bstr,'%d','delimiter','-');
blocks = bstr{1};
channel = str2num(datfilename(bidx+2:end)); %#ok<ST2NM>

% find units sorted with MClust
unitfiles = dir([datfilename '*.t']);



