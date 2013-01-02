function varargout = TDT_BlockSelect(TT,tank,varargin)
% varargout = TDT_BlockSelect(TT,tank,varargin)
% 
% DJS (c)

% set defaults
smode = 'single';
sname = 'Select Tank';
okstr = 'Select';
castr = 'Cancel';
blocks = [];

ptags  = {'SelectionMode','Name','OKString','CancelString','tanklist'};
vnames = {'smode','sname','okstr','castr','tanks'};

ParseVarargin(ptags,vnames,varargin);

c.tank = tank;
c.datatype = 'BlockInfo';
c.silently = true;
c.TT = TT;

b = getTankData(c);

blocks = cell(size(b));
for i = 1:length(b)
    blocks{i} = b(i).name;
end

[bind,ok] = listdlg('ListString',blocks, ...
                   'SelectionMode',smode, ...
                   'Name',sname, ...
                   'OKString',okstr, ...
                   'CancelString',castr);
               
varargout{1} = blocks(bind);
varargout{2} = ok;