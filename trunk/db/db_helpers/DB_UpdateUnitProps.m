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
end


mymstrf = 'REPLACE unit_properties (unit_id,group_id,param_id,paramF) VALUES (%d,"%s",%d,%f)';
mymstrs = 'REPLACE unit_properties (unit_id,group_id,param_id,paramS) VALUES (%d,"%s",%d,"%s")';

fstrf = 'unit id %d\t%s: %s\t%s\n';
fstrs = 'unit id %d\t%s: %s\t%f\n';

for f = fn
    f = char(f);
    id = ap.id(ismember(ap.name,f));
    if iscellstr(P.(f))
        for i = 1:numel(P.(groupid))
            mym(sprintf(mymstrs,unit_id,P.(groupid){i},id,P.(f){i}));
            if verbose
                fprintf(fstrf,unit_id,groupid,P.(groupid){i},P.(f){i})
            end
        end
    else
        for i = 1:numel(P.(groupid))
            mym(sprintf(mymstrf,unit_id,P.(groupid){i},id,P.(f)(i)));
            if verbose
                fprintf(fstrs,unit_id,groupid,P.(groupid){i},P.(f)(i))
            end
        end
    end
end








