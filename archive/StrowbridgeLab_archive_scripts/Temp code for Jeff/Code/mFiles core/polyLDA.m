function [accuracy distFromPlane constantTerm coefTerms] = polyLDA(array1in, array2in)
    % revised 5 Jan 2015 BWS for Poly3
    % takes rows as trials like other routines
    
    array1 = array1in';
    array2 = array2in';
    
    Data  = cat(2, array1, array2); % now columns are trials
    Vecs = transpose(Data);
    Grouping = cat(2, 1*ones(1,size(array1,2)), 2*ones(1,size(array2,2)));
    
    if size(array1,1) == 3  %3-d only to flag less than 3 cells
        %case size(x,1) is numCells, size(x,2) is numTrials

        %create the sample class for classify (
        [X,Y,Z] = meshgrid(linspace(min(Vecs(:,1)),1.2*max(Vecs(:,1))),...  
                           linspace(min(Vecs(:,2)),1.2*max(Vecs(:,2))),...
                           linspace(min(Vecs(:,3)),1.2*max(Vecs(:,3))));               
        X=X(:); Y=Y(:); Z=Z(:);

        %classify by LDA
        [~,err,~,~,coeff] = classify([X Y Z],[Vecs(:,1) Vecs(:,2) Vecs(:,3)],...    
                                         Grouping,'linear');


    elseif size(array1,1) == 2 %2-d case
        % disp('LDA fixed dropped to 2d');
        %create the sample class for classify 
        [X,Y] = meshgrid(linspace(min(Vecs(:,1)),1.2*max(Vecs(:,1))),...  
                           linspace(min(Vecs(:,2)),1.2*max(Vecs(:,2))));             
        X=X(:); Y=Y(:);

        %classify by LDA
        [~,err,~,~,coeff] = classify([X Y],[Vecs(:,1) Vecs(:,2)],...    
                                         Grouping,'linear');

    elseif size(array1,1) == 1 %1-d case
        % disp('LDA fixed dropped to 1d');
        %create the sample class for classify 
        X = transpose(linspace(min(Vecs(:,1)),1.2*max(Vecs(:,1))));         

        %classify by LDA
        [~,err,~,~,coeff] = classify(X,Vecs(:,1),Grouping,'linear');

    end
    
    
    %X = transpose(linspace(min(Vecs(:,1)), 1.2*max(Vecs(:,1))));
    %[~, err, ~, ~, coeff] = classify(X, Vecs(:,1), Grouping, 'linear');
    K = coeff(1,2).const;
    L = transpose(coeff(1,2).linear);
    accuracy = 100 * (1-err);
    distFromPlane = zeros(1, size(Vecs,1));
    for n = 1:size(Vecs,1)
       distFromPlane(n) = (K + Vecs(n,:) * L') / norm(L);
       %distFromPlane(n) = 0;
    end
    constantTerm = K;
    coefTerms = L;
end