function subdirs = ephys_startup(rootdir)
% ephys_startup
% ephys_startup(rootdir)
% newp = ephys_startup(...)
%
% Finds all subdirectories in a given root directory, removes any
% directories with 'svn', and adds them to the Matlab path.
%
% Default rootdir is 'C:\MATLAB\work\ephys'
% 
% DJS 2013

fprintf('** Setting Paths for EPhys **\n')

if ~nargin || isempty(rootdir), rootdir = cd; end

p = genpath(rootdir);

t = textscan(p,'%s','delimiter',';');
i = cellfun(@strfind,t{1},repmat({'svn'},size(t{1})),'UniformOutput',false);
ind = cell2mat(cellfun(@isempty,i,'UniformOutput',false));
subdirs = t{1}(ind);

catsubdirs = subdirs{1};
for i = 2:length(subdirs)
    catsubdirs = [catsubdirs ';' subdirs{i}]; %#ok<AGROW>
end

addpath(catsubdirs);





