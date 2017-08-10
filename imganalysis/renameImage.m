function renameImage(current_dir, name, movesingle)
current_dir = 'D:\Data\2photon\2016\05.May\Image 3 May 2016\Slice B';
name = 'Slice B';
movesingle = true;
if movesingle
    [~, N] = SearchFiles(pwd, '*1F*.img', 'D');
    mkdir(fullfile(current_dir, 'Single'));
    % move all the single images into a folder first
    for n = 1:length(N)
        source = fullfile(current_dir, N{n});
        target = fullfile(current_dir, 'Single', N{n});
        movefile(source, target);
    end
end
% parse other movies
[~, N] = SearchFiles(current_dir, '*.img', 'D');
for n = 1:length(N)
    source = fullfile(current_dir, N{n});
    target = fullfile(current_dir, strrep(N{n}, name, [name,' ', sprintf('%03.0f',n)]));
    movefile(source, target);
end
end