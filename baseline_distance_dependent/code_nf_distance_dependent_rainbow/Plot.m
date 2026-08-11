function p =  Plot(x,y, num, linestyle, varargin)
% Included operators: Color, Linewidth, Markersize, MarkerFaceColor
    
    N = numel(varargin);
    if mod(N,2) == 1
        error('Parameter number must be even! ');
    end
    
    index = 1:ceil(length(x)/num):length(x);
    linetype = linestyle(1:end-1);
    markertype = linestyle(end);
    
    p0 = plot(x,y, linetype);
    p1 = plot(x(index), y(index), markertype);
    p2 = plot(x(1), y(1), linestyle);
    p3 = plot(x(end), y(end), linestyle);
    
    for idx = 1:N/2
        set(p0, varargin{2*idx-1}, varargin{2*idx});
        set(p1, varargin{2*idx-1}, varargin{2*idx});
        set(p2, varargin{2*idx-1}, varargin{2*idx});
        set(p3, varargin{2*idx-1}, varargin{2*idx});
    end
    p = p2;
end

