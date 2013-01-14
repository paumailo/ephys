function result = DB_UploadWaveData(tankname,BlockInfo)
% result = DB_UploadWaveData(tankname,BlockInfo)
%
% Upload waveform data to a database.  A connection to the database should
% already be established.
%
% DJS 2013

result = 0; %#ok<NASGU>

TT = [];

% process each block
for i = 1:length(BlockInfo)
    %     get Wave Data from tank
    cfg = [];
    cfg.datatype   = 'Waves';
    cfg.TT         = TT;
    cfg.tank       =  tankname;
    cfg.blocks     = BlockInfo(i).name;
    [WaveData,~,TT] = getTankData(cfg);
    
    Fs = BlockInfo(i).Wave.fsample;

    %----------------------------------------------------------------------
    % Decimate
%     n = floor(Fs/1200);
%     Fs = Fs / n;
% 
%         % build a LFP filter (lowpass at 300 Hz)
%         Wp = 600 * 2 / Fs;
%         Ws = 1000 * 2 / Fs;
%         [N,Wn] = buttord( Wp, Ws, 3, 20);
%         [Lb,La] = butter(N,Wn);
%         
%         S.waves = downsample(WaveData,n);
%         WaveData.waves(:,j) = filtfilt(Lb, La, S.waves);
%         clear S
%     
% %     mym('UPDATE tanks SET wave_fs = {S} WHERE STRCMP(name,"{S}")',num2str(Fs),tankname);
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

    fprintf('Uploading Wave Data on Block %d ... ',BlockInfo(i).id)
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

