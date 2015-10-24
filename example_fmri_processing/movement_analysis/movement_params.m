%movement parameters
function [RMS,GeoDist,EXT,JAG,MEAN]=movement_params(movement_mat,column_titles)
%number of columns of movement_mat must match the length of column titles
%calcualte RMS
for c=1:length(column_titles)
    RMS.(column_titles{c})=calculate_RMS(movement_mat(:,c));
    EXT.(column_titles{c})=calculate_extreme(movement_mat(:,c));
    JAG.(column_titles{c})=calculate_JAG(movement_mat(:,c));
    MEAN.(column_titles{c})= mean(movement_mat(:,c),1);
end
%calculate Geometric distance
%Geometric distance vectors
GeoDist.translational=calculate_GeoDist(movement_mat(:,1:3));
GeoDist.rotational=calculate_GeoDist(movement_mat(:,4:6));
%RMS of geometric distance
RMS.GeoDist_translational=calculate_RMS(GeoDist.translational.Vect);
RMS.GeoDist_rotational=calculate_RMS(GeoDist.rotational.Vect);
%Extreme values of the geometric distance
EXT.GeoDist_translational=calculate_extreme(GeoDist.translational.Vect);
EXT.GeoDist_rotational=calculate_extreme(GeoDist.rotational.Vect);
%Jaggedness of the geometric distance
JAG.GeoDist_translational=calculate_JAG(GeoDist.translational.Vect);
JAG.GeoDist_rotational=calculate_JAG(GeoDist.rotational.Vect);
end

%% movement parameters to be calculated from the data
%extreme values
function EXT=calculate_extreme(vector_col)
[~,max_ind]=max(abs(vector_col));
EXT.max_num=vector_col(max_ind);
[~,min_ind]=min(abs(vector_col));
EXT.min_num=vector_col(min_ind);
end

%RMS
function RMS=calculate_RMS(vector_col)
RMS=sqrt(mean(vector_col.^2));
end

%Geometric Distance
function GeoDist=calculate_GeoDist(vector_ncols)
%vector_ncols: needs to have more than 1 columns to use this function
if norm(vector_ncols(1,:),2)>1E-7
    vector_ncols=bsxfun(@minus,vector_ncols,vector_ncols(1,:));
end
GeoDist.Vect=sqrt(sum(vector_ncols.^2,2));
GeoDist.Mean=mean(GeoDist.Vect(:));
end

%Jaggedness
function JAG=calculate_JAG(vector_col,varargin)
if isempty(varargin)
    %default t_vect as column vector of counting numbers
    t_vect=[1:1:size(vector_col,1)]';
else
    %if there is input, set the time vector as the input
    t_vect=varargin{1};
end
JAG=mean(abs(diff(vector_col))./diff(t_vect));
end
