clear all;  clc;
Nt=128;
channel_theta = linspace(-1,1,5*Nt);
channel_alpha = linspace(1/400,1/10,100);
fc=10*10^9;
B=2*10^9;
M=512;
k0 = 2;
c = 3e8;
lambda_c = c/fc;
d = lambda_c / 2;
theta1 = -31; theta2 = 15;
alpha1 = -0.454; alpha2 = 0.5;
w_2D_near = delay_polar_2d(Nt, B, fc, M, d,theta1,theta2,alpha1,alpha2,k0);
f = zeros(1, M);
for m= 1:M
    f(m)=fc+B/(M)*(m-1-(M-1)/2);
end
k = 2 * pi * f / c;
g = zeros(100,5*Nt);
nn = (-(Nt - 1)/2:1:(Nt-1)/2)';
for l =1:k0
    for m=1:M
        for p=1:5*Nt
            for q=1:100
                w = 1/sqrt(Nt) * exp( - 1j * k(m) * (  nn * d * channel_theta(p) - nn.^2 * d.^2 * channel_alpha(q)));
                g(q,p)=abs(w'*w_2D_near(:,l,m));
            end
        end
        mesh(channel_theta,channel_alpha,g);
        view(0, 90);
        hold on;
        
    end
    
    theta1=theta1+2/k0;
    box on;
    xlabel('\theta');
    ylabel('\alpha');
    colorbar
    caxis([0.4 1]);

end
