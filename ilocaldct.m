function d=ilocaldct(A, D, n, m)

    k=size(D, 1);
    d=zeros(n, m);
    
    for i=1:k:n
        r=min([i+k-1 n]);
        for j=1:k:m
            c=min([j+k-1 m]);
            a=A(1+floor(i/k), 1+floor(j/k));
            d(i:r, j:c)=a;
        end
    end