function [ m ] = sparseAmbigline( L, H, r , N )
% sparse version of Ambigline function

    Ntemp = 2^ceil(log2(N)+1);
    %majority vote to figure out the dom freqs:
    rtemp = max(r,8);
    %mtemp = zeros(rtemp,log2(Ntemp)); %counter
    temp = [];
    t= linspace(0,N-1,N);
    for i=1:log2(log2(Ntemp))
%         c = randi(N-1);
         cinv = 1;%modminv(c,N);
%         p = mod(c*t,N)+1;
        permL = L(t+1);
        permH = H(t+1);
        temp=[temp;sparseAmbigfft(permL,permH,rtemp,Ntemp,N,cinv)];
    end
    temp(:,2) = round(temp(:,2)*N/Ntemp);
    mtemp = counter(temp,rtemp,5);
    m = mtemp(:,3);
    sz = size(mtemp);
    if r>sz(1)
        fprintf('r is toooo big!');
    else
%       round(counter(mtemp,rtemp,30)*N/Ntemp);
        m = m(1:r);
    end
end

function [dftk] = sparseAmbigfft(L,H,k,N,init,cinv)
ktemp = ceil(k/2.0);
if k==1
    dftk = zeros(k,2);
    %only retain the entries of a that we need
    ak = zeros(log2(N),ceil(log2(log2(N))),3);
    
    for j=1:log2(N)
        for l =1:ceil(log2(log2(N)))
        int1 = mod(randi(N-1),init)+1;
        int2 = mod(int1-1+(N/2^j),init)+1;
        ak(j,l,:) = [helper(L,H,int1),helper(L,H,int2),int1];
        end
    end

%     if abs(ak(1,1)-ak(1,2))<= abs(ak(1,1)+ak(1,2))
%          %'even'
%          if N==2 
%              dftktemp=2;
%          else dftktemp= 2*sparsefftinternal(ak(2:log2(N),:),0,N/2);
%          end  
%     else 
%          %'odd'
%          if N==2
%              dftktemp=1;
%          else dftktemp= 2*sparsefftinternal(ak(2:log2(N),:),1,N/2)-1;
%          end
%     end

    dftktemp = sparsefftinternal(ak,0,N);
    
    dftk(1,:)= [helper(L,H,1),mod(dftktemp,N)]; %sparsefftinternal(ak,0,N);
    
else
% %pseudo random permutation:
% b = randi(N)-1;
%     c = 1;
%     for i=1:log2(N) %make a random c that is invertible mod N which is a power of 2.
%         c = c*(2*randi(5)-1);
%     end
%     c = mod(c,N); 
%    cinv = modminv(c,N);

    %only retain the entries of a that we need
    filter=zeros(2*ktemp,1);

    for i=1:ktemp %generate the significant coeffs of filter roughly |supp|=k
        filter(i) = exp(-(N/(ktemp^2))*(pi*(i-1)^2)/N);
    end
    j= ktemp+1; 
    for i=N-ktemp+1:N
        filter(j) = exp(-(N/(ktemp^2))*(pi*(N-i)^2)/N);
        j=j+1;
    end

    ak1 = zeros(log2(N),ceil(log2(log2(N))),2*ktemp);
    ak2 = zeros(log2(N),ceil(log2(log2(N))),2*ktemp);
    int = zeros(log2(N),ceil(log2(log2(N))),1);

    for j=1:log2(N) %generate samples of filtered versions of a each with one alive frequency for bit by bit
        for l = 1:ceil(log2(log2(N)))
            int1 = randi(N)-1; 
            int2 = mod(int1+(N/2^j),N);
            h1=zeros(2*ktemp,1);
            h2 = zeros(2*ktemp,1);
            for i=0:2*ktemp-1 
                  if i+1 <= ktemp
                    shiftint1 = mod((i+int1),init);
                    shiftint2 = mod((i+int2),init);
                    h1(i+1) = L(shiftint1+1)*conj(H(shiftint1+1))*filter(i+1);%helper(L,H,shiftint1+1)*filter(i+1);
                    h2(i+1) = L(shiftint2+1)*conj(H(shiftint2+1))*filter(i+1);%helper(L,H,shiftint2+1)*filter(i+1);
                  else
                    shiftint1 = mod((N-(2*ktemp-i)+int1),init);
                    shiftint2 = mod((N-(2*ktemp-i)+int2),init);
                    h1(i+1) = L(shiftint1+1)*conj(H(shiftint1+1))*filter(i+1); %helper(L,H,shiftint1+1)*filter(i+1); 
                    h2(i+1) = L(shiftint2+1)*conj(H(shiftint2+1))*filter(i+1); %helper(L,H,shiftint2+1)*filter(i+1); 
                  end
            end
            int(j,l)=int1+1;
            ak1(j,l,:)= fft(h1,2*ktemp); %creates samples for the n-th bit for each of the k filtered versions
            ak2(j,l,:) = fft(h2,2*ktemp);  
        end
    end

    % Non-recursive: (comment out if unnecessary)
%     dftk = NonRecursiveSfft(N,ktemp,ak1,ak2,int);
 
    %Recursive: 
%     tic
      dftk = RecursiveSfft(N,ktemp,ak1,ak2,int);  
%     toc
    
end
end

function[LH] = helper(L,H,int)
    LH = L(int)*conj(H(int));
end
