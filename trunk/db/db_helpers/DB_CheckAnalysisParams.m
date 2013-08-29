function DB_CheckAnalysisParams(n,d)
% DB_CheckAnalysisParams(n,d)
%
% check to see if necessary parameters already exist on db_util and add if
% not there
%
% Where n is a cellstr array of parameter names and d is a cell string
% array (same size as n) of descriptions for each parameter.
%
% Max number of characters for each n is 15.
% Max number of characters for each d is 45.
%
% A connection to the database must already be established before calling
% this function.
% 
% ex:
% n = {'bestlevel','maxresp','threshold'};
% d = {'Level of best response', 'Maximum response', 'Threshold'};
% DB_CheckAnalysisParams(n,d);
%
% DJS 2013 daniel.stolzberg@gmail.com

narginchk(2,2);

if ~iscellstr(n), error('n must be a cellstr'); end
if ~iscellstr(d), error('d must be a cellstr'); end

if ~isequal(numel(n),numel(d))
    error('Size of n must equal size of d');
end

DB_CreateUnitPropertiesTable;

p = myms('SELECT name FROM db_util.analysis_params');

ind = ~ismember(n,p);

for i = find(ind)
    mym(['INSERT db_util.analysis_params ', ...
         '(name,description) VALUES ', ...
         '("{S}","{S}")'],n{i},d{i});
end
