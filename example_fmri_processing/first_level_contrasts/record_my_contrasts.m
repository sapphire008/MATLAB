% converts the .mat file of contrast parameters back to MATLAB script

FID = fopen('MID_contrast_conditions.txt','w');
%write positive
for n = 1:length(positive_cons)
    fprintf(FID,['positive_cons{',num2str(n),'} = {']);
    for m = 1:length(positive_cons{n})
        fprintf(FID,'''%s''',positive_cons{n}{m});
        if m<length(positive_cons{n})
            fprintf(FID,',');
        end
    end
    
    fprintf(FID,'};\n');
end

fprintf(FID,'\n');

clear n m;
%write negative
for n = 1:length(negative_cons)
    fprintf(FID,['negative_cons{',num2str(n),'} = {']);
    for m = 1:length(negative_cons{n})
        fprintf(FID,'''%s''',negative_cons{n}{m});
        if m<length(negative_cons{n})
            fprintf(FID,',');
        end
    end
    
    fprintf(FID,'};\n');
end



%write names
if exist('name','var')
    fprintf(FID,'\n');
    clear n m;
    for n = 1:length(name)
        fprintf(FID,['name{',num2str(n),'} = {']);
        
        fprintf(FID,'''%s''',name{n});
        if n<length(name)
            fprintf(FID,',');
        end

        fprintf(FID,'};\n');
    end
end


fclose(FID);