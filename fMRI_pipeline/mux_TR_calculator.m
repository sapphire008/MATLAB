function [set_numTR,willget_num_nii,actual_numTR] = mux_TR_calculator(n,mux,arc,num_mux_cycle)
% calculate multiplex TR prescription
% 
% [set_numTR,willget_num_nii,actual_numTR] = mux_TR_calculator(n,mux,arc,num_mux_cycle)
%
% Inputs:
%   n: number of TRs/volumes wanted
%   mux: multiplex factor, or how many planes to acquired in parallel
%   arc (optional): inplane acceleration factor.
%   num_mux_cycle (optional): how many cycles of calibration to do (how
%          many k-space to acquire for calibration)
% Outputs:
%   set_numTR: what number should be set in 'phases per location' in the
%              scanner
%   willget_num_nii: the number of nii volumes will get after
%              reconstruction
%   actual_numTR: the actual number of TRs for the duration of the
%           multiplex run
if nargin<3 ||isempty(arc),arc = 2;end
if nargin<4 || isempty(num_mux_cycle),num_mux_cycle = 2;end
set_numTR = n + mux*num_mux_cycle;
willget_num_nii = n + num_mux_cycle;
actual_numTR = n +  mux * arc * num_mux_cycle;
end

% python code
% def mux_TR_calculator(n,mux,arc=2,num_mux_cycle):
%     '''
%           calculate multiplex TR prescription
%   
%           [set_numTR,willget_num_nii,actual_numTR] = mux_TR_calculator(n,mux,arc,num_mux_cycle)
%     
%           Inputs:
%               n: number of TRs/volumes wanted
%               mux: multiplex factor, or how many planes to acquired in parallel
%               arc (optional): inplane acceleration factor.
%               num_mux_cycle (optional): how many cycles of calibration to do (how
%                        many k-space to acquire for calibration)
%           Outputs:
%               set_numTR: what number should be set in 'phases per location' in the
%                      scanner
%               willget_num_nii: the number of nii volumes will get after
%                      reconstruction
%               actual_numTR: the actual number of TRs for the duration of the
%                      multiplex run
%     '''
%     set_numTR = n + mux*num_mux_cycle;
%     willget_num_nii = n + num_mux_cycle;
%     actual_numTR = n +  mux * arc * num_mux_cycle;
%     return (set_numTR, willget_num_nii, actual_numTR)