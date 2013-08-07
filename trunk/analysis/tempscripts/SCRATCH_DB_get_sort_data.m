%%

expt = 'MAIZE';

DB_Connect;

mym('use','ds_a1_modulates_mgb');



%%
prot = 'RIF';
sortparams = {'Levl'};
win = [-0.1 0.1];
binsize = 0.001;


mstr = sprintf(['SELECT b.id AS block, u.id AS unit FROM blocks b ', ...
    'JOIN tanks t ON t.id = b.tank_id ', ...
    'JOIN channels c ON b.id = c.block_id ', ...
    'JOIN units u ON u.channel_id = c.id ', ...
    'WHERE t.exp_id = (SELECT e.id FROM experiments e ', ...
    'WHERE e.name = "%s") ', ...
    'AND b.protocol = (SELECT pid FROM db_util.protocol_types ',...
    'WHERE alias = "%s") ', ...
    'AND u.in_use = TRUE'],expt,prot);

dbdata = mym(mstr);

gw = gausswin(5);

dbdata.data  = cell(size(dbdata.block));
dbdata.cdata = cell(size(dbdata.block));
for i = 1:length(dbdata.block)
    fprintf('Block % 3d\tUnit % 3d (%d of %d)\n',dbdata.block(i),dbdata.unit(i),i,length(dbdata.block))
    spiketimes = DB_GetSpiketimes(dbdata.unit(i));
    params = DB_GetParams(dbdata.block(i));
    [dbdata.data{i},vals] = shapedata_spikes(spiketimes,params,sortparams,'win',win, ...
        'binsize',binsize,'func','mean');
    for j = 1:size(dbdata.data{i},2)
        dbdata.cdata{i}(:,j) = conv(flipud(dbdata.data{i}(:,j)),gw,'same');
        dbdata.cdata{i}(:,j) = conv(flipud(dbdata.cdata{i}(:,j)),gw,'same');
    end
end
dbdata.data = cellfun(@transpose,dbdata.data,'UniformOutput',false);
dbdata.cdata = cellfun(@transpose,dbdata.cdata,'UniformOutput',false);








%% Do some calculations
dbdata.prestim  = cellfun(@(x)(x(:,vals{1}<0)'),dbdata.data,'UniformOutput',false);
dbdata.poststim = cellfun(@(x)(x(:,vals{1}>=0)'),dbdata.data,'UniformOutput',false);
dbdata.presum   = cellfun(@sum,dbdata.prestim,'UniformOutput',false);
dbdata.postsum  = cellfun(@sum,dbdata.poststim,'UniformOutput',false);
dbdata.rif      = cellfun(@minus,dbdata.postsum,dbdata.presum,'UniformOutput',false);
dbdata.premean  = cellfun(@nanmean,dbdata.prestim,'UniformOutput',false);





%%

for i = 1:length(dbdata.data)
    f = figure;
    subplot(221)
    plot(vals{1},dbdata.data{i}')
    
    subplot(222)
    imagesc(vals{1},vals{2},dbdata.data{i})
    set(gca,'ydir','normal')
    hold on
    plot([0 0],ylim,'-k','linewidth',3);
    hold off
    
    subplot(223)
    plot(vals{1},dbdata.cdata{i}')
    
    subplot(224)
    imagesc(vals{1},vals{2},dbdata.cdata{i})
    set(gca,'ydir','normal')
    hold on
    plot([0 0],ylim,'-k','linewidth',3);
    hold off
    
    waitfor(f);
end







%% upload rif result to analysis_rif table
x = 0:10:80;
for i = 1:length(dbdata.rif)
    fprintf('Block % 3d\tUnit % 3d (%d of %d) ',dbdata.block(i),dbdata.unit(i),i,length(dbdata.block))
    for j = 1:length(dbdata.rif{i})
        mym(['REPLACE analysis_rif (unit_id, level, value) ', ...
            'VALUES ({Si},{Si},{S})'], ...
            dbdata.unit(i),x(j),num2str(dbdata.rif{i}(j),'%0.10f'));
        fprintf('.')
    end
    fprintf(' done\n')
end


%% Retrieve rif data for further analysis

% rif = mym('SELECT DISTINCT unit_id FROM analysis_rif');

rif = mym(['SELECT DISTINCT a.unit_id FROM analysis_rif a ', ...
           'LEFT JOIN analysis_rif_features b ', ...
           'ON a.unit_id = b.unit_id ', ...
           'WHERE b.unit_id IS NULL']);

for u = rif.unit_id'
    fprintf('Unit %d\t',u)
    waitfor(RIF_analysis(u),'UserData',1);
end





