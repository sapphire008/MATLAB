function P = location_of_beta_images_from_event_discription(Events,SPM)
% P = location_of_beta_images_from_event_discription(Events,SPM)
% Events = Cell Array of Strings that defines a unique set of beta images
% SPM data structure



discription = {SPM.Vbeta.descrip}; % extract discription

% this block finds sets of index where discriptions match Events
Event_name = '';
for n = 1:length(Events),
    idx{n} = strfind(discription,Events{n});
    idx{n} = find(~cellfun('isempty',idx{n})); %strip out non matching results
    Event_name = [Event_name,'_',Events{n}];
end

% this block find the intersection of all sets of index
ref_idx = idx{1};
for n = 2:length(idx),
    reduced_idx{n-1} = intersect(idx{n},ref_idx);
end
final_idx = [];
for n = 1:length(reduced_idx),
    final_idx = union(reduced_idx{n},final_idx);
end

beta_images = {SPM.Vbeta(final_idx).fname}; % name of beta_images for selected events

% make array of location of beta images
for n = 1:length(beta_images)
    P{n} = fullfile(SPM.swd,beta_images{n});
end
