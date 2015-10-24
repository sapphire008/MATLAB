function runs = postproc_correct_reference_disp(runs)
% For each group (labeled by ref_voxel), use the first frame of the
% reference scan as the frame of reference (0,0), calculate displacement
% from the origin to susbsequent scans' first frame, and add this
% difference back to subsequent scans so that now, subsequent scans'
% displacement are relative to the origin of the first frame of the
% reference scan. Now, to account for movement during reference scan,
% subtract the mean of the displacement from subsequent scans. This
% essentially is equivalent to displacement relative to the mean position
% of the reference scan.


% extract some more parameters and store in an array
group_vect = arrayfun(@(x) x.params.ref_voxel,runs,'un',0);
[groups,~,IC] = unique(group_vect);
runs = num2cell(runs); % convert to cell for indexing
% loop through each group
for n = 1:length(groups)
    current_runs = runs(IC == n);
    % sanity check, making sure all runs have the same dimension
    dim_vect = cell2mat(cellfun(@(x) x.params.img_dim,current_runs,'un',0)');
    dim_dist = bsxfun(@plus,dot(dim_vect,dim_vect,2),dot(dim_vect,dim_vect,2)')-2*(dim_vect*dim_vect');
    if any(dim_dist(:)),error('%s: Not all runs'' images have the same size\n',groups{n});end
    % sanity check, making sure all windows are smaller than the dimension of
    % original image size
    dim_vect = cellfun(@(x) x.params.img_dim,current_runs,'un',0);
    window_vect = cellfun(@(x) x.params.Window,current_runs,'un',0);
    window_check = cellfun(@(x,y) x(1)>=1 & x(2)<=y(1) & x(3)>=1 & x(4)<=y(2),window_vect,dim_vect);
    if ~all(window_check(:))
        error('%s %d ''s window size is beyond the original dimension\n',groups{n},find(~window_check));
    end
    clear dim_dist dim_vect window_check;
    % find out which run is reference run
    isref_vect = cellfun(@(x) logical(x.params.isref),current_runs);
    if sum(isref_vect(:))>1
        warning('There are more than 1 runs that are specified as reference in the current group');
        cellfun(@(x,y) fprintf('%d: %s\n',x,y),...
            num2cell(1:sum(isref_vect(:))),{current_runs(logical(isref_vect)).dir});
        IND = input('Which run should be used? Enter a number: ');
        % fix the current runs
        current_run_IND = find(isref_vect);
        current_run_IND = current_run_IND(setdiff(1:sum(isref_vect(:)),IND));
        for kk = 1:length(current_run_IND)
            current_runs(current_run_IND(kk)).params.isref = 0;
        end
        runs(IC==n) = current_runs;
        isref_vect = cellfun(@(x) logical(x.params.isref), current_runs);
        clear IND current_run_IND;
    end
    
    % separate type of runs
    ref_runs = current_runs{isref_vect};
    norm_runs = current_runs(~isref_vect);
    
    % calculate the adjusted displacement
    for m = 1:length(norm_runs)
        norm_runs{m}.current_ref = ref_runs.dir;
        % calculate the adjusted distance
        norm_runs{m}.this_to_ref = ...
            ((norm_runs{m}.params.Window([1,3])+norm_runs{m}.base_image_center)-...
            (ref_runs.params.Window([1,3])+ref_runs.base_image_center))/...
            norm_runs{m}.params.pixels_to_mm; %[row,col]
        % why not divide each individual's px2mm conversion factor, but
        % only use the one from current norm_run?: then the frame of
        % reference would change.
        norm_runs{m}.this_to_ref = [norm_runs{m}.this_to_ref(2),-norm_runs{m}.this_to_ref(1)]; % [x,y]
        norm_runs{m}.displacement.x = norm_runs{m}.displacement.x + norm_runs{m}.this_to_ref(1) - mean(ref_runs.displacement.x(:));
        norm_runs{m}.displacement.y = norm_runs{m}.displacement.y + norm_runs{m}.this_to_ref(2) - mean(ref_runs.displacement.y(:));
    end
    
    % homogenize ref runs
    ref_runs.current_ref = 'self';
    ref_runs.this_to_ref = [0;0];
    
    % reconstruct runs
    current_runs{isref_vect} = ref_runs;
    current_runs(~isref_vect)= norm_runs;
    runs(IC == n) = current_runs;
    
    clear current_runs ref_runs norm_runs;
end
runs = cell2mat(runs);
end