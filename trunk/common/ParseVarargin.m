function ParseVarargin(paramkeys,varnames,vin)
% ParseVarargin(paramkeys,varnames,vin);
% 
% Single line 'varargin' checking.  'vin' should be the varargin cell
% array for the calling functiion.
% 
% ParseVarargin(paramkeys,[],vin) will use the paramkeys value as a
% variable name.  Note: spaces are invalid in variable names and are
% replaced with an underscore ('_') in this function.
% 
% paramkeys and varnames must have the same number of elements.
% 
% DJS (c) 2010

paramkeys  = cellstr(paramkeys);
if isempty(varnames)
    varnames = paramkeys;
    for i = 1:length(varnames)
        ind = strfind(varnames{i},' ');
        if any(ind), varnames{i}(ind) = '_'; end
    end
else
    varnames = cellstr(varnames);
end

for i = 1:2:length(vin)
    ind = strcmpi(vin{i},paramkeys);
    if ~any(ind), continue; end
    
    ind = find(ind,1,'last');
    
    assignin('caller',varnames{ind},vin{i+1});
end
        