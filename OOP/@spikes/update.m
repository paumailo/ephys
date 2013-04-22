function obj = update(obj)
if isempty(obj.block)
    fprintf('update:Must first set a block number (ex: S.block = 3)\n')
    return
end
if isempty(obj.eventname)
    %                 fprintf('update:Must fist specify eventname (ex: S.eventname = ''Snip'')\n')
    return
end
obj = checkTT(obj);
fprintf('Retrieving data ...')
obj.TT.CreateEpocIndexing;

if ~isempty(obj.sortname)
    obj.TT.SetUseSortName(obj.sortname);
end

obj.count = obj.TT.ReadEventsV(1e7,obj.eventname,0,0,0,0,'ALL');
obj.channels   = obj.TT.ParseEvInfoV(0,obj.count,4)';
obj.sortcodes  = obj.TT.ParseEvInfoV(0,obj.count,5)';
obj.timestamps = obj.TT.ParseEvInfoV(0,obj.count,6)';
obj.Fs         = obj.TT.ParseEvInfoV(0,1,9);

if obj.get_waveforms
    obj.waveforms = obj.TT.ParseEvV(0,obj.count)';
else
    obj.waveforms = [];
end

cs  = [obj.channels obj.sortcodes];
ucs = unique(cs,'rows');

obj.units   = nan(size(cs,1),1);
obj.unitstr = cell(size(ucs,1),1);
for i = 1:size(ucs,1)
    ind = cs(:,1) == ucs(i,1) & cs(:,2) == ucs(i,2);
    obj.units(ind) = i;
    obj.unitstr{i} = sprintf('ch%03.0f_u%02.0f',ucs(i,:));
end

fprintf(' done\n')

