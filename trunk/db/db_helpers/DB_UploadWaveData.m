function result = DB_UploadWaveData(tankname,cfg,BlockInfo)
% result = DB_UploadWaveData(tankname,cfg)
% result = DB_UploadWaveData(tankname,cfg,BlockInfo)
%
% Upload waveform data to a database.  A connection to the database should
% already be established.
%
% DJS 2013

result = 0; %#ok<NASGU>

if ~exist('BlockInfo','var') || isempty(BlockInfo)
    % get Block Info
    cfg.tank     = tankname;
    cfg.datatype = 'BlockInfo';
    BlockInfo    = getTankData(cfg);
end

TT = [];

% process each block
for i = 1:length(BlockInfo)
%     get Wave Data from tank
        cfg.datatype   = 'Waves';
        cfg.TT         = TT;
        cfg.blocks     = BlockInfo(i).name;
        [WaveData,cfg,TT] = getTankData(cfg);

    Fs = BlockInfo(i).Wave.fsample;

    %----------------------------------------------------------------------
%     clear WaveData
%     n = floor(BlockInfo(i).Strm.fsample/1200);
%     Fs = BlockInfo(i).Strm.fsample / n;
% 
%     for j = 1:32
%         cfg.datatype   = 'Stream';
%         cfg.TT         = TT;
%         cfg.blocks     = BlockInfo(i).name;
%         cfg.channel    = j;
%         [S,cfg,TT]     = getTankData(cfg);
% 
%         % build a LFP filter (lowpass at 300 Hz)
%         Fs = 1200;
%         Wp = 300 * 2 / Fs;
%         Ws = 500 * 2 / Fs;
%         [N,Wn] = buttord( Wp, Ws, 3, 20);
%         [Lb,La] = butter(N,Wn);
%         
%         S.waves = downsample(S.waves,n);
%         WaveData.waves(:,j) = filtfilt(Lb, La, S.waves);
%         clear S
%     end
%     mym('UPDATE tanks SET wave_fs = {S}',num2str(Fs));
    %----------------------------------------------------------------------

    % Split WaveData according to epoch onsets
    onidx   = strcmp(BlockInfo(i).paramspec,'onset');
    sampon  = floor(BlockInfo(i).epochs(:,onidx) * Fs)+1;
    sampon(sampon > size(WaveData.waves,1)) = [];
    sampoff = sampon(2:end) - 1;
    sampoff(end+1) = sampon(end) + sampoff(1) - sampon(1); %#ok<AGROW>
    sampoff(sampoff>size(WaveData.waves,1)) = size(WaveData.waves,1);

    % get corresponding channel_id
    [chans,cids] = myms(sprintf([ ...
        'SELECT c.channel,c.id ', ...
        'FROM channels c ', ...
        'INNER JOIN blocks b ', ...
        'ON c.block_id = b.id ', ...
        'INNER JOIN tanks t ', ...
        'ON b.tank_id = t.id ', ...
        'WHERE t.name = "%s" ', ...
        'AND b.block  = %d ', ...
        'ORDER by c.channel'], ...
        tankname,BlockInfo(i).id)); %#ok<ASGLU>

    if isempty(cids), continue; end

    fprintf('Uploading Wave Data on Block %d of %d ... ',i,length(BlockInfo))
    for k = 1:length(cids)
        for j = 1:length(sampon)
            mym([ ...
                'REPLACE INTO wave_data ', ...
                'VALUES ({Si},{Si},"{M}")'], ...
                cids(k),j,WaveData.waves(sampon(j):sampoff(j),k));
        end
    end
    fprintf('done\n')
end

result = 1;

