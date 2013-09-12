function DB_UpdateUnitProps(unit_id,P,groupid,verbose)
% DB_UpdateUnitProps(unit_id,P,groupid)
% DB_UpdateUnitProps(unit_id,P,groupid,verbose)
%
% Updates unit_properties table of currently selected database.
%
% Accepts a unit_id (from units table) and P which is a structure in which
% each field name is an existing name from db_util.analysis_params table.  
%
% Fields of P can be a matrix of any size/dimensions and either a cellstr
% type or numeric type.
%
% groupid is a string with the name of one field in the structure P.  This
% field (P.(groupid)) is used to group results in unit_properties by some 
% common value such as sound level, frequency, etc.  If P.(groupid) can
% also be numeric.
%
% ex: % this example uploads peakfr and peaklat with the group level
%   P.level   = {'10dB','30dB','50dB','70dB'};
%   P.peakfr  = [6.1, 10.3, 24.2, 56.1];
%   P.peaklat = [15.1, 14.0, 12.1, 11.5];
%   groupid = 'level';
%   DB_UpdateUnitProperties(unit_id,P,groupid)
% 
% If verbose is true, then the updating progress will be displayed in the
% command window. (default = false)
%
% DJS 2013 daniel.stolzberg@gmail.com

narginchk(3,4);

if nargin >= 3 && ~isfield(P,groupid)
    error('The groupid string must be a fieldname in structure P');
end

ap = mym('SELECT id, name FROM db_util.analysis_params');

fn = fieldnames(P)';
fn(ismember(fn,groupid)) = [];

if isnumeric(P.(groupid))
    P.(groupid) = num2str(P.(groupid)(:));
    P.(groupid) = cellstr(P.(groupid));
elseif ~iscellstr(P.(groupid))
    P.(groupid) = cellstr(P.(groupid));
end

chkstr = 'SELECT id FROM v_unit_props WHERE unit_id = %d AND group_id = "%s" AND param = "%s"';
dltstr = ['DELETE FROM up USING unit_properties AS up INNER JOIN db_util.analysis_params AS ap ', ...
          'ON ap.id = up.param_id WHERE up.unit_id = %d AND up.group_id = "%s" ', ...
          'AND ap.name = "%s"'];

mymstrf = 'REPLACE unit_properties (unit_id,group_id,param_id,paramF) VALUES (%d,"%s",%d,%f)';
mymstrs = 'REPLACE unit_properties (unit_id,group_id,param_id,paramS) VALUES (%d,"%s",%d,"%s")';

fstrf = '%s unit id %d\t%s: %s\t%s: "%s"\n';
fstrs = '%s unit id %d\t%s: %s\t%s: %0.3f\n';

for f = fn
    f = char(f); %#ok<FXSET>
    id = ap.id(ismember(ap.name,f));
    if ischar(P.(f)), P.(f) = cellstr(P.(f)); end
    if iscellstr(P.(f))
        for i = 1:numel(P.(groupid))
            if i > numel(P.(f)), continue; end
            c = myms(sprintf(chkstr,unit_id,P.(groupid){i},f));
            if ~isempty(c), mym(sprintf(dltstr,unit_id,P.(groupid){i},f)); end            
            mym(sprintf(mymstrs,unit_id,P.(groupid){i},id,P.(f){i}));
            if verbose
                if ~isempty(c)
                    fprintf(fstrf,'Updated',unit_id,groupid,P.(groupid){i},f,P.(f){i})
                else
                    fprintf(fstrf,'Added',unit_id,groupid,P.(groupid){i},f,P.(f){i})
                end
            end
        end
    else
        for i = 1:numel(P.(groupid))
            if i > numel(P.(f)), continue; end
            c = myms(sprintf(chkstr,unit_id,P.(groupid){i},f));
            if ~isempty(c), mym(sprintf(dltstr,unit_id,P.(groupid){i},f)); end
            mym(sprintf(mymstrf,unit_id,P.(groupid){i},id,P.(f)(i)));
            if verbose
                if ~isempty(c)
                    fprintf(fstrs,'Updated',unit_id,groupid,P.(groupid){i},f,P.(f)(i))
                else
                    fprintf(fstrs,'Added',unit_id,groupid,P.(groupid){i},f,P.(f)(i))
                end
            end
        end
    end
end








