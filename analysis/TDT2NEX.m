%%

tank = char(TDT_TankSelect);

%%

block = char(TDT_BlockSelect(tank));


%%
data = TDT2mat(tank,block,'type',[2 3],'silent',true,'sortname','Pooled');

snip = data.snips.eNeu;

uchan = unique(snip.chan);

clear ch*
for c = uchan
    ind = snip.chan == c;
    units = unique(snip.sort);
    units(units == 0) = []; % ignore noise
    for u = units
        ind = snip.chan == c & snip.sort == u;
        ts = snip.ts(ind);
        
        if length(ts) < 50, continue; end
        
        varname = sprintf('ch%02d_%d',c,u);
        
        fprintf('%s\tcount = % 7d spikes\n',varname,length(ts))
        
        eval(sprintf('%s = ts;',varname));
    end    
end

%

Levl = data.epocs.Levl.data;
Onst = data.epocs.Levl.onset;

uLevl = unique(Levl)';
clear Onst_*
for i = uLevl
    ind = i == Levl;    
    tmp = Onst(ind);
    eval(sprintf('Onst_%ddB = tmp;',i));
end









