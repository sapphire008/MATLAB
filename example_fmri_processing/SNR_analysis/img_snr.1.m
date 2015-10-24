% snr calculator
% Description: takes an array of files and sets all NaN values to 0. Then
% calculates mean/std for all voxels and writes out an image. window_size
% is essetnial to keeping memory from runing out.
function img_snr(files,b)

window_size=10000; scenario='single';

for i=1:length(files)
	tmp_image=load_nii(files{i});
	img_data(:,:,:,i)=tmp_image.img;
end

img_dim=size(img_data);
lin=prod(img_dim(1:3));

lin_data=reshape(img_data,[lin img_dim(4)]);

switch scenario
	case 'single'
		snr_mean=nanmean(lin_data,2)';
		snr_std=nanstd(single(lin_data)');
	case 'multiple'
		N1=size(lin_data,1);
		for k=1:window_size:(N1-window_size)
			lh=[k:k+window_size-1];
			snr_mean(lh)=nanmean(lin_data(lh,:),2);
			snr_std(lh)=nanstd(single(lin_data(lh,:))');
		end
		N2=length(snr_mean);
		snr_mean(N2+1:N1)=nanmean(lin_data(N2+1:N1,:),2);
		snr_std(N2+1:N1)=nanstd(single(lin_data(N2+1:N1,:))');
end


snr=snr_mean./snr_std;

snr_map=reshape(snr,img_dim(1:3));

[root,~,suffix]=fileparts(files{1});

tmp_image.img=snr_map;
save_nii(tmp_image,[root '/snr_' b suffix])
