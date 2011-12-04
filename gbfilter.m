function gb=gbfilter(gbHeight, gbWidth, theta, sigma, gamma, lambda)
        
    radWidth=ceil(gbWidth/2);
    radHeight=ceil(gbHeight/2);
    [x,y]=meshgrid(-radWidth:radWidth, -radHeight:radHeight);
    
    xp=x*cosd(theta) + y*sind(theta);
    yp=-x*sind(theta) + y*cosd(theta);
    
    gb=exp(-0.5*(xp.^2 + (gamma*yp).^2)/sigma^2).*cosd(2*pi*xp/lambda);
    gb=gb(1:gbHeight, 1:gbWidth);