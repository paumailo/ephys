%%

expt = 'Sensational';

DB_Connect;

mym('use','ds_a1_modulates_mgb');



%%
prot = 'WAV';
sortparams = {'BuID'};
win = [-0.6 0.6];
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
dbdata.data = cell(size(dbdata.block));
for i = 1:length(dbdata.block)    
    fprintf('Block % 3d\tUnit % 3d (%d of %d)\n',dbdata.block(i),dbdata.unit(i),i,length(dbdata.block))
    
    spiketimes = DB_GetSpiketimes(dbdata.unit(i));
    
    params = DB_GetParams(dbdata.block(i));
    
    [dbdata.data{i},vals] = shapedata_spikes(spiketimes,params,sortparams,'win',win, ...
        'binsize',binsize);
end
dbdata.data = cellfun(@transpose,dbdata.data,'UniformOutput',false);

%%
dbdata.prestim  = cellfun(@(x)(x(:,vals{1}<0)'),dbdata.data,'UniformOutput',false);
dbdata.poststim = cellfun(@(x)(x(:,vals{1}>=0)'),dbdata.data,'UniformOutput',false);
dbdata.presum   = cellfun(@sum,dbdata.prestim,'UniformOutput',false);
dbdata.postsum  = cellfun(@sum,dbdata.poststim,'UniformOutput',false);
dbdata.rif      = cellfun(@rdivide,dbdata.postsum,dbdata.presum,'UniformOutput',false);
dbdata.premean  = cellfun(@nanmean,dbdata.prestim,'UniformOutput',false);








