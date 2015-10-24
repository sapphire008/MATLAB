function images = imreg_edges(images, params)
% The imreg_edges function finds feature edges using the specified
% algorithm and saves the edged images in images.edged
disp(['Finding edges using the ' params.edge_alg ' algorithm...']); tic;
images(params.image_num).edged = [];
for i = 1:params.image_num
    % find the edges of each image using the specified alg.
    images(i).edged = edge(images(i).cleaner, params.edge_alg);
end
toc; disp(' ');
%EDC: not going to clear the workspace, since we rely on .cleaner to find
%the center<--more reliable
% % If user is not saving workspace, let's clear some RAM:
% if ~params.save_workspace
%     images = rmfield(images, 'cleaner');
% end
%Give option to view edged images if interactive
if params.interactive
    choice = questdlg('View edged images?',...
        'Edged Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            images = imreg_display(images, 'edged');
        case 'Cancel'
            images = -1; return;
    end
end
end