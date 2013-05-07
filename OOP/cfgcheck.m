function pcfg = cfgcheck(cfg,reqflds,reqvald,optflds,optdeft,opttype)
% helper function for checking cfg structure.

narginchk(3,6);

p = inputParser;
p.StructExpand = false;
v = [];
for i = 1:length(reqflds)
    p.addRequired(reqflds{i},reqvald{i});
    if isfield(cfg,reqflds{i})
        v{end+1} = cfg.(reqflds{i}); %#ok<AGROW>
    else
        s = dbstack(1);
        error('cfgcheck:Required cfg field ''%s'' is missing for function %s', ...
            reqflds{i},s(1).name)
    end
end
if nargin > 3
    for i = 1:length(optflds)
        p.addParamValue(optflds{i},optdeft{i},opttype{i});
        if isfield(cfg,optflds{i})
            v{end+1} = optflds{i}; %#ok<AGROW>
            v{end+1} = cfg.(optflds{i}); %#ok<AGROW>
        end
    end
end
p.parse(v{:});
pcfg = p.Results;


