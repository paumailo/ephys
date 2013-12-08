function DB_CreateUnitPropertiesTable
% DB_CreateUnitPropertiesTable
%
% Checks that db_util.analysis_params and (currentdatabase).unit_properties
% exist and are current.
% 
% This functions is automatically called by DB_CheckAnalysisParams
%
% See also, DB_CheckAnalysisParams
%
% Daniel.Stolzberg@gmail.com 2013

mym(['CREATE TABLE IF NOT EXISTS db_util.analysis_params (', ...
     'id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, ', ...
     'name VARCHAR(15) NOT NULL, ', ...
     'units VARCHAR(10), ', ...
     'description VARCHAR(100) NULL, ', ...
     'ts DATETIME NULL DEFAULT CURRENT_TIMESTAMP, ', ...
     'PRIMARY KEY (id, name), ', ...
     'UNIQUE INDEX id_UNIQUE (id ASC), ', ...
     'UNIQUE INDEX name_UNIQUE (name ASC))']);

mym(['CREATE TABLE IF NOT EXISTS unit_properties ( ', ...
     'id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, ', ...
     'ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ', ...
     'unit_id INT UNSIGNED NOT NULL, ', ...
     'param_id SMALLINT UNSIGNED NOT NULL, ', ...
     'group_id VARCHAR(32), ', ...
     'paramS VARCHAR(256), ', ...
     'paramF FLOAT, ', ...
     'INDEX i_unit_prop_id (unit_id), ', ...
     'INDEX i_unit_prop_param (unit_id,param_id), ', ...
     'INDEX i_unit_prop_group_param (unit_id,group_id,param_id))']);
 
 try %#ok<TRYNC> 
     mym(['CREATE OR REPLACE ALGORITHM = UNDEFINED ', ...
          'VIEW v_unit_props AS ', ...
          'select  ', ...
            'p.unit_id AS unit_id, ', ...
            'p.param_id AS param_id, ', ...
            'p.group_id AS group_id, ', ...
            'a.name AS param, ', ...
            'p.paramS AS paramS, ', ...
            'p.paramF AS paramF, ', ...
            'a.units AS units, ', ...
            'p.id AS id, ', ...
            'p.ts AS ts ', ...
         'from ', ...
            '(db_util.analysis_params a ', ...
            'join unit_properties p ON ((a.id = p.param_id)))']);

 end
 
 
%% updates to table structure
try
    u = mym('SELECT units FROM db_util.analysis_params LIMIT 1'); %#ok<NASGU>
catch me
    if strcmp(me.message,'Unknown column ''units'' in ''field list''')
        mym(['ALTER TABLE db_util.analysis_params ', ...
             'ADD COLUMN units VARCHAR(10) NULL AFTER name']);

    end
end




