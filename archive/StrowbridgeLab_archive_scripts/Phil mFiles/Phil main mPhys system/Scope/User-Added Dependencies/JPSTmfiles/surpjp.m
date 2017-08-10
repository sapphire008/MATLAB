function IERR = surpjp;
%
global xHist;
global yHist;
global matrix;
global alignList;
%
% ----------------------------------------------------------
%C
%        real function surpjp(n,nx,ny,nxy,IERR)
%C
% NOTE that original i,j loop was outside the function. Here it is inside.
% matrix contains raw JPST, not normalized by trial number
% n = IND3 = number of aligns
% nx = a PSTX bin
% ny = a PSTY bin
% nxy = the corresponding matrix bin
% IERR is a returned error value:
% ------------------------------------------------------

eExcite = zeros(size(matrix));
eInhib =  zeros(size(matrix));
IERR = zeros(size(matrix));
NumTrials = length(alignList);
%
%major i,j loop through matrices
for i = 1:length(xHist)
   for j = 1:length(yHist)

% ----------------------------------------------------
%C
%C             ERROR FLAG TO INDICATE POSSIBLE ERRORS:
%C             IERR=0 : NO ERROR
%C                  1 : NX AND/OR NY .GE. N ; ACTION TAKEN: N=MAX(NX,NY)
%C                  2 : NXY .GE. MIN(NX,NY) ; ACTION TAKEN: NXY=MIN(NX,NY)
%C                  3 : BOTH ERRORS; BOTH ACTIONS TAKEN IN SEQUENCE 1,2
%C       
%C    FIRST TEST POSSIBLE ERROR CONDITIONS
%C
%        IERR=0
%        NN=N
%        IF (MAX0(xHist,yHist).GT.NN) THEN
%            IERR=IERR+1
%            NN=MAX0(NX,NY)
%        END IF
        
% if the  
%        NNXY=NXY
%        IF (NNXY.GT.MIN0(NX,NY)) THEN
%            IERR=IERR+2
%            NNXY=MIN0(NX,NY)
%        END IF
% --------------------------------------------
        ERR1 = 0; ERR2 = 0;
        NX = xHist(i);
        NY = yHist(j);
        NNXY = matrix(i,j);
        NN = NumTrials;
        if (max([NX NY]) > NN)
            IERR(i,j) = IERR(i,j) +1;
            ERR1 = ERR1 + IERR(i,j);    %summing up the type 1 errors
            NN = max([NX NY]);
        end
        if (NNXY > min([NX NY]))
            IERR(i,j) = IERR(i,j) + 2;
            ERR2 = ERR2 + IERR(i,j);    % summing up the type 2 errors
            NNXY = min([NX NY]);
        end
% ----------------------------------------

%C
%C CALCULATE 'SURPRISE'
%C
%        NP=NX
%        NQ=NY
%        X=DBLE(0.)
%        IF (NP.LE.NQ) GOTO 1
%        M=NP
%        NP=NQ
%        NQ=M
%1       NK=NN-NQ
%        MINKP=MIN0(NK,NP)
%        MAXKP=MAX0(NK,NP)
%        LMIN=MAX0(0,NP+NQ-NN)
%        B=DBLE(1.)
%        DO 7 L=0,MINKP-1
%         TA = DFLOAT(MAXKP-L)
%         TB = DFLOAT(NN-L)
%         B = B*TA/TB
%C       B=B*FLOAT(MAXKP-L)/FLOAT(NN-L)
%7       CONTINUE
%        Y=B
%        IF (NNXY.EQ.0) GOTO 8
%        X=B
%        IF (LMIN.GT.NNXY-2) GOTO 3
%        DO 6 L=LMIN,NNXY-2
%         TC = DFLOAT(NQ-L)
%         TD = DFLOAT(NP-L)
%         TE = DFLOAT(L+1)
%         TF = DFLOAT(NK+L+1-NP)
%         B = B*TC*TD/(TE*TF)
%C       B=B*(NQ-L)*FLOAT(NP-L)/(FLOAT(L+1)*FLOAT(NK+L+1-NP))
%        X=X+B
%6       CONTINUE
%3       IF (LMIN.LE.NNXY-1) THEN
%         TG = DFLOAT((NQ-NNXY)+1)
%         TH = DFLOAT((NP-NNXY)+1)
%         TI = DFLOAT(NNXY)
%         TK = DFLOAT(NK+NNXY-NP)
%         B = B*TG*TH/(TI*TK)
%C    1  B=B*((NQ-NNXY)+1)*FLOAT((NP-NNXY)+1)/
%C    2   (FLOAT(NNXY)*FLOAT(NK+NNXY-NP))
%        END IF
%        Y=X+B
%8       IF (X.GT.DBLE(0.99999999999999)) X=DBLE(0.99999999999999)
%        SEXCIT=-DLOG(DBLE(1.)-X)
%        IF (Y.LT.DBLE(0.00000000000001)) Y=DBLE(0.00000000000001)
%        SINHIB=-DLOG(Y)
%        SURPJP=SEXCIT-SINHIB
%        RETURN
%        END
%C

% ----------------------------------------------------------

        NP = NX;
        NQ = NY;
        X = double(0);
        if (NP > NQ)
            NP = NY;
            NQ = NX;
        end
        %
        NK = NN - NQ;
        MINKP = min([NK NP]);
        MAXKP = max([NK NP]);
        LMIN = max([0 NP+NQ-NN]);
        B = double(1);
        for L=0:MINKP-1
            TA = double(MAXKP - L);
            TB = double(NN - L);
            B = double(B*TA/TB);
        end
        Y = B;
        if (NNXY ~= 0)
            X = B;
            if (LMIN <= NNXY-2)
                for L = LMIN:NNXY-2
                    TC = double(NQ-L);
                    TD = double(NP-L);
                    TE = double(L+1);
                    TF = double(NK+L+1-NP);
                    B = double(B*TC*TD/(TE*TF));
                    X = X + B;
                end
            end
            if (LMIN < NNXY-1)
               TG = double((NQ-NNXY)+1);
               TH = double((NP-NNXY)+1);
               TI = double(NNXY);
               TK = double(NK+NNXY-NP);
               B = B*TG*TH/(TI*TK);
            end
            Y = X + B;
        end
        if (X > double(0.99999999999999)) 
            X = double(0.99999999999999);
        end
        eExcite=-log(double(1.)-X);
        if (Y < double(0.00000000000001)) 
            Y = double(0.00000000000001);
        end
        eInhib=-log(Y);
        matrix(i,j) = eExcite - eInhib;
%        matrix is the output surpjp plane of Palm's original routine
   end      %closing the i,j major loop
end
% Note that IERR matrix is available to examine error distributions
[m,n] = find(IERR > 0);
NUMERR = max(size([m,n]));
fprintf('number of errors is %d\n',NUMERR);






