function h = eph_line_plot(x, y, err, h, varargin)

% make sure everything is in column
x = x(:);
y = y(:);

% start the figure
if nargin<4 || isempty(h)
    h = figure();
end
% parse error bar argument
if any(size(err)==1)
    err = err(:);
    err = [err,err];
end
d = find(size(err) == length(x));
if d>1
    err = err';
end
% Do the plotting
errorbar(x, y, err(:,1), err(:,2));

axs = findobj(h,'type','axes');
for n = 1:length(axs)
    set(axs(n), 'tickdir','out')
    set(axs(n), 'box','off')
    set(axs(n), 'fontname','Helvetica');
end

% Add additional labels
flag = parse_varargin(varargin, {'title',''}, {'xlabel',''}, ...
    {'ylabel',''});
title(flag.title);
xlabel(flag.xlabel);
ylabel(flag.ylabel);
end

function flag = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1'}.
% return flag with fields 'opt1', 'opt2', ...

% for sanity check
IND = ~ismember(options(1:2:end),cellfun(@(x) x{1}, varargin, 'un',0));
if any(IND)
    EINPUTS = options(find(IND)*2-1);
    S = warning('QUERY','BACKTRACE'); % get the current state
    warning OFF BACKTRACE; % turn off backtrace
    warning(['Unrecognized optional flags:\n', ...
        repmat('%s\n',1,sum(IND))],EINPUTS{:});
    warning('These options are ignored');
    warning(S);
end
flag = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp) % if present, assign using input value
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
    else % if not present, assign default value
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end