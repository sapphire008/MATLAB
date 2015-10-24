function failed_jobs = run_spm_jobs(jobs,waitsecs,maxattempt)
% run list of spm jobs with repeated attempts.
%
% Inputs:
%
%   jobs: cellstr of list of job paths, or loaded matlabbatch structure
%   waitsecs: seconds to wait before next attempt (default 60 seconds)
%   maxattempt: maximum number of attempt allowed (default 100)
%
% Output:
%   failed_jobs: list of jobs that failed the maximum number of attempts.
%
% This function can be  useful when trying to run smoothing and model 
% estimation at the same time on different server nodes. The function is
% going to attempt to run model estimation. Upon failure, it is going to
% wait for 'waitsecs', then attempts again. The maximum number of attempts
% can be set with 'maxattempt' (Default 100)

if nargin<2 || isempty(waitsecs)
    waitsecs = 60;
end
if nargin<3 || isempty(maxattempt)
    maxattempt = 100;
end

terminate = false;
n = 1;% index jobs
m = 1; % count attempts for current job
failed_jobs = [];% collect failed jobs
while ~terminate
    state = true;
    try
        %disp(n);
        spm_jobman('run',jobs{n});
    catch
        state = false;
        pause(waitsecs);
    end
    % if succesfully run, move on to the next job
    if state
        n = n+1;
        m = 1;% reset attempt count
    else
        m = m+1;
    end
    
    % terminate if all the jobs are succesfully run
    if n>numel(jobs)
        break;
    end
    
    % terminate if exceeding the maximum number of attempts allowed
    if m > maxattempt
        warning(['Maximum number of attempts (%d) exceeded for job\n\n',...
            '%s.\n\nTerminated prematurely!\n\n'],maxattempt,jobs{n});
        n = n +1; % moving on
        failed_jobs = [failed_jobs,jobs(n)];
        continue;
    end
    % pause for a bit so that we are not breaking the computer with while
    % loop.
    pause(0.1);
end

end