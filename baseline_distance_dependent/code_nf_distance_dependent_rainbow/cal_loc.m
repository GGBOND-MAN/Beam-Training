function [loc]=cal_loc(fc,f,theta1,theta2,alpha1,alpha2,M,k)
    loc = zeros(M,2,k);
    for n=1:k
        for m=1:M
            loc(m,1,n)=theta1+theta2*fc/f(m);
            loc(m,2,n)=alpha1+alpha2*fc/f(m);
            if loc(m,1,n)>1
                theta2=theta2-2;
                loc(m,1,n)=theta1+theta2*fc/f(m);
            end
            if loc(m,1,n)<-1
            	theta2=theta2+2;
                loc(m,1,n)=theta1+theta2*fc/f(m);
            end
            if loc(m,1,n)>1
                loc(m,1,n)=1;
            end
            if loc(m,1,n)<-1
                loc(m,1,n)=-1;
            end
        end
    theta1=theta1-2/k;
    end
end