function p = DB_GetParams(block_id)
% p = DB_GetParams(block_id)
% 
% Simply retrieves parameters from the protocols table into structure p.
%
% Note: Uses a persistent variable and checks if the protocol is the same
% as the last call to this function.  This reduces the number of calls to
% the server.
% 
% DJS (c) 2013

persistent PP

if nargin<1 
   error('DB:DB_GetParams:NrInputArguments','Not enough input arguments.');
end

database = dbcurr;
if isempty(database)
    error('No Database has been selected.')
end


if isempty(PP) || block_id ~= PP.block_id || ~strcmp(PP.database,database)   
    % retrieve block data
    PP = mym(['SELECT id,param_id,param_type,param_value FROM protocols ', ...
        'WHERE block_id = {Si}'],block_id);
    
    if isempty(PP)
        error('No protocol data found for block %d',block_id);
    end
    
    % reorganize protocol data
    [pid,pstr] = myms('SELECT id,param FROM db_util.param_types');
    
    ind = ~ismember(pid,unique(PP.param_type));
    pid(ind) = []; pstr(ind) = [];
    
    p = mym([ ...
        'SELECT t.spike_fs,t.wave_fs,t.id AS tank_id FROM tanks t ', ...
        'INNER JOIN blocks b ON b.tank_id = t.id ', ...
        'WHERE b.id = {Si} ', ...
        'LIMIT 1'],block_id);

    
    p.block_id   = block_id;
    p.database   = database;
    p.param_type = pstr;
    p.param_id   = unique(PP.param_id);
    
    for i = 1:length(pid)
        ind = PP.param_type == pid(i);
        p.param_value(:,i)   = PP.param_value(ind); 
        p.ind.(pstr{i})      = strcmp(p.param_type,pstr{i});
        p.lists.(pstr{i})    = unique(PP.param_value(ind));
    end
    
    % sort by stimulus onset times if available
    onidx = strcmp('onset',pstr);
    if any(onidx)
        p.param_value = sortrows(p.param_value,find(onidx));
    end
    
    for i = 1:length(pid)
        p.VALS.(pstr{i}) = p.param_value(:,i);
    end
    
    p.updated = true;
    
    PP = p;
else
    PP.updated = false;
    p = PP;
end
