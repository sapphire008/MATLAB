function jobs = make_contrasts_jobs(spm_loc, contrasts)

jobs{1}.stats{1}.con.spmmat = {spm_loc};

jobs{1}.stats{1}.con.delete = 1;

for k = 1:length(contrasts)
    jobs{1}.stats{1}.con.consess{k}.tcon.name = contrasts(k).name;
    jobs{1}.stats{1}.con.consess{k}.tcon.sessrep = 'none'
    jobs{1}.stats{1}.con.consess{k}.tcon.convec = contrasts(k).con;
end
