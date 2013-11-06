function BATCH_RF_analysis
%%
ids = getpref('DB_BROWSER_SELECTION',{'experiments','blocks'});

prot = myms(sprintf('SELECT protocol FROM blocks WHERE id = %d LIMIT 1',ids{2}));

units = myms(sprintf(['SELECT DISTINCT v.unit FROM v_ids v ', ...
                      'JOIN units u ON u.id = v.unit ', ...
                      'LEFT OUTER JOIN v_unit_props p ON p.unit_id = v.unit ', ...
                      'JOIN blocks b ON v.block = b.id ', ...
                      'JOIN db_util.protocol_types pt ON pt.pid = b.protocol ', ...
                      'WHERE v.experiment = %d ', ...
                      'AND u.pool > 0 and b.protocol = %d ', ...
                      'AND u.in_use = TRUE AND b.in_use = TRUE'],ids{1},prot));

nunits = length(units);

%%
rng(123,'twister'); % Important: do not chang this seed value from 123
units = units(randperm(nunits));

%%

k = input('Enter the unit sequency number you would like to start at: ');

if isempty(k), k = 1; end

for u = k:nunits
    fprintf('Unit %d of %d\n',k,nunits)
    uiwait(RF_analysis(units(k)));
    k = k + 1;
    fprintf('\n')
end


