function d=localdct(A, D)
    
    k=size(D, 1);
    n=size(A, 1);
    m=size(A, 2);
    d=[];
    
    for i=1:k:n
        r=min([i+k-1 n]);
        for j=1:k:m
            c=min([j+k-1 m]);
            a=zeros(k);
            a(1:1+r-i, 1:1+c-j)=A(i:r, j:c);
            s=max(a(:));
            if s ~= 0
                a=D*a*D';
            end
            d(1+floor(i/k), 1+floor(j/k))=max(a(:));
        end
    end
