function saveasfigure(h, fname, fmt, varargin)
% This function reproduces the MATLAB's 'Save as' botton in the figure
% window
% h: the figure handle
% fname: figure name without format extension
% fmt: format extension, e.g. .fig, .png, .jpeg, etc.
% 
% Optional Inputs
%   'index': for .gif image only. When 'index' is 1, the gif image will be
%            first created. For other indices, the frames will be appended
%            to the created .gif image
%   'quality': for .jpeg family images only, specifiying compression level
%              of jpeg image. Default 90. 

% parse flags
flags = InspectVarargin(varargin, {'index',1}, {'quality',90});

[PATH, NAME, EXT] = fileparts(fname);
% Infer format from extension if fmt not provided
if nargin<3 || isempty(fmt)
    tmpEXT = lower(strrep(EXT, '.',''));
    switch tmpEXT
        case {'jpeg','jpg'}
            fmt = 'jpg';
        case {'tiff','tif'}
            fmt = 'tiff';
        case {'png', 'bmp','gif','ps','eps','pdf','pcx','ppm',...
                'pgm','pbm','svg','fig','ras','xwd','hdf'}
            fmt = tmpEXT;
        otherwise % not known format
            fmt = 'fig'; % force MATLAB figure
    end
else
    fmt = strrep(fmt,'.','');
end

fname = fullfile(PATH, NAME);
fname = strrep(fname,'\','/');

switch lower(fmt)
    case 'fig'
        saveas(h, [fname,'.fig']);
    case {'pcx','ras','xwd','hdf'}
        % get current background color
        currentcolor = get(h, 'color');
        % set background color to white
        set(h, 'color','w')
        %# Capture the current window
        f = getframe(h);
        % write the figure out
        imwrite(f.cdata, [fname,'.',fmt]);
        % set the color back
        set(h, 'color', currentcolor);
    case 'gif'
        % Need to call this function repeatedly to write the images layer
        % by layer
        frame = getframe(h);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        if flag.index == 1
            imwrite(imind,cm,[fname,'.gif'],'gif','Loopcount',inf);
        else
            imwrite(imind,cm,[fname,'.gif'],'gif','WriteMode','append');
        end
    case {'ps','psc','ps2','psc2','eps','epsc','eps2','epsc2','pdf',...
            'svg','tiffnoncompression','png','bmp', 'bmpmono',...
            'bmp256','bmp16m','pcxmono','pcx16','pcx256','pcx24b','pbm',...
            'pbmraw','pgm','pgmraw','ppm','ppmrawo','tiff','tif','jpeg',...
            'jpg','jpeg2000'} % now infer EXT from format
        % duplicate formats
        switch fmt
            case {'jpg','jpeg2000', 'jpeg'}
                fmt = sprintf('jpeg%d', flags.quality);
                EXT = '.jpg';
            case {'tif', 'tiff','tiffnoncompression'}
                fmt = 'tiff';
                EXT = '.tif';
            case {'bmp','bmp256','bmp16m'}
                fmt = 'bmp256';
                EXT = '.bmp';
            case 'bmpmono'
                EXT = '.bmp';
            case {'ps','psc'}
                fmt = 'psc';
                EXT = '.ps';
            case {'ps2','psc2'}
                fmt = 'psc2';
                EXT = '.ps';
            case {'pcxmono','pcx16','pcx256','pcx24b'}
                EXT = '.pcx';
            case {'pbmraw','pbm'}
                EXT = '.pbm';
            case {'pgm','pgmraw'}
                EXT = '.pgm';
            case {'ppm','ppmrawo'}
                EXT = '.ppm';
            case {'eps','epsc'}
                fmt = 'epsc';
                EXT = '.eps';
            case {'eps2','epsc2'}
                fmt = 'epsc2';
                EXT = '.eps';
            otherwise
                EXT = ['.',fmt];
        end
        fname = [fname, EXT];
        axs = findobj(h,'type','axes');
        for n = 1:length(axs)
            axs(n).XTickMode = 'manual';
            axs(n).YTickMode = 'manual';
            axs(n).ZTickMode = 'manual';
        end
        % Make sure the size of the saved figure is as displayed
        set(h, 'PaperPositionMode','auto');
        % get current background color
        currentcolor = get(h, 'color');
        % set background color to white
        set(h, 'color','w');
        print(h, ['-d',fmt], '-r600', fname);
        % set the color back
        set(h, 'color', currentcolor);
    otherwise
        error('Unrecognized image format');
end

end

function [flag,ord]=InspectVarargin(varargin_cell,varargin)
% Inspect whether there is a keyword input in varargin, else return
% default. If search for multiple keywords, input both keyword and
% default_value as a cell array of the same length.
% If length(keyword)>1, return flag as a structure
% else, return the value of flag without forming a structure
%
% [flag,ord]=InspectVarargin(varargin_cell,{k1,v1},...)
%
% Inputs:
% varargin_cell: varargin cell
% keyword (k): flag names
% default_value (v): default value if there is no input
% Input as many pairs of keys and values
%
% Outputs:
% flag: structure with field names identical to that of keyword
% ord: order of keywords being input in the varargin_cell. ord(1)
% correspond to the index of the keyword that first appeared in the
% varargin_cell
%
%
% Edward Cui. Last modified 12/13/2013
%
% reorganize varargin of current function to keyword and default_value
keyword = cell(1,length(varargin));
default_val = cell(1,length(varargin));
for k = 1:length(varargin)
    keyword{k} = varargin{k}{1};
    default_val{k} = varargin{k}{2};
end
% check if the input keywords matches the list provided
NOTMATCH = cellfun(@(x) find(~ismember(x,keyword)),varargin_cell(1:2:end),'un',0);
NOTMATCH = ~cellfun(@isempty,NOTMATCH);
if any(NOTMATCH)
    error('Unrecognized option(s):\n%s\n',...
        char(varargin_cell(2*(find(NOTMATCH)-1)+1)));
end
%place holding
flag=struct();
ord = [];
% assuming the structure of varargin_cell is {'opt1',val1,'opt2',val2,...}
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_val{n};
    end
end
%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end
end











