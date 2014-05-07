function [Y, X] = max2( f )
%MAX2   Global maximum of a CHEBFUN2.
%   Y = MAX2(F) returns the global maximum of F over its domain. 
%   
%   [Y, X] = MAX2(F) returns the global maximum in Y and its location X.  
%
%   For certain problems this problem can be slow if the MATLAB Optimization
%   Toolbox is not available.
% 
% See also MIN2, MINANDMAX2.

% Copyright 2014 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

% Call MINANDMAX2:
[Y, X] = minandmax2(f);   

% Extract out maximum:
Y = Y(2); 
X = X(2,:); 

end
