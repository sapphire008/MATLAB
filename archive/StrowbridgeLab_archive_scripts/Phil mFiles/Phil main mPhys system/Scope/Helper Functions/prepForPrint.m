function handles = prepForPrint(currentAxis, yVal, varargin)
% Hides axes and places a scale bar with y-units set by yVal (a character
% array).  Possible options include:
% 'xOnly'              -display only the x scale
% 'yOnly',             -display only the y scale
% 'openRight'          -scale bars are open to the right
% 'openBottom'         -scale bars are open to the bottom
% 'location', [x y]    -normalized distance from bottom left corner

    if nargin == 0
        currentAxis = gca;
        yVal = 'V';
    end
    
    if nargin == 1
        if ischar(currentAxis)
            yVal = currentAxis;
            currentAxis = gca;
        else
            yVal = '';
        end
    end
    
    set(currentAxis, 'xtick', [], 'xticklabel', '', 'ytick', [], 'yticklabel', '', 'box', 'off', 'xColor', [1 1 1], 'yColor', [1 1 1]);

    handles = [];
    % add an offset if applicable
    if ispref('newScope', 'exportSettings')
        tempPref = getpref('newScope', 'exportSettings');
        if tempPref(4)
            kids = get(currentAxis, 'children');
            finalKids = [];
            lastData = 0;
            for i = 1:length(kids)
                if strcmp(get(kids(i), 'userData'), 'data')
                    if ~exist('xData', 'var')
                        xData = get(kids(i), 'xdata');
                    end                    
                    yData = get(kids(i), 'ydata');
                    yData = yData(~isnan(yData));
                    yData = mean(yData(find(xData > min(get(currentAxis, 'xlim')), 1, 'first') + (0:min([9 length(yData)]))));

                    switch yVal
                        case {'V', 'F'}
                            switch 1
                                case abs(yData) >= 1000
                                    yLabel = [sprintf('%0.0f', yData / 1000) ' V   '];
                                case abs(yData) >= 1
                                    yLabel = [sprintf('%0.0f', yData) ' mV   '];
                                otherwise
                                    yLabel = [sprintf('%0.0f', yData * 1000) ' ' char(181) 'V   '];
                            end
                        case 'I'
                            switch 1
                                case abs(yData) >= 1000000
                                    yLabel = [sprintf('%0.0f', yData / 1000000) ' ' char(181) 'A   '];
                                case abs(yData) >= 1000
                                    yLabel = [sprintf('%0.0f', yData / 1000) ' nA   '];
                                case abs(yData) >= 1
                                    yLabel = [sprintf('%0.0f', yData) ' pA   '];
                                otherwise
                                    yLabel = [sprintf('%0.0f', yData * 1000) ' fA   '];
                            end      
                        otherwise
                            yLabel = sprintf('%0.0f', yData);
                    end    
            
                    lastText = text(min(get(currentAxis, 'xlim')), yData, yLabel, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'parent', currentAxis, 'fontsize', 8);   
                    handles(end + 1) = lastText;
                    finalKids = [finalKids lastText kids((lastData + 1):i)'];
                    lastData = i;
                end
            end
            finalKids = [finalKids kids((lastData + 1):i)'];
            set(currentAxis, 'children', finalKids);
		else %~tempPref(4)
			% add blank texts as place-holders for the correl macro to
			% determine where one trace ends and the next begins
            kids = get(currentAxis, 'children');
            finalKids = [];
            lastData = 0;            
            for i = 1:length(kids)
                if strcmp(get(kids(i), 'userData'), 'data')
                    lastText = text(min(get(currentAxis, 'xlim')) + diff(get(currentAxis, 'xlim')) / 2, min(get(currentAxis, 'ylim')) + diff(get(currentAxis, 'ylim')) / 2, ' ', 'parent', currentAxis);
                    handles(end + 1) = lastText;
                    finalKids = [finalKids lastText kids((lastData + 1):i)'];
                    lastData = i;
                end
            end
            finalKids = [finalKids kids((lastData + 1):i)'];
            set(currentAxis, 'children', finalKids);
        end
    end

    % add scale bar
    xGap = diff(get(currentAxis, 'xlim'));
    howManyXDigits = floor(log10(xGap / 5));
    if howManyXDigits < 0
        howManyXDigits = floor(log10(xGap) / 2.5);
    end
    xBarSize = round((xGap/(5*10^howManyXDigits)))*10^howManyXDigits; 

    yGap = diff(get(currentAxis, 'ylim'));
    howManyYDigits = floor(log10(yGap / 5));
    if howManyYDigits <= 0
        howManyYDigits = floor(log10(yGap / 2.5));
    end        
    yBarSize = round((yGap/(5*10^howManyYDigits)))*10^howManyYDigits; 

    switch 1
        case xBarSize >= 1000
            xLabel = [num2str(xBarSize / 1000) ' s'];
        case xBarSize >= 1
            xLabel = [num2str(xBarSize) ' ms'];
        otherwise
            xLabel = [num2str(xBarSize * 1000) ' ' char(181) 's'];
    end

    switch yVal
        case 'V'
            switch 1
                case yBarSize >= 1000
                    yLabel = [num2str(yBarSize / 1000) ' V'];
                case yBarSize >= 1
                    yLabel = [num2str(yBarSize) ' mV'];
                otherwise
                    yLabel = [num2str(yBarSize * 1000) ' ' char(181) 'V'];
            end
        case 'I'
            switch 1
                case yBarSize >= 1000000
                    yLabel = [num2str(yBarSize / 1000000) ' ' char(181) 'A'];
                case yBarSize >= 1000
                    yLabel = [num2str(yBarSize / 1000) ' nA'];
                case yBarSize >= 1
                    yLabel = [num2str(yBarSize) ' pA'];
                otherwise
                    yLabel = [num2str(yBarSize * 1000) ' fA'];
            end     
        case ''
            yLabel = num2str(yBarSize);
        otherwise
            yLabel = [num2str(yBarSize) ' ' yVal];
    end    

    xTextPos = hgconvertunits(get(currentAxis, 'parent'), [1 1 1 1.5], 'characters', 'normalized', 0);
    yTextPos = hgconvertunits(get(currentAxis, 'parent'), [1 1 length(yLabel) 1], 'characters', 'normalized', 0);

    if any(~cellfun('isempty', strfind(varargin(cellfun('isclass', varargin, 'char')), 'location')))
        whereLocation = find(~cellfun('isempty', strfind(varargin(cellfun('isclass', varargin, 'char')), 'location')));
        whatLocation = varargin{whereLocation + 1};
        if numel(whatLocation) == 2
            startPos = [min(get(currentAxis, 'xlim')) + whatLocation(1) * (diff(get(currentAxis, 'xlim')) - xBarSize) min(get(currentAxis, 'ylim')) + whatLocation(2) * (diff(get(currentAxis, 'ylim')) - yBarSize)];
            varargin = varargin([1:whereLocation whereLocation + 2:end]);
        else
        	error('Arguement ''location'' must be followed by a two element, normalized vector')
        end        
    end
    
    if all(cellfun('isempty', strfind(varargin, 'location')))
        if ~all(cellfun('isempty', strfind(varargin, 'yOnly')))
            xBarSize = 0;
        end
        if ~all(cellfun('isempty', strfind(varargin, 'xOnly')))
            yBarSize = 0;
        end                    
        startPos = emptySpot(currentAxis, xBarSize / diff(get(currentAxis, 'xlim')), yBarSize / diff(get(currentAxis, 'ylim')), 2 * xTextPos(3) + yTextPos(3), 1.5 * xTextPos(4));
    end
    
    xTextPos(3) = xTextPos(3) * diff(get(currentAxis, 'xlim'));
    xTextPos(4) = xTextPos(4) * diff(get(currentAxis, 'ylim'));
        
    if all(cellfun('isempty', strfind(varargin, 'yOnly')))
        handles(end + 1) = line([startPos(1) startPos(1) + xBarSize], [startPos(2) startPos(2)], 'parent', currentAxis, 'color', [0 0 0]);    
        if all(cellfun('isempty', strfind(varargin, 'openBottom')))
            handles(end + 1) = text(startPos(1) + 0.5 * xBarSize, startPos(2) - 0.5 * xTextPos(4), xLabel, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'parent', currentAxis, 'fontsize', 8);            
        else
            handles(end + 1) = text(startPos(1) + 0.5 * xBarSize, startPos(2) + 0.5 * xTextPos(4), xLabel, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'parent', currentAxis, 'fontsize', 8);            
        end
    end
       
    if all(cellfun('isempty', strfind(varargin, 'xOnly')))
        if all(cellfun('isempty', strfind(varargin, 'openRight')))
            handles(end + 1) = line([startPos(1) + xBarSize startPos(1) + xBarSize], [startPos(2) startPos(2) + yBarSize], 'parent', currentAxis, 'color', [0 0 0]);
            handles(end + 1) = text(startPos(1) + xBarSize + 2 * xTextPos(3), startPos(2) + 0.5 * yBarSize, yLabel, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'parent', currentAxis, 'fontsize', 8);                
        else
            handles(end + 1) = line([startPos(1) startPos(1)], [startPos(2) startPos(2) + yBarSize], 'parent', currentAxis, 'color', [0 0 0]);
            handles(end + 1) = text(startPos(1) - 2 * xTextPos(3), startPos(2) + 0.5 * yBarSize, yLabel, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'parent', currentAxis, 'fontsize', 8);                            
        end
    end
    
    
function Pos = emptySpot(ha,wdt,hgt,textWdt,textHgt)
% sets position vector given handle to axis, xScaleLength, yScaleLength, width (normalized units), height (normalized units)

% Calculate tile size
cap = [0 0 1 1]; %hgconvertunits(ancestor(ha,'figure'), get(ha,'Position'),get(ha,'Units'), 'normalized',get(ha,'Parent'));
xlim=get(ha,'Xlim');
ylim=get(ha,'Ylim');
if ~all(isfinite(xlim)) || ~all(isfinite(ylim))
  % If any of the public limits are inf then we need the actual limits
  % by getting the hidden deprecated RenderLimits.
  oldstate = warning('off','MATLAB:HandleGraphics:NonfunctionalProperty:RenderLimits');
  renderlimits = get(ha,'RenderLimits');
  warning(oldstate);
  xlim = renderlimits(1:2);
  ylim = renderlimits(3:4);
end
H=ylim(2)-ylim(1);
W=xlim(2)-xlim(1);

dh = 0.03*H;
dw = 0.03*W;
Hgt = hgt*H/cap(4);
Wdt = wdt*W/cap(3);
textHgt = textHgt*H;
textWdt = textWdt*W;
Thgt = H/max(1,floor(H/(Hgt+dh)));
Twdt = W/max(1,floor(W/(Wdt+dw)));
textHgt = H/max(1,floor(H/(textHgt+dh)));
textWdt = W/max(1,floor(W/(textWdt+dw)));

% Get data, points and text
Kids=[findobj(ha,'type','line'); ...
      findobj(ha,'type','patch'); ...
      findobj(ha,'type','surface'); ...
      findobj(ha,'type','text')];
Xdata=[];Ydata=[];
for i=1:length(Kids),
    type = get(Kids(i),'type');
    if strcmp(type,'line')
        xk = get(Kids(i),'Xdata');
        yk = get(Kids(i),'Ydata');
        eithernan = isnan(xk) | isnan(yk);
        xk(eithernan) = [];
        yk(eithernan) = [];
        nx = length(xk);
        ny = length(yk);
        if nx < 100 && nx > 1 && ny < 100 && ny > 1
            xk = interp1(xk,linspace(1,nx,200));
            yk = interp1(yk,linspace(1,ny,200));
        end
        Xdata=[Xdata,xk];
        Ydata=[Ydata,yk];
    elseif strcmp(type,'patch') || strcmp(type,'surface')
        xk = get(Kids(i),'Xdata');
        yk = get(Kids(i),'Ydata');
        Xdata=[Xdata,xk(:)'];
        Ydata=[Ydata,yk(:)'];
    elseif strcmp(get(Kids(i),'type'),'text'),
        tmpunits = get(Kids(i),'units');
        set(Kids(i),'units','data')
        tmp=get(Kids(i),'Position');
        ext=get(Kids(i),'Extent');
        set(Kids(i),'units',tmpunits);
        Xdata=[Xdata,[tmp(1) tmp(1)+ext(3)]];
        Ydata=[Ydata,[tmp(2) tmp(2)+ext(4)]];
    end
end

% make sure xdata and ydata have same length
if ~isequal(length(Xdata),length(Ydata))
    xydlength = min(length(Xdata),length(Ydata));
    Xdata = Xdata(1:xydlength);
    Ydata = Ydata(1:xydlength);
end
% xdata and ydata must have same dimensions
in = isfinite(Xdata) & isfinite(Ydata);
Xdata = Xdata(in);
Ydata = Ydata(in);

% Determine # of data points under each "tile"
xp = (0:Twdt/2:W-Twdt-textWdt) + xlim(1);
yp = (H-Thgt:-Thgt/2:textHgt) + ylim(1);
wtol = Twdt / 100;
htol = Thgt / 100;
pop = zeros(length(yp),length(xp));
for j=1:length(yp)
    for i=1:length(xp)
        pop(j,i) = sum(sum(((Xdata > xp(i)-wtol) & (Xdata < xp(i)+Twdt+wtol+textWdt) & ...
            (Ydata > yp(j)-htol-textHgt) & (Ydata < yp(j)+htol)) |...
            ((Xdata > xp(i)+Twdt-wtol) & (Xdata < xp(i)+Twdt+wtol+textWdt) & ...
            (Ydata > yp(j)-htol-textHgt) & (Ydata < yp(j)+Thgt+htol))));    
    end
end

if all(pop(:) == 0), pop(1) = 1; end

% Cover up fewest points.  After this while loop, pop will
% be lowest furthest away from the data
% while any(pop(:) == 0)
%     newpop = filter2(ones(3),pop);
%     if all(newpop(:) ~= 0)
%         break;
%     end
%     pop = newpop;
% end

[j,i] = find(pop == min(pop(:))); % give preference to bottom left corner

Pos = [xp(i(end)) yp(j(end))];    