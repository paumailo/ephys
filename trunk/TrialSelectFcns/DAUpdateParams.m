function e = DAUpdateParams(DA,C)
% DAUpdateParams(DA,C)
% 
% Updates parameters on modules.  Use ProtocolDesign GUI.
%
% DA is handle to OpenDeveloper ActiveX control
% C is the protocol.COMPILED structure
% 
% See also, ProtocolDesign, EPhysController
%
% DJS 2013

trial = C.trials(C.tidx,:);

for j = 1:length(trial)
    param = C.writeparams{j};

    % '*' serves as ignore flag.  This is useful if you want something to
    % be updated by a custom trial-select function after being modified
    if param(1) == '*', continue; end 
    
    par = trial{j};
    
    if isstruct(par) % file buffer (usually WAV file)
        if ~isfield(par,'buffer')
            wfn = fullfile(par.path,par.file);
            if ~exist(wfn,'file')
                par.buffer = [];
            else
                par.buffer = wavread(wfn);
            end
        end
        
        e = DA.WriteTargetV(param,0,single(par.buffer(:)'));
    
    elseif isscalar(par) % set value
        
        if isequal('PA5',param(1:3))
            % use small steps from previous attenuation value to new
            % attenuation value on PA5 rather than a big jump to avoid
            % switching transients (0/24/13)
            pa = DA.GetTargetVal(param);
            if pa < par, a = pa:5:par; else a = pa:-5:par; end
            for i = a
                DA.SetTargetVal(param,i);
            end
        end
        
        e = DA.SetTargetVal(param,par);
    end
    
    if ~e
        fprintf('** WARNING: Parameter: ''%s'' was not updated **\n',param);
    end
end
