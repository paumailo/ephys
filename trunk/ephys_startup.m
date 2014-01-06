function subdirs = ephys_startup(rootdir)
% ephys_startup;
% ephys_startup(rootdir);
% newp = ephys_startup(...)
%
% Finds all subdirectories in a given root directory, removes any
% directories with 'svn', and adds them to the Matlab path.
%
% Default rootdir is 'C:\MATLAB\work\ephys'.  If this directory does not
% exist, then an error is thrown.
% 
% DJS 2013

fprintf('** Setting Paths for EPhys **\n')

if ~nargin || isempty(rootdir)
    rootdir = 'C:\MATLAB\work\ephys'; 
    assert(isdir(rootdir),'Default directory "%s" not found. See help ephys_startup',rootdir)
end

p = genpath(rootdir);

t = textscan(p,'%s','delimiter',';');
i = cellfun(@(x) (strfind(x,'\.')),t{1},'UniformOutput',false);
ind = cell2mat(cellfun(@isempty,i,'UniformOutput',false));
subdirs = t{1}(ind);

subdirs = cellfun(@(x) ([x ';']),subdirs,'UniformOutput',false);
catsubdirs = cell2mat(subdirs');

addpath(catsubdirs);





