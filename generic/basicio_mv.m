function basicio_mv(source_dir, target_dir)
if isunix || ismac
    eval(['!mv ', source_dir, ' ', target_dir]);
else %pc
    [~, ~] = dos(['move "', source_dir, '" "', target_dir,'"']);
end
end