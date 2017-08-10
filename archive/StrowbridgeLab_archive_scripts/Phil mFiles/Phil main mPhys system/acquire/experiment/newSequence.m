function newSequence

% increments the sequence by 1
handle = findobj(getappdata(0, 'experiment'), 'tag', 'nextEpisode');
nextEpisode = get(handle, 'string');

set(handle, 'string', ['S' num2str(str2double(nextEpisode(find(nextEpisode == 'S', 1, 'first') + 1:find(nextEpisode == '.') - 1)) + 1) '.E1']);

saveExperiment;