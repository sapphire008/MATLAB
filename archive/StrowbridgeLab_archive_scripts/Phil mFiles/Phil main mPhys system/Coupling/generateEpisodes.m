function lookers = generateEpisodes
% generates a list of file names ranked by amplitude

tempData = get(gcf, 'userdata');
PSPdata = tempData{4};
cellPath = get(gcf, 'name');
cellPath = cellPath(11:end);

% create output window
figure('Name', cellPath,...
    'NumberTitle', 'off',...
    'Units', 'normalized',...
    'position', [.5 .7 .5 .2],...
    'toolbar', 'none',...
    'menubar', 'none')
resultsBox = uicontrol(...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Style','edit',...
    'HorizontalAlignment', 'left',...
    'max', 300);

resultString = '';
lookers = '';

for i = 1: size(PSPdata, 1)
    for j = 1:size(PSPdata, 2) - 1
        [indices indices] = sort(squeeze(PSPdata(i,j,3, PSPdata(i,j,1,:) ~= 0)));
        for k = 1:length(indices)
            % look for a match in the other stim
            if j/2 == round(j/2)
                superStar = find(PSPdata(i, j - 1, 1,:) == PSPdata(i, j, 1, indices(k)) & PSPdata(i, j - 1, 2, :) == PSPdata(i, j, 2, indices(k)) & ((PSPdata(i, j - 1, 3, :) .* PSPdata(i, j, 3, indices(k)) > 0))); 
                if length(superStar) > 0
                    resultString{end + 1, 1} = ['PSP from cell ' num2str(round(j/2 + .1)) ' to cell '  num2str(i) ' in S' num2str(PSPdata(i,j,1,indices(k)), '%2.0f') ', E' num2str(PSPdata(i,j,2,indices(k)), '%3.0f') ', Amp = ' num2str(PSPdata(i,j,3,indices(k)), '%4.2f') '     ***************'];                                         
                    lookers{end + 1, 1} = [cellPath 'S' num2str(PSPdata(i,j,1,indices(k))), 'E' num2str(PSPdata(i,j,2,indices(k))) '.dat'];
                else
                    resultString{end + 1, 1} = ['PSP from cell ' num2str(round(j/2 + .1)) ' to cell '  num2str(i) ' in S' num2str(PSPdata(i,j,1,indices(k)), '%2.0f') ', E' num2str(PSPdata(i,j,2,indices(k)), '%3.0f') ', Amp = ' num2str(PSPdata(i,j,3,indices(k)), '%4.2f')];                                         
                end   
            else
                resultString{end + 1, 1} = ['PSP from cell ' num2str(round(j/2 + .1)) ' to cell '  num2str(i) ' in S' num2str(PSPdata(i,j,1,indices(k)), '%2.0f') ', E' num2str(PSPdata(i,j,2,indices(k)), '%3.0f') ', Amp = ' num2str(PSPdata(i,j,3,indices(k)), '%4.2f')];                                                         
            end
        end
    end
end

set(resultsBox, 'string', resultString);