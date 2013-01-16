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
% DJS 2012

trial = C.trials(C.tidx,:);

for j = 1:length(trial)
    e = 0;
    param = C.writeparams{j};

    % '*' serves as ignore flag.  This is useful if you want something to
    % be updated by a custom trial-select function after being modified
    if ~isempty(strfind(param,'*')), continue; end 
    
    val = trial{j};
    
    if isstruct(val)
        % file buffer (usually WAV file)
        e = DA(m).WriteTargetV(param,0,par.buffer(:)');
    
    elseif isscalar(val)       
        % set value
        e = DA.SetTargetVal(param,val);
    end
    
    if ~e
        fprintf('** WARNING: Parameter: ''%s'' was not updated **\n',param);
    end
end
