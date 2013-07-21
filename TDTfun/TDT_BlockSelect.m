function varargout = TDT_BlockSelect(tank,varargin)
% varargout = TDT_BlockSelect(tank,varargin)
%
%
% DJS 2013

% set defaults
smode = 'single';
sname = 'Select Tank';
okstr = 'Select';
castr = 'Cancel';

ptags  = {'SelectionMode','Name','OKString','CancelString','tanklist'};
vnames = {'smode','sname','okstr','castr','tanks'};

ParseVarargin(ptags,vnames,varargin);

blocks = TDT2mat(tank);

if isempty(blocks)
    fprintf('No blocks found in tank %s\n',tank)
    varargout{1} = [];
    varargout{2} = 0;
else
    [bind,ok] = listdlg('ListString',blocks, ...
        'SelectionMode',smode, ...
        'Name',sname, ...
        'OKString',okstr, ...
        'CancelString',castr);
    
    varargout{1} = blocks(bind);
    varargout{2} = ok;
end