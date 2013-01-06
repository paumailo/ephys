function[names] = dblist
% dblist   List MySQL databases           [mym utilities]
% Example  dbs = dblist
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else
    % new compilation of mym returns structure DJS 1/2013
    dbs = mym('show databases');
    names = dbs.Database;
    % remove reserved database names DJS 1/2013
    reserved = {'information_schema','class_lists','db_util','mysql'};
    i = ismember(names,reserved);
    names(i) = [];
end   
