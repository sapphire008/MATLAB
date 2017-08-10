% batch script to process images
addmatlabpkg('generic');
addmatlabpkg('2photon');

base_dir = 'D:\Data\2photon\Image 26 Feb 2015\';
cells = {'Neocortex A','Neocortex B', 'Neocortex C', 'Neocortex D', 'Neocortex F'};

for n = 1:length(cells)
    % get current cell directory
    current_cell_dir = fullfile(base_dir, cells{n});
    % get  list of image parts
    [current_image_dir, current_image] = SearchFiles(current_cell_dir, '*');
    current_image_dir = current_image_dir(3:end);
    current_image = current_image(3:end);
    for m = 1:length(current_image_dir)
        savedir = fullfile(current_image_dir{m}, [current_image{m}, '.jpg']);
        I = createZStack2D(current_image_dir{m}, []);
    end
    
end