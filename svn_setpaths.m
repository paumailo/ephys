function subdirs = svn_setpaths(rootdir)
% svn_setpaths
% svn_setpaths(rootdir)
% newp = svn_setpaths(...)
%
% Finds all subdirectories in a given root directory, removes any
% directories with 'svn', and adds them to the Matlab path.
%
% 
% DJS 2013

if ~nargin
    error('svn_setpaths: rootdir parameter must be specified')
end

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





