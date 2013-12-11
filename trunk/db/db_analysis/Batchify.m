function Batchify(analysisfcn)
global KILLBATCH
KILLBATCH = false;
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
rng(123,'twister'); % Important: do not change this seed value from 123
units = units(randperm(nunits));

%%

k = inputdlg(sprintf(['Enter the unit sequence number (1 to %d) ', ...
    'at which you would like to start: '],nunits),'Batch Analysis');

k = str2num(k{1}); %#ok<ST2NM>

if isempty(k), k = 1; end


for u = k:nunits
    fprintf('Unit %d of %d\n',k,nunits)
    af = feval(analysisfcn,units(k));
    f = LaunchBatchGUI(af);
    set(f,'Name',sprintf('BATCH: Unit %d of %d',k,nunits));
    uiwait(af);
    if KILLBATCH, break; end %#ok<UNRCH>
    k = k + 1;
    fprintf('\n')
end

assignin('base','LASTUNITIDX',k)
s = repmat('*',1,50);
fprintf('\n%s\nLast Unit Index: %d\n%s\n',s,k,s)




function f = LaunchBatchGUI(af)
f = findobj('type','figure','-and','tag','Batchify');
if isempty(f)
    f = figure('tag','Batchify','name','BATCH','units','normalized', ...
        'toolbar','none','dockcontrols','off','menubar','none', ...
        'numbertitle','off','position',[0.25 0.67 0.2 0.05]);
    
    
    uicontrol(f,'Style','pushbutton','String','Quit Batch', ...
        'units','normalized','Position',[0.05 0.05 0.5 0.9], ...
        'Tag','Quit','Fontsize',16);
    
    uicontrol(f,'Style','pushbutton','String','Skip >', ...
        'units','normalized','Position',[0.55 0.05 0.4 0.9], ...
        'Tag','Skip','Fontsize',16);    
end

set(f,'CloseRequestFcn',{@KillBatch,f,af});

set(findobj(f,'Tag','Quit'),'Callback',{@KillBatch,f,af});
set(findobj(f,'Tag','Skip'),'Callback',{@SkipUnit,af});

winontop(f);



function KillBatch(~,~,f,af)
global KILLBATCH

KILLBATCH = true;

uiresume(af);

delete(f);


function SkipUnit(~,~,af)
delete(af);

